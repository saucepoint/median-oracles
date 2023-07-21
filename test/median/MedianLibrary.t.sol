// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {MedianLibrary} from "../../src/lib/MedianLibrary.sol";

contract MedianLibraryTest is Test {
    using MedianLibrary for uint256[];

    function setUp() public {}

    function test_medianSimple() public {
        uint256[] memory sequence = new uint256[](8);
        sequence[0] = 4;
        sequence[1] = 2;
        sequence[2] = 1;
        sequence[3] = 5;
        sequence[4] = 3;
        sequence[5] = 2;
        sequence[6] = 5;
        sequence[7] = 4;
        assertEq(sequence.medianRoundDown(), 3);
    }

    function test_medianGas() public {
        uint256[] memory sequence = new uint256[](8);
        sequence[0] = 4;
        sequence[1] = 2;
        sequence[2] = 1;
        sequence[3] = 5;
        sequence[4] = 3;
        sequence[5] = 2;
        sequence[6] = 5;
        sequence[7] = 4;

        uint256 gasBefore = gasleft();
        sequence.medianRoundDown();
        uint256 gas = gasBefore - gasleft();
        console.log("Median gas %s", gas);
        assertEq(sequence.medianRoundDown(), 3);
    }

    function test_medianRoundDown() public {
        uint256[] memory nums = new uint256[](2);
        nums[0] = 1;
        nums[1] = 2;
        uint256 median = nums.medianRoundDown();
        assertEq(median, 1);

        nums = new uint256[](4);
        nums[0] = 1;
        nums[1] = 2;
        nums[2] = 3;
        nums[3] = 4;
        median = nums.medianRoundDown();
        assertEq(median, 2);
    }

    function test_medianRoundDown_unsorted() public {
        uint256[] memory nums = new uint256[](2);
        nums[0] = 20;
        nums[1] = 10;
        uint256 median = nums.medianRoundDown();
        assertEq(median, 10);

        nums = new uint256[](4);
        nums[0] = 20;
        nums[1] = 10;
        nums[2] = 30;
        nums[3] = 40;
        median = nums.medianRoundDown();
        assertEq(median, 20);
    }

    function test_medianMidPoint() public {
        uint256[] memory nums = new uint256[](2);
        nums[0] = 10;
        nums[1] = 20;
        uint256 median = nums.medianMidPoint();
        assertEq(median, 15);

        nums = new uint256[](3);
        nums[0] = 10;
        nums[1] = 20;
        nums[2] = 30;
        median = nums.medianMidPoint();
        assertEq(median, 20);
    }

    function test_medianMidPoint_unsorted() public {
        uint256[] memory nums = new uint256[](2);
        nums[0] = 20;
        nums[1] = 10;
        uint256 median = nums.medianMidPoint();
        assertEq(median, 15);

        nums = new uint256[](3);
        nums[0] = 20;
        nums[1] = 10;
        nums[2] = 30;
        median = nums.medianMidPoint();
        assertEq(median, 20);
    }
}
