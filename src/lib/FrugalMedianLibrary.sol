// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library FrugalMedianLibrary {
    function frugalMedian(int256[] memory sequence) public pure returns (int256 approxMedian) {
        int256 num;
        int256 step;
        uint256 i;
        bool positive;
        for (i; i < sequence.length;) {
            unchecked {
                num = sequence[i];
                if (num > approxMedian) {
                    step += positive ? stepIncrement(step) : -stepIncrement(step);
                    // line 6: we cant do ceiling
                    approxMedian += (step > 0) ? step : int256(1);
                    if (approxMedian > num) {
                        step += num - approxMedian;
                        approxMedian = num;
                    }
                    if (!positive && step > 1) {
                        step = 1;
                    }
                    positive = true;
                } else if (num < approxMedian) {
                    step += !positive ? stepIncrement(step) : -stepIncrement(step);
                    approxMedian -= (step > 0) ? step : int256(1);
                    // line 18
                    if (approxMedian < num) {
                        step += approxMedian - num;
                        approxMedian = num;
                    }
                    if (positive && step > 1) {
                        step = 1;
                    }
                    positive = false;
                }

                ++i;
            }
        }
    }

    function stepIncrement(int256 step) private pure returns (int256) {
        return 1;
    }
}
