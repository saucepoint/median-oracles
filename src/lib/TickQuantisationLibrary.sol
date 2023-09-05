// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library TickQuantisationLibrary {
    int256 constant TICK_TRUNCATION = 30;

    function quantiseTick(int256 tick) public pure returns (int256) {
        unchecked {
            return (tick + (tick < 0 ? -(TICK_TRUNCATION - 1) : int256(0))) / TICK_TRUNCATION;
        }
    }

    function unQuantiseTick(int256 tick) public pure returns (int256) {
        unchecked {
            return tick * TICK_TRUNCATION + (TICK_TRUNCATION / 2);
        }
    }

    function memoryPackTick(int256 tick, uint256 duration) public pure returns (uint256) {
        unchecked {
            return (uint256(tick + 32768) << 16) | duration;
        }
    }

    function unMemoryPackTick(uint256 rec) public pure returns (int256) {
        unchecked {
            return int256(rec >> 16) - 32768;
        }
    }
}
