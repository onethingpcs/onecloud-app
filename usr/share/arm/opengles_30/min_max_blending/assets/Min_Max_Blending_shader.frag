#version 300 es

/*
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2012 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

precision mediump float;
precision mediump int;
precision mediump isampler3D;

/* Value used to normalize color values. */
const highp int maxShort = 32768;
/* Value used to brighten output color. */
const float contrastModifier = 3.0;
 
/* Input taken from vertex shader. */ 
in vec3 uvwCoordinates;

/* 3D integer texture sampler. */
uniform isampler3D textureSampler;
/* Boolean value indicating current blending equation. */
uniform bool isMinBlending;
/* Threshold used for min blending. */
uniform float minBlendingThreshold;

/* Output variable. */
out vec4 fragColor;

void main()
{
	/* Loaded texture short integer data are in big endian order. Swap the bytes. */
	ivec4 initialTexture          = ivec4(texture(textureSampler, uvwCoordinates).rrr, 1.0);
	ivec4 swappedBytesTextureTemp =  (initialTexture << 8) & ivec4(0xFF00);
	ivec4 swappedBytesTexture	  = ((initialTexture >> 8) & ivec4(0x00FF)) | swappedBytesTextureTemp;
	
	/* Determine output fragment color. */
	fragColor = vec4(swappedBytesTexture) / float(maxShort) * contrastModifier;
	
	/* If min blending is set, discard fragments that are not bright enough. */
	if (isMinBlending && length(fragColor) < minBlendingThreshold)
	{		
		discard;
	}
}