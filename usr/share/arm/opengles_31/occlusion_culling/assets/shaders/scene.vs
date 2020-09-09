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

layout(location = 0) in vec3 aVertex;
layout(location = 1) in vec3 aNormal;
layout(location = 3) in vec3 aOffset; // Instanced array

layout(location = 0) uniform mat4 uVP;

out vec3 vNormal;

void main()
{
    vec3 world = aVertex + aOffset;
    gl_Position = uVP * vec4(world, 1.0);
    vNormal = aNormal;
}
