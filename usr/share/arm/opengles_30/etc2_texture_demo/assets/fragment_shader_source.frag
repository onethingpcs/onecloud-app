#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2012 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
 
precision mediump float;

uniform sampler2D uniformTexture;
in      vec2      varyingTextureCoordinate;
out     vec4      colour;

void main()
{
    colour = texture(uniformTexture, varyingTextureCoordinate);
}