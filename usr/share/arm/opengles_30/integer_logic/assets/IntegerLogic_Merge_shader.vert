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

/* Coordinates of the drawn quad. */
in vec4  position;
/* Input UV coordinates. */
in vec2  vertexTexCoord;

/* Model-View-Projection matrix. */
uniform  mat4  mvpMatrix;

/* UV coordinates passed to fragment shader. */
out vec2 fragmentTexCoord;

void main()
{	
	/* Pass texture coordinates to fragment shader. */
	fragmentTexCoord = vertexTexCoord;
	
	/* Determine gl_Position. */
	gl_Position = mvpMatrix * position;
}