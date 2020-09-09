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

precision mediump float;

in vec4 mask0;

out vec4 out0;

void main()
{
    vec2 xy = 2.0 * gl_PointCoord.xy - vec2(1.0);
    float r2 = dot(xy, xy);
    float opacity = exp2(-r2 * 5.0) * 0.025;
    out0 = opacity * mask0;
}
