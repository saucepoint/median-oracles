// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {RingBufferLibrary} from "../lib/RingBufferLibrary.sol";
import {BufferData} from "../TickObserver.sol";
import {FrugalMedianLibrary} from "../lib/FrugalMedianLibrary.sol";

interface ITickObserver {
    function buffers(bytes32 poolId) external view returns (uint256[8192] memory);
    function bufferData(bytes32 poolId) external view returns (BufferData memory);
    function get50Observations(IPoolManager.PoolKey calldata key) external view returns (int256[] memory sequence);
}

contract FrugalMedianLens {
    using PoolId for IPoolManager.PoolKey;
    using RingBufferLibrary for uint256[8192];
    using FrugalMedianLibrary for int256[];

    ITickObserver public immutable observer;

    constructor(ITickObserver _observer) {
        observer = _observer;
    }

    function readOracle(IPoolManager.PoolKey calldata key, uint256 numObservations) external view returns (int256) {
        require(numObservations == 50, "only 10 minute intervals supported");
        int256[] memory sequence = observer.get50Observations(key);
        return sequence.frugalMedian();
    }
}
