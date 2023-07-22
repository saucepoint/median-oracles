// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library RingBufferLibrary {
    function read(uint256[8192] calldata buffer, uint256 index) public pure returns (int16 tick, uint16 duration) {
        unchecked {
            uint256 packed = buffer[index / 8];
            uint256 shift = 32 * (index % 8);

            // tick is top 16 bits
            tick = int16(uint16(packed >> (shift + 16)));

            // duration is bottom 16 bits
            duration = uint16(packed >> shift);
        }
    }

    // TODO: prevent out-of-bounds writes
    function write(uint256[8192] storage buffer, uint256 index, int16 tick, uint16 duration) public {
        unchecked {
            uint256 packed = (uint256(uint16(tick)) << 16) | duration;
            uint256 shift = 32 * (index % 8);
            buffer[index / 8] = (buffer[index / 8] & ~(0xFFFFFFFF << shift)) | (packed << shift);
        }
    }
}
