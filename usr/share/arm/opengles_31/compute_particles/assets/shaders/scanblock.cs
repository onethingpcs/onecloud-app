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
 * The main idea of the sorting algorithm is based on counting.
 * For example, say that we need to put the number 3 in sorted order,
 * and we know that there are in total 5 numbers less than 3 in the input.
 * Then we know that our number must come after all of these - that is, in position 5!
 * 
 * To determine such a value for each number in our input, we use a prefix sum
 * (also known as a scan).
 * 
 * It works like this, let's make this our input that we want to sort:
 *     1 3 2 0 1 0 2 2
 * 
 * (the actual input may have values greater than 3, but the scan only operates
 * on 2 bit values, because the radix sort works on 2-bit stages. We mask out
 * the interesting digit based on the <bitOffset> value.)
 * 
 * We then construct four flag arrays, one for each possible digit,
 * that has a 1 where the key matches the digit, and 0 elsewhere:
 *     0 0 0 1 0 1 0 0 <- 0
 *     1 0 0 0 1 0 0 0 <- 1
 *     0 0 1 0 0 0 1 1 <- 2
 *     0 1 0 0 0 0 0 0 <- 3
 *  
 * If we do an exclusive prefix sum over these arrays (carrying over the sum
 * from each array to the next) we get:
 *     0 0 0 0 1 1 2 2 <- 0
 *     2 3 3 3 3 4 4 4 <- 1
 *     4 4 4 5 5 5 5 6 <- 2
 *     7 7 8 8 8 8 8 8 <- 3 (note that 7 was carried over instead of 6)
 *  
 * Now we have all we need!
 * We then go through each element in the input, and look at this table to find
 * out where the element should go in the sorted output.
 * 
 * For example, the first 0 is located in the fourth column (as marked by the flag).
 * The scan array that corresponds to 0 contains the number 0 at this columns.
 * Thus, the first 0 should go to location 0.
 * 
 * Not too bad!
 * What about the first 1?
 * 
 * It is masked in the first column, second row.
 * We then look at the second row to determine its offset.
 * The scan value there is 2. So the first 1 should go to index 2 in the output.
*/

/*
 * For efficiency, we perform the prefix sum in blocks.
 * For example, with blocks of 4-by-4 elements, calculating the prefix sum of
 *     0 0 0 1 0 1 0 0
 * is done by first scanning each block individually
 *     0 0 0 0 | 0 0 1 1
 *  
 * To merge these two we need to add the sum of elements in the first block,
 * to each element in the second block. So first we compute the sums
 *     1 | 1
 * then we take the prefix sum of this again!
 *     0 | 1
 * Finally we add sums[i] to each element in block[i], and so on
 *     0 0 0 0 (+ 0) | 0 0 1 1 (+ 1)
 *     0 0 0 0 | 1 1 2 2
 * 
 * Because we need to perform four prefix sums, the sums array is a uvec4 array.
 * The xyzw components correspond to the digit 0, 1, 2 and 3
 * scan arrays, respectively. Storing it as a vector allows us to use vector math
 * to operate on each array in single expressions.
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

shared uvec4 sharedData[gl_WorkGroupSize.x];

uniform uint bitOffset;
uniform vec3 axis;
uniform float zMin;
uniform float zMax;

/*
 * The particles are sorting by increasing distance along the sorting axis.
 * We find the distance by a simple dot product. But the sorting algorithm
 * needs integer keys (16-bit in this case), so we convert the distance from
 * the range [zMin, zMax] -> [0, 65535].
 * Finally we extract the current working digit (2-bit in this case) from the key.
*/
uint decodeKey(uint index)
{
    float z = dot(Input[index].xyz, axis);
    z = 65535.0 * clamp( (z - zMin) / (zMax - zMin), 0.0, 1.0 );
    return (uint(z) >> bitOffset) & 3U;
}

void main()
{
    uint global_i = gl_GlobalInvocationID.x;
    uint block_i = gl_WorkGroupID.x;
    uint local_i = gl_LocalInvocationID.x;
    const uint blockSize = gl_WorkGroupSize.x;
    const uint steps = uint(log2(float(blockSize))) + 1U;

    uint key = decodeKey(global_i);
    uvec4 flag = uvec4(key == 0U ? 1U : 0U, key == 1U ? 1U : 0U, key == 2U ? 1U : 0U, key == 3U ? 1U : 0U);
    sharedData[local_i] = flag;

    // Wait for other threads within the block to have done the same
    memoryBarrierShared();
    barrier();

    // The prefix sum routine works on shared memory for efficiency!
    for (uint step = 0U; step < steps; step++)
    {
        uint rd_id = (1U << step) * (local_i >> step) - 1U;
        uint mask = (local_i & (1U << step)) >> step;
        sharedData[local_i] += sharedData[rd_id] * mask;
        memoryBarrierShared();
        barrier();
    }

    // Subtract initial value to get exclusive prefix sum
    Scan[global_i] = sharedData[local_i] - flag;
    memoryBarrierShared();
    barrier();

    // Store the sum of all elements of this block to the sums array
    // (which is equal to the last element in the inclusive prefix sum)
    Sums[block_i] = sharedData[blockSize - 1U];

    // This is used later to determine how to rearrange the input
    Flag[global_i] = flag;
}
