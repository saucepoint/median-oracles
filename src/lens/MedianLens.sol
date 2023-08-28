// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolIdLibrary, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {RingBufferLibrary} from "../lib/RingBufferLibrary.sol";
import {BufferData} from "../TickObserver.sol";
import {MedianLibrary} from "../lib/MedianLibrary.sol";

interface ITickObserver {
    function buffers(bytes32 poolId) external view returns (uint256[8192] memory);
    function bufferData(bytes32 poolId) external view returns (BufferData memory);
    function get50Observations(PoolKey calldata key) external view returns (int256[] memory sequence);
}

contract MedianLens {
    using PoolIdLibrary for PoolKey;
    using RingBufferLibrary for uint256[8192];
    using MedianLibrary for int256[];

    ITickObserver public immutable observer;

    constructor(ITickObserver _observer) {
        observer = _observer;
    }

    function readOracle(PoolKey calldata key, uint256 numObservations) external view returns (int256) {
        require(numObservations == 50, "only 10 minute intervals supported");
        int256[] memory sequence = observer.get50Observations(key);
        return sequence.medianRoundDown();
    }
}
