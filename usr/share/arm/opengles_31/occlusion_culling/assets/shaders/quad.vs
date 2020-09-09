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

// Trivial shader to blit textures.

layout(location = 0) in vec2 aVertex;
out vec2 vTex;

void main()
{
    gl_Position = vec4(aVertex, 0.0, 1.0);
    vTex = aVertex * 0.5 + 0.5;
}
