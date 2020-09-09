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

in float lifetime;
in vec3 color;

uniform float particleLifetime;

out vec4 outColor;

void main()
{
    // Alpha blending
    vec2 xy = 2.0 * gl_PointCoord.xy - vec2(1.0);
    float r2 = dot(xy, xy);

    outColor.a = exp2(-r2 * 5.0);
    outColor.rgb = color;

    // Smooth alphablending into and out of existence
    float s = clamp(lifetime / particleLifetime, 0.0, 1.0);
    outColor.a *= s;

    // Premultiply alpha
    outColor.rgb *= outColor.a;
}
