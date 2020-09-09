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

in vec3 vPosition;
in vec2 vShadowTexel;

out vec4 outColor;

uniform vec3 color;
uniform sampler2D shadowMap0;

float sampleShadow()
{
    vec4 shadow0 = texture(shadowMap0, vShadowTexel);
    return clamp(dot(shadow0, vec4(1.0)), 0.0, 1.0);
}

void main()
{
    float r2 = dot(vPosition, vPosition);
    outColor.rgb = color * exp2(-r2 * 0.2 + 1.5);
    outColor.a = 1.0;

    // shadow from particles
    float shadow = sampleShadow();
    outColor.rgb = mix(outColor.rgb, color * vec3(0.1, 0.12, 0.15), shadow);

    // approximate gamma correction
    outColor.rgb = sqrt(outColor.rgb);
}
