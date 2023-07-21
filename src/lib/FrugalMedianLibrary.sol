// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library FrugalMedianLibrary {
    function frugalMedian(int256[] memory sequence) public pure returns (int256 approxMedian) {
        int256 step;
        uint256 i;
        bool positive;
        for (i; i < sequence.length;) {
            (approxMedian, step, positive) = updateApproxMedian(sequence[i], approxMedian, step, positive);
            unchecked {
                ++i;
            }
        }
    }

    function updateApproxMedian(int256 newNumber, int256 approxMedian, int256 step, bool positive)
        public
        pure
        returns (int256, int256, bool)
    {
        unchecked {
            if (newNumber > approxMedian) {
                step += positive ? stepIncrement(step) : -stepIncrement(step);
                // line 6: we cant do ceiling
                approxMedian += (step > 0) ? step : int256(1);
                if (approxMedian > newNumber) {
                    step += newNumber - approxMedian;
                    approxMedian = newNumber;
                }
                if (!positive && step > 1) {
                    step = 1;
                }
                positive = true;
            } else if (newNumber < approxMedian) {
                step += !positive ? stepIncrement(step) : -stepIncrement(step);
                approxMedian -= (step > 0) ? step : int256(1);
                // line 18
                if (approxMedian < newNumber) {
                    step += approxMedian - newNumber;
                    approxMedian = newNumber;
                }
                if (positive && step > 1) {
                    step = 1;
                }
                positive = false;
            }
        }
        return (approxMedian, step, positive);
    }

    function stepIncrement(int256 step) private pure returns (int256) {
        return 1;
    }
}
