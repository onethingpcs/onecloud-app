#version 300 es

/** 
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2012 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

/* Coordinates of the drawn lines. */
in vec4  position;
/* Input UV coordinates. */
in vec2  vertexTexCoord;

/* Model-View-Projection matrix. */
uniform mat4  mvpMatrix;
/* A uniform used to determine the distance from the bottom of the drawn geometry of the currently drawn line. */
uniform float verticalOffset;

/* UV coordinates passed to fragment shader. */
out vec2 fragmentTexCoord;

void main()
{
	/* Pass texture coordinates to fragment shader. */
	fragmentTexCoord = vertexTexCoord;

	/* Determine gl_Position modified by verticalOffset. */
	gl_Position = (mvpMatrix * position) - vec4(0.0, verticalOffset, 0.0, 0.0);
}