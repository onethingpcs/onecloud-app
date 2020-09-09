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
 
precision highp float;
precision lowp usampler2D;

/* UV coordinates received from vertex shader. */
in vec2 fragmentTexCoord;

/* Sampler holding the ping texture. */
uniform usampler2D pingTexture;
/* Sampler holding the pong texture. */
uniform usampler2D pongTexture;

/* Output variable. */
out vec4 fragColor;

void main()
{
	/* Determine if the currently drawn line is odd or even. */
	if((uint(gl_FragCoord.y) & 1u) == 0u)
	{
		/* Use the ping texture. */
		fragColor = vec4(texture(pingTexture, fragmentTexCoord).rrrr);
	}
	else
	{
		/* Use the pong texture. */
		fragColor = vec4(texture(pongTexture, fragmentTexCoord).rrrr);
	}
}