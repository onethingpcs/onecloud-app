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

// Compute next miplevel for Hi-Z depth map.

// Want highp since depth is 24-bit.
precision highp float;

layout(binding = 0) uniform sampler2D uTexture; 
out vec4 FragColor;
in vec2 vTex;

void main()
{
    vec4 depths = textureGather(uTexture, vTex, 0);
    gl_FragDepth = max(max(depths.x, depths.y), max(depths.z, depths.w));
}
