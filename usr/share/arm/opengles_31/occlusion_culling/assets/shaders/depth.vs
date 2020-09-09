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

// Used by Hi-Z culler to render depth map.

layout(location = 0) in vec4 aVertex;
layout(location = 0) uniform mat4 uVP;

void main()
{
    gl_Position = uVP * aVertex;
}
