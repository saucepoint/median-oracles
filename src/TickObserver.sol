// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
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

contract TickObserver is BaseHook, Test {
    using TickQuantisationLibrary for int256;
    using PoolIdLibrary for PoolKey;
    using RingBufferLibrary for uint256[8192];

    mapping(PoolId poolId => uint256[8192] buffer) public buffers;
    mapping(PoolId poolId => BufferData) public bufferData;

    uint256 internal constant bufferMax = 65536;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    // TODO: replace with time-based selection
    function get50Observations(PoolKey calldata key) external view returns (int256[] memory sequence) {
        PoolId id = key.toId();
        uint256[8192] memory buffer = buffers[id];
        BufferData memory data = bufferData[id];
        uint256 bufferIndex = data.bufferIndex;

        sequence = new int256[](50);

        int16 tick;
        uint16 duration;
        uint256 i;
        for (i; i < 50;) {
            (tick, duration) = buffer.read(bufferIndex);
            sequence[49 - i] = int256(tick).unQuantiseTick();
            unchecked {
                ++i;
                bufferIndex -= duration;
            }
        }
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: true,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function afterInitialize(address, PoolKey calldata key, uint160, int24, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4)
    {
        bufferData[key.toId()].lastUpdate = block.timestamp;
        return BaseHook.afterInitialize.selector;
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4)
    {
        PoolId id = key.toId();
        (, int24 tick,,,,) = poolManager.getSlot0(id);
        BufferData storage data = bufferData[id];

        int16 newTick = int16(int256(tick).quantiseTick());
        if (newTick == data.currentTick) return BaseHook.beforeSwap.selector;

        uint256 timeChange = block.timestamp - data.lastUpdate;
        if (timeChange != 0) {
            data.bufferIndex = (data.bufferIndex + timeChange) % bufferMax;
            uint256[8192] storage buffer = buffers[id];
            buffer.write(data.bufferIndex, newTick, uint16(timeChange));
        }

        data.currentTick = newTick;
        data.lastUpdate = block.timestamp;
        unchecked {
            ++data.count;
        }

        return BaseHook.beforeSwap.selector;
    }

    function clampTime(uint256 t) private pure returns (uint256) {
        unchecked {
            return t > type(uint16).max ? uint256(type(uint16).max) : t;
        }
    }
}
