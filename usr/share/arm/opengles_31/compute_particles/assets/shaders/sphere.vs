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

out vec2 vShadowTexel;
out vec3 vNormal;

uniform mat4 projection;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projectionViewLight;

void main()
{
    vec4 mPosition = model * vec4(position, 1.0);
    vNormal = (model * vec4(position, 0.0)).xyz;
    gl_Position = projection * view * mPosition;

    // project onto shadowmap
    vec4 posFromLight = projectionViewLight * mPosition;
    vShadowTexel = posFromLight.xy * 0.5 + vec2(0.5);
}
