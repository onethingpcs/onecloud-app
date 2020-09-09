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

precision mediump float;
 
/* Output color variable. */
out vec4 color;

void main()
{
	/* Set yellow color for a cube representing light source. */
	color = vec4(1.0, 1.0, 0.0, 0.6);
}