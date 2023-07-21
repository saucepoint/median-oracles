// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {FrugalMedianLibrary} from "../../src/lib/FrugalMedianLibrary.sol";

contract FrugalMedianTest is Test {
    using FrugalMedianLibrary for int256[];

    function setUp() public {}

    function test_medianSimple() public {
        int256[] memory sequence = new int256[](8);
        sequence[0] = 4;
        sequence[1] = 2;
        sequence[2] = 1;
        sequence[3] = 5;
        sequence[4] = 3;
        sequence[5] = 2;
        sequence[6] = 5;
        sequence[7] = 4;
        assertEq(sequence.frugalMedian(), 4);
    }

    function test_medianGas() public {
        int256[] memory sequence = new int256[](8);
        sequence[0] = 4;
        sequence[1] = 2;
        sequence[2] = 1;
        sequence[3] = 5;
        sequence[4] = 3;
        sequence[5] = 2;
        sequence[6] = 5;
        sequence[7] = 4;

        uint256 gasBefore = gasleft();
        sequence.frugalMedian();
        uint256 gas = gasBefore - gasleft();
        console.log("Frugal gas %s", gas);
        assertEq(sequence.frugalMedian(), 4);
    }
}
