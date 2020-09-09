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

in vec3 position;
in vec3 normal;

out vec3 vPosition;
out vec2 vShadowTexel;

uniform mat4 projection;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projectionViewLight;

void main()
{
    vPosition = (model * vec4(position, 1.0)).xyz;
    gl_Position = projection * view * vec4(vPosition, 1.0);

    // project onto shadowmap
    vec4 posFromLight = projectionViewLight * vec4(vPosition, 1.0);
    vShadowTexel = posFromLight.xy * 0.5 + vec2(0.5);
}
