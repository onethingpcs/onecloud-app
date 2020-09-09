#version 310 es

/*
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 *     ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

layout (local_size_x = 8) in;
layout (std140, binding = 0) buffer Data {
    float data[];
};

void main()
{
    data[gl_GlobalInvocationID.x] = 1.0;
}
