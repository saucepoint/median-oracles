// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {FrugalMedianLibrary} from "./lib/FrugalMedianLibrary.sol";

contract RunningFrugalMedianHook is BaseHook, Test {
    using PoolId for IPoolManager.PoolKey;

    uint256 public beforeSwapCount;
    uint256 public afterSwapCount;

    mapping(bytes32 poolId => MedianState median) public medians;

    struct MedianState {
        int120 approxMedian;
        int120 step;
        bool positive;
    }

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function readOracle(IPoolManager.PoolKey calldata key) external view returns (int256) {
        return int256(medians[key.toId()].approxMedian);
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

        MedianState storage median = medians[id];
        (int256 newMedian, int256 newStep, bool newPositive) =
            FrugalMedianLibrary.updateApproxMedian(int256(tick), median.approxMedian, median.step, median.positive);

        median.approxMedian = int120(newMedian);
        median.step = int120(newStep);
        median.positive = newPositive;
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
