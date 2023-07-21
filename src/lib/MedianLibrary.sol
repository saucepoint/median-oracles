// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library MedianLibrary {
    function medianRoundDown(uint256[] memory nums) public pure returns (uint256) {
        uint256 k;
        unchecked {
            k = (nums.length / 2) - 1;
        }
        return findKthSmallest(nums, k);
    }

    function medianMidPoint(uint256[] memory nums) public pure returns (uint256) {
        uint256 n = nums.length;
        if (n % 2 == 0) {
            uint256 lower = findKthSmallest(nums, (n / 2) - 1);
            uint256 higher = findKthSmallest(nums, (n / 2));
            return (lower + higher) / 2;
        } else {
            return findKthSmallest(nums, (n / 2));
        }
    }

    // -- Quick Select -- //
    function quickselect(uint256[] memory arr, uint256 left, uint256 right, uint256 k)
        internal
        pure
        returns (uint256)
    {
        if (left == right) {
            return arr[left];
        }

        uint256 pivotIndex = partition(arr, left, right);

        if (k == pivotIndex) {
            return arr[k];
        } else if (k < pivotIndex) {
            return quickselect(arr, left, pivotIndex - 1, k);
        } else {
            return quickselect(arr, pivotIndex + 1, right, k);
        }
    }

    function partition(uint256[] memory arr, uint256 left, uint256 right) internal pure returns (uint256) {
        // arbitrary pivot selection?
        uint256 pivotValue = arr[right];
        uint256 i = left;
        uint256 j;
        // iterate from left index to right index
        for (j = left; j < right;) {
            // element is less than pivot value
            // swap element to the cache index
            if (arr[j] <= pivotValue) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                unchecked {
                    ++i;
                }
            }
            unchecked {
                ++j;
            }
        }

        // swap `right` into the last cache index
        (arr[i], arr[right]) = (arr[right], arr[i]);

        // every element less than index `i` is less than the pivot value
        return i;
    }

    /// @notice Search for the kth smallest element in an array
    /// @dev Uses the quick select algorithm O(log2(n))
    /// @param arr The array to search
    /// @param k The index of the element to search for. k = 0 returns the smallest
    function findKthSmallest(uint256[] memory arr, uint256 k) public pure returns (uint256) {
        require(0 <= k && k < arr.length, "Invalid k value");
        uint256 right;
        unchecked {
            right = arr.length - 1;
        }
        return quickselect(arr, 0, right, k);
    }
}
