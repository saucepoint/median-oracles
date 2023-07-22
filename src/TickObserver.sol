// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {RingBufferLibrary} from "./lib/RingBufferLibrary.sol";

struct BufferData {
    int16 currentTick;
    uint256 bufferIndex;
    uint256 lastUpdate;
}

contract TickObserver is BaseHook, Test {
    using PoolId for IPoolManager.PoolKey;
    using RingBufferLibrary for uint256[8192];

    uint256 public beforeSwapCount;
    uint256 public afterSwapCount;

    mapping(bytes32 poolId => uint256[8192] buffer) public buffers;
    mapping(bytes32 poolId => BufferData) public bufferData;

    int256 constant TICK_TRUNCATION = 30;
    uint256 internal constant bufferMax = 65536;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    // TODO: allow for arbitrary time ranges
    function get10MinObservations(IPoolManager.PoolKey calldata key) external view returns (int256[] memory sequence) {
        bytes32 id = key.toId();
        uint256[8192] memory buffer = buffers[id];
        BufferData memory data = bufferData[id];

        // worse case scenario
        // each index in the sequence corresponds to 12 seconds, so 50 = 10 minutes (600s)
        sequence = new int256[](50);

        uint256 bufferIndex = data.bufferIndex;
        uint256 sequenceIndex = 49; // most recent

        int16 tick;
        uint16 duration;
        uint256 i;
        uint256 j;
        for (i; i < 50;) {
            (tick, duration) = buffer.read(bufferIndex);
            if (duration == 0) break;
            for (j = 0; j < duration;) {
                sequence[sequenceIndex] = int256(tick);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
                bufferIndex -= duration;
                sequenceIndex -= i;
            }
        }
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeSwap(address, IPoolManager.PoolKey calldata key, IPoolManager.SwapParams calldata)
        external
        override
        returns (bytes4)
    {
        bytes32 id = key.toId();
        (, int24 tick,) = poolManager.getSlot0(id);
        BufferData storage data = bufferData[id];

        int16 newTick = int16(quantiseTick(tick));
        if (newTick == data.currentTick) return BaseHook.beforeSwap.selector;

        uint256 timeChange = block.timestamp - data.lastUpdate;
        if (timeChange != 0) {
            data.bufferIndex = (data.bufferIndex + timeChange) % bufferMax;
            uint256[8192] storage buffer = buffers[id];
            buffer.write(data.bufferIndex, newTick, uint16(timeChange));
        }

        data.currentTick = newTick;
        data.lastUpdate = block.timestamp;

        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(address, IPoolManager.PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta)
        external
        override
        returns (bytes4)
    {
        afterSwapCount++;
        return BaseHook.afterSwap.selector;
    }

    function clampTime(uint256 t) private pure returns (uint256) {
        unchecked {
            return t > type(uint16).max ? uint256(type(uint16).max) : t;
        }
    }

    function quantiseTick(int256 tick) private pure returns (int256) {
        unchecked {
            return (tick + (tick < 0 ? -(TICK_TRUNCATION - 1) : int256(0))) / TICK_TRUNCATION;
        }
    }

    function unQuantiseTick(int256 tick) private pure returns (int256) {
        unchecked {
            return tick * TICK_TRUNCATION + (TICK_TRUNCATION / 2);
        }
    }
}
