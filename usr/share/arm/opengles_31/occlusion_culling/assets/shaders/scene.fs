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

// Shader for generic objects in scene.
// Used for occluders here.
// Just render a constant color with some basic lighting.

precision mediump float;

layout(location = 1) uniform vec3 uColor;
layout(location = 2) uniform vec3 uLightDir;

out vec4 FragColor;
in vec3 vNormal;

void main()
{
    vec3 normal = normalize(vNormal);
    FragColor = vec4(uColor * (dot(uLightDir, normal) * 0.5 + 0.5), 1.0); // Half-lambertian
}
