#version 310 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 *     ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

/*
 * This program merges the block-wise prefix sums of the input into a 
 * single prefix sum. It does this by adding the sum of elements in a previous
 * block to the next one, accumulating the sum as we go along. The sums to
 * add are located in the SumsBuffer.
 *
 * Finally, we shuffle the elements to their correct positions.
 * The new position is given by the prefix
 * sum value in the element's scan array.
 * 
 * For example, if our keys (for the current stage) are as following:
 *     1 3 2 0 1 0 2 2
 *  
 * We get these digit scan arrays
 *     0 0 0 0 1 1 2 2 <- 0
 *     2 3 3 3 3 4 4 4 <- 1
 *     4 4 4 5 5 5 5 6 <- 2
 *     7 7 8 8 8 8 8 8 <- 3
 *  
 * And these flags
 *     0 0 0 1 0 1 0 0 <- 0
 *     1 0 0 0 1 0 0 0 <- 1
 *     0 0 1 0 0 0 1 1 <- 2
 *     0 1 0 0 0 0 0 0 <- 3
 *  
 * (Note that the columns of these are stored as uvec4s in the buffers)
 * 
 * In column 1 we have a flag in the second row, because the key is (1) in the first position.
 * Looking at the scan array belonging to (1) we find that the offset is 2.
 * So the first element should be reordered to position 2 in the sorted array.
*/

layout (local_size_x = 32) in; // Must equal <block_size> in sort.h
layout (std430, binding = 0) buffer ScanBuffer {
    uvec4 Scan[];
};

layout (std430, binding = 1) buffer SumsBuffer {
    uvec4 Sums[];
};

layout (std430, binding = 2) buffer InputBuffer {
    vec4 Input[];
};

layout (std430, binding = 3) buffer FlagBuffer {
    uvec4 Flag[];
};

layout (std430, binding = 4) buffer SortedInputBuffer {
    vec4 SortedInput[];
};

void main()
{
    uint global_i = gl_GlobalInvocationID.x;
    uint block_i = uint(gl_WorkGroupID.x);

    // The sums array contains the inclusive prefix sum, so we need to
    // offset it to get the exclusive prefix sum
    uvec4 blockSum = block_i > 0U ? Sums[block_i - 1U] : uvec4(0U);

    // Used to decide which element to reorder
    uvec4 flag = Flag[global_i];

    // Carry over the sum of each digit array to the next
    uvec4 total = Sums[gl_NumWorkGroups.x - 1U];
    uvec4 carry = uvec4(0U, total.x, total.x + total.y, total.x + total.y + total.z);

    // Merge the scan blocks
    uvec4 scan = Scan[global_i];
    scan += blockSum + carry;

    // Write back for debugging
    // Scan[gl_GlobalInvocationID.x] = scan;

    // Move element to correct position
    vec4 position = Input[global_i];
    uint offset = uint(dot(vec4(scan), vec4(flag)));
    SortedInput[offset] = position;
}
