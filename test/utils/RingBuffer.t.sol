// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {RingBufferLibrary} from "../../src/lib/RingBufferLibrary.sol";

contract RingBufferTest is Test {
    using RingBufferLibrary for uint256[8192];

    uint256[8192] buffer;

    function setUp() public {}

    function test_readWrite() public {
        buffer.write(0, 1, 2);
        (int16 tick, uint16 duration) = buffer.read(0);
        assertEq(tick, 1);
        assertEq(duration, 2);

        buffer.write(10, 200, 300);
        (tick, duration) = buffer.read(10);
        assertEq(tick, 200);
        assertEq(duration, 300);
    }
}
