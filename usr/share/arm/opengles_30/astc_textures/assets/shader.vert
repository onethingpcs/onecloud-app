#version 300 es

/*
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 *     ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

in vec4 av4position;
in vec3 vv3normal;
in vec2 vv3tex2dcoord;

uniform mat4 mv;
uniform mat4 mvp;

out vec2 tex2dcoord;
out vec3 normal;
out vec3 light;
out vec3 view;

void main()
{
    vec3 light_position = vec3(15.0, 0.0, 0.0);
    
    /* Transform vertex posiotion and normals to the view space.
       We must make sure that light source and mesh data are in the same space. */
    vec4 P = mv * av4position;
    normal = mat3(mv) * vv3normal;

    /* Calculate light and view vectors. */
    light = light_position - P.xyz;
    view  = -P.xyz;

    /* Send the texture coordinates to the fragment shader. */
    tex2dcoord = vv3tex2dcoord;

    /* Decide whether the vertex belongs to the projection frustrum or not. */
    gl_Position = mvp * av4position;
}