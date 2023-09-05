// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolIdLibrary, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {HookTest} from "./utils/HookTest.sol";
import {TickObserver} from "../src/TickObserver.sol";
import {TickObserverImplementation} from "./implementation/TickObserverImplementation.sol";

contract TickObserverTest is HookTest, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    TickObserver hook =
        TickObserver(address(uint160(Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG)));
    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {
        vm.warp(1690023971);
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // testing environment requires our contract to override `validateHookAddress`
        // well do that via the Implementation contract to avoid deploying the override with the production contract
        TickObserverImplementation impl = new TickObserverImplementation(manager, hook);
        etchHook(address(impl), address(hook));

        // Create the pool
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(hook));
        poolId = PoolIdLibrary.toId(poolKey);
        manager.initialize(poolKey, SQRT_RATIO_1_1, ZERO_BYTES);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );
    }

    function test_read() public {
        // Perform a test swap //
        int256 amount = 0.1e18;
        bool zeroForOne = true;
        swap(poolKey, amount, zeroForOne);
        skip(12);
        swap(poolKey, amount, zeroForOne);
        skip(12);
        swap(poolKey, amount, zeroForOne);
        skip(12);
        // ------------------- //

        hook.get50Observations(poolKey);
    }
}
