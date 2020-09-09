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

precision mediump float;

layout(binding = 0) uniform sampler2D uTexture; 
out vec4 FragColor;
in vec2 vTex;

void main()
{
    FragColor = texture(uTexture, vTex);
}
