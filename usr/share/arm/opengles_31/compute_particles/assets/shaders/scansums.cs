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
 * We perform an inclusive prefix sum over the sums array
 * In order to do this in one step (one shader dispatch)
 * we would ideally fit the entire sums array into one thread group.
 * But since the number of elements might exceed the max work group size,
 * or it might give unoptimal performance, we split the array
 * into blocks and perform a tile-wise prefix sum, merging the blocks manually.
 * This leads to a couple of loops, but as long as the sizes are constant,
 * these should be unrolled by the compiler.
 */

layout (local_size_x = 32) in; // Must be less than or equal to <numSums>
layout (std430, binding = 1) buffer SumsBuffer {
    uvec4 Sums[];
};

const uint numSums = 512U; // Must equal <num_blocks> in sort.cpp
const uint numBlocks = numSums / gl_WorkGroupSize.x;
const uint blockSize = gl_WorkGroupSize.x;
const uint steps = uint(log2(float(blockSize))) + 1U;
shared uvec4 sharedData[gl_WorkGroupSize.x * numBlocks];

void main()
{
    uint local_i = gl_LocalInvocationID.x;

    // Load the data to scan into shared storage
    for (uint i = 0U; i < numBlocks; i++)
        sharedData[local_i + i * blockSize] = Sums[local_i + i * blockSize];
    memoryBarrierShared();
    barrier();

    for (uint step = 0U; step < steps; step++)
    {
        uint rd_id = (1U << step) * (local_i >> step) - 1U;
        uint mask = (local_i & (1U << step)) >> step;

        // Apply operation on all blocks
        for (uint i = 0U; i < numBlocks; i++)
            sharedData[local_i + i * blockSize] += sharedData[rd_id + i * blockSize] * mask;
        memoryBarrierShared();
        barrier();
    }

    // Merge the blocks manually (there aren't that many blocks,
    // so speed should be ok)
    for (uint i = 1U; i < numBlocks; i++)
    {
        sharedData[local_i + i * blockSize] += sharedData[i * blockSize - 1U];
        memoryBarrierShared();
        barrier();
    }

    // Write back result to sums array
    for (uint i = 0U; i < numBlocks; i++)
        Sums[local_i + i * blockSize] = sharedData[local_i + i * blockSize];
}
