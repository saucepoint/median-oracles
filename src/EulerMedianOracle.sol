// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolIdLibrary, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {RingBufferLibrary} from "./lib/RingBufferLibrary.sol";
import {TickQuantisationLibrary} from "./lib/TickQuantisationLibrary.sol";

struct BufferData {
    int16 currentTick;
    uint256 bufferIndex;
    uint256 count;
    uint256 lastUpdate;
}

/// @title Euler Median Oracle. Euler's implementation adapted for Uniswap v4 Hooks
/// @notice this contract is a modification of https://github.com/euler-xyz/median-oracle/blob/master/contracts/MedianOracle.sol
contract EulerMedianOracle is BaseHook {
    using PoolIdLibrary for PoolKey;
    using TickQuantisationLibrary for int256;
    using TickQuantisationLibrary for uint256;
    using RingBufferLibrary for uint256[8192];

    uint256[8192] ringBuffer;

    int16 public currTick;
    uint16 public ringCurr;
    uint16 public ringSize;
    uint64 public lastUpdate;

    constructor(IPoolManager _poolManager, uint16 _ringSize) BaseHook(_poolManager) {
        ringCurr = 0;
        ringSize = _ringSize;
        lastUpdate = uint64(block.timestamp);
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4)
    {
        (, int24 tick,,,,) = poolManager.getSlot0(key.toId());
        int256 newTick = int256(tick);

        unchecked {
            int256 _currTick = currTick;
            uint256 _ringCurr = ringCurr;
            uint256 _ringSize = ringSize;
            uint256 _lastUpdate = lastUpdate;

            newTick = newTick.quantiseTick();

            if (newTick == _currTick) return BaseHook.beforeSwap.selector;

            uint256 elapsed = block.timestamp - _lastUpdate;

            if (elapsed != 0) {
                _ringCurr = (_ringCurr + 1) % _ringSize;
                ringBuffer.write(_ringCurr, int16(_currTick), uint16(clampTime(elapsed)));
            }

            currTick = int16(newTick);
            ringCurr = uint16(_ringCurr);
            ringSize = uint16(_ringSize);
            lastUpdate = uint64(block.timestamp);
        }
        return BaseHook.beforeSwap.selector;
    }

    function readOracle(uint256 desiredAge) external view returns (uint16, int24, int24) {
        // returns (actualAge, median, average)
        require(desiredAge <= type(uint16).max, "desiredAge out of range");

        unchecked {
            int256 _currTick = currTick;
            uint256 _ringCurr = ringCurr;
            uint256 _ringSize = ringSize;
            uint256 cache = lastUpdate; // stores lastUpdate for first part of function, but then overwritten and used for something else

            uint256[] memory arr;
            uint256 actualAge = 0;

            // Load ring buffer entries into memory

            {
                uint256 arrSize = 0;
                uint256 freeMemoryPointer;
                assembly {
                    arr := mload(0x40)
                    freeMemoryPointer := add(arr, 0x20)
                }

                // Populate first element in arr with current tick, if any time has elapsed since current tick was set

                {
                    uint256 duration = clampTime(block.timestamp - cache);

                    if (duration != 0) {
                        if (duration > desiredAge) duration = desiredAge;
                        actualAge += duration;

                        uint256 packed = _currTick.memoryPackTick(duration);

                        assembly {
                            mstore(freeMemoryPointer, packed)
                            freeMemoryPointer := add(freeMemoryPointer, 0x20)
                        }
                        arrSize++;
                    }

                    _currTick = _currTick.unQuantiseTick() * int256(duration); // _currTick now becomes the average accumulator
                }

                // Continue populating elements until we have satisfied desiredAge

                {
                    uint256 i = _ringCurr;
                    cache = type(uint256).max; // overwrite lastUpdate, use to cache storage reads

                    while (actualAge != desiredAge) {
                        int256 tick;
                        uint256 duration;

                        if (cache == type(uint256).max) {
                            // TODO: beware of type expansion here
                            (tick, duration) = ringBuffer.read(i);
                        }

                        if (duration == 0) break; // uninitialised

                        if (actualAge + duration > desiredAge) duration = desiredAge - actualAge;
                        actualAge += duration;

                        uint256 packed = tick.memoryPackTick(duration);

                        assembly {
                            mstore(freeMemoryPointer, packed)
                            freeMemoryPointer := add(freeMemoryPointer, 0x20)
                        }
                        arrSize++;

                        _currTick += tick.unQuantiseTick() * int256(duration);

                        if (i & 7 == 0) cache = type(uint256).max;

                        i = (i + _ringSize - 1) % _ringSize;
                        if (i == _ringCurr) break; // wrapped back around
                    }

                    assembly {
                        mstore(arr, arrSize)
                        mstore(0x40, freeMemoryPointer)
                    }
                }
            }

            return (
                uint16(actualAge),
                int24(weightedMedian(arr, actualAge / 2).unMemoryPackTick().unQuantiseTick()),
                int24(_currTick / int256(actualAge))
            );
        }
    }

    // QuickSelect, modified to account for item weights

    function weightedMedian(uint256[] memory arr, uint256 targetWeight) private pure returns (uint256) {
        unchecked {
            uint256 weightAccum = 0;
            uint256 left = 0;
            uint256 right = (arr.length - 1) * 32;
            uint256 arrp;

            assembly {
                arrp := add(arr, 32)
            }

            while (true) {
                if (left == right) return memload(arrp, left);

                uint256 pivot = memload(arrp, (left + right) >> 6 << 5);
                uint256 i = left - 32;
                uint256 j = right + 32;
                uint256 leftWeight = 0;

                while (true) {
                    i += 32;
                    while (true) {
                        uint256 w = memload(arrp, i);
                        if (w >= pivot) break;
                        leftWeight += w & 0xFFFF;
                        i += 32;
                    }

                    do {
                        j -= 32;
                    } while (memload(arrp, j) > pivot);

                    if (i >= j) {
                        if (i == j) leftWeight += memload(arrp, j) & 0xFFFF;
                        break;
                    }

                    leftWeight += memswap(arrp, i, j) & 0xFFFF;
                }

                if (weightAccum + leftWeight >= targetWeight) {
                    right = j;
                } else {
                    weightAccum += leftWeight;
                    left = j + 32;
                }
            }
        }

        assert(false);
        return 0;
    }

    // Array access without bounds checking

    function memload(uint256 arrp, uint256 i) private pure returns (uint256 ret) {
        assembly {
            ret := mload(add(arrp, i))
        }
    }

    // Swap two items in array without bounds checking, returns new element in i

    function memswap(uint256 arrp, uint256 i, uint256 j) private pure returns (uint256 output) {
        assembly {
            let iOffset := add(arrp, i)
            let jOffset := add(arrp, j)
            output := mload(jOffset)
            mstore(jOffset, mload(iOffset))
            mstore(iOffset, output)
        }
    }

    function clampTime(uint256 t) private pure returns (uint256) {
        unchecked {
            return t > type(uint16).max ? uint256(type(uint16).max) : t;
        }
    }
}
