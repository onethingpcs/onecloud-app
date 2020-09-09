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

in vec3 vObjectVertexCoordinates;
in vec3 vObjectVertexNormal;

uniform mat4 uMVP;

out highp vec3 vNormal;
out highp vec4 vPosition;

void main()
{	
	vNormal = vObjectVertexNormal.xyz;
	gl_Position = uMVP * vec4(vObjectVertexCoordinates, 1.0);
	vPosition = gl_Position;
}