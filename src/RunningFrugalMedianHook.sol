// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

contract RunningFrugalMedianHook is BaseHook {
    using PoolId for IPoolManager.PoolKey;

    uint256 public beforeSwapCount;
    uint256 public afterSwapCount;

    mapping(bytes32 poolId => OracleConfig config) public configs;
    mapping(bytes32 poolId => MedianState median) public medians;

    // hack: restrict pool to static configuration
    struct OracleConfig {
        uint256 bufferSize;
        uint256 bufferIndex;
        uint256 bufferLimit;
    }

    // fits in 256 bits
    struct MedianState {
        int124 approxMedian;
        int124 step;
        bool positive;
    }

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function initHook(IPoolManager.PoolKey calldata poolKey, uint256 bufferLimit) external {
        configs[poolKey.toId()] = OracleConfig({bufferSize: 0, bufferIndex: 0, bufferLimit: bufferLimit});
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
        beforeSwapCount++;
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
}
