#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2009 - 2013 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
 
out     vec3 texCoord;
uniform mat4 viewMat;

void main(void)
{
     const vec3 vertices[4] = vec3[4](vec3(-1.0f, -1.0f, 1.0f),
                                      vec3( 1.0f, -1.0f, 1.0f),
                                      vec3(-1.0f,  1.0f, 1.0f),
                                      vec3( 1.0f,  1.0f, 1.0f));

    /* Multiply the cube's vertex position by 
       the rotational part of a view matrix. */
    texCoord = mat3(viewMat) * vertices[gl_VertexID];

    /* Calculate the position of the current vertex. */
    gl_Position = vec4(vertices[gl_VertexID], 1.0f);
}