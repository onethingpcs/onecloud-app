#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2009 - 2013 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

precision mediump float;

in      vec3        texCoord;
out     vec4        color;
uniform samplerCube texCubemap; 

void main(void)
{
    /* Output to the framebuffer. */
    color = texture(texCubemap, texCoord);
}