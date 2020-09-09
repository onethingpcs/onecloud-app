#version 300 es
/** 
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
 /* [Vertex shader source] */
/* [Define attributes] */
/* ATTRIBUTES */
in vec4 vertexCoordinates; /* Attribute: holding coordinates of triangles that make up a geometry. */
in vec3 vertexNormals;     /* Attribute: holding normals. */
/* [Define attributes] */

/* UNIFORMS */
uniform mat4 modelViewMatrix;           /* Model * View matrix */
uniform mat4 modelViewProjectionMatrix; /* Model * View * Projection matrix */
uniform mat4 normalMatrix;              /* transpose(inverse(Model * View)) matrix */

/* OUTPUTS */
out vec3 normalInEyeSpace; /* Normal vector for the coordinates. */
out vec4 vertexInEyeSpace; /* Vertex coordinates expressed in eye space. */

void main()
{
    /* Calculate and set output vectors. */
    normalInEyeSpace = mat3x3(normalMatrix) * vertexNormals;
    vertexInEyeSpace = modelViewMatrix      * vertexCoordinates;

    /* Multiply model-space coordinates by model-view-projection matrix to bring them into eye-space. */
    gl_Position = modelViewProjectionMatrix * vertexCoordinates;
}
 /* [Vertex shader source] */