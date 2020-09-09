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

uniform  sampler2D u_s2dTexture;
in       vec2      v_v2TexCoord;
in       vec4      v_v4FontColor;
out      vec4      color;

void main()
{
    vec4 v4Texel = texture(u_s2dTexture, v_v2TexCoord);
    color = v_v4FontColor * v4Texel;
}