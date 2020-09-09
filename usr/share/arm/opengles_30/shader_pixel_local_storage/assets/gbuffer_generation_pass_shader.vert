#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

/* GBuffer generation pass vertex shader */

/* Input per-vertex shader arguments */
in vec3 vObjectVertexCoordinates;
in vec3 vObjectVertexNormal;

/* Input per-object shader arguments */
uniform mat4 uMVP;
uniform vec3 uObjectColor;

/* Input per-object shader arguments */
out highp vec3 vColor;
out highp vec3 vNormal;

void main(void)
{
    /* [Pass color and normal vector into fragment shader, apply MVP to vertices] */
    vColor        = vec3(uObjectColor);
    vNormal       = vec3(vObjectVertexNormal);
    gl_Position   = uMVP * vec4(vObjectVertexCoordinates, 1.0);
    /* [Pass color and normal vector into fragment shader, apply MVP to vertices] */
}
