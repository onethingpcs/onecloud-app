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

/* Determines the resulting color by taking appropriate data from inputTexture. */
uvec4 determineResultColor();

/* Apply Rule 30 using the pixels from one line above.
 * Since the input textures contain only red component, the implementation checks
 * if its value in the upper line pixels is higher or lower than 0.5. Then it returns
 * black or white color vectors, following the Rule 30. 
 */
uvec4 applyRule30(uvec4 upperLeftPixel, uvec4 upperCenterPixel, uvec4 upperRightPixel);

/* UV coordinates received from vertex shader. */
in vec2 fragmentTexCoord;

/* Sampler holding current input texture, from which the output is determined. */
uniform usampler2D inputTexture;
/* A uniform used to determine UV coordinates of the input line. */
uniform float     inputVerticalOffset;
/* A uniform used to point to neighbouring pixels. */
uniform float	  inputNeighbour;

/* Output variable. */
out uvec4 fragColor;

void main()
{
	fragColor = determineResultColor();
}

/* See the description of the declaration. */
uvec4 determineResultColor()
{
	uvec4 upperLeftPixel   = texture(inputTexture, fragmentTexCoord - vec2(inputNeighbour,  inputVerticalOffset));
	uvec4 upperCenterPixel = texture(inputTexture, fragmentTexCoord - vec2(0.0, 		    inputVerticalOffset));
	uvec4 upperRightPixel  = texture(inputTexture, fragmentTexCoord - vec2(-inputNeighbour, inputVerticalOffset));
	
	return applyRule30(upperLeftPixel, upperCenterPixel, upperRightPixel);
}

/* See the description of the declaration. */
uvec4 applyRule30(uvec4 upperLeftPixel, uvec4 upperCenterPixel, uvec4 upperRightPixel)
{	
	/* Value of upper left pixel to be compared. */
	uint upperLeftCompare   = upperLeftPixel.r;
	/* Value of upper center pixel to be compared. */
	uint upperCenterCompare = upperCenterPixel.r;
	/* Value of upper right pixel to be compared. */
	uint upperRightCompare  = upperRightPixel.r;
	
	if (upperLeftCompare == 0u   && upperCenterCompare == 0u   && upperRightCompare == 0u   ||
		upperLeftCompare == 255u && upperCenterCompare == 0u   && upperRightCompare == 255u ||
		upperLeftCompare == 255u && upperCenterCompare == 255u && upperRightCompare == 0u   ||
		upperLeftCompare == 255u && upperCenterCompare == 255u && upperRightCompare == 255u)
	{		
		return uvec4(0u, 0u, 0u, 255u);
	}
	else
	{		
		return uvec4(255u, 255u, 255u, 255u);
	}
}