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

// Shader for spheres in scene.

layout(location = 0) in vec3 aVertex;
layout(location = 3) in vec4 aOffset; // Instanced arrays

layout(location = 0) uniform mat4 uVP;

out vec3 vNormal;

void main()
{
    // .w component is radius. Sphere mesh is radius == 1.
    vec3 world = aOffset.w * aVertex + aOffset.xyz;
    gl_Position = uVP * vec4(world, 1.0);
    vNormal = aVertex;
}

