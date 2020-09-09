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

in vec3 vLightboxVertexCoordinates;
uniform mat4 uMVP;

void main()
{
	gl_Position = uMVP * vec4(vLightboxVertexCoordinates, 1.0);
}