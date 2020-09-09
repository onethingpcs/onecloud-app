#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2012 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
 
in        vec4 attributePosition;
in        vec2 attributeTextureCoordinate;
uniform   mat4 modelViewMatrix;
out   	  vec2 varyingTextureCoordinate;

void main()
{
	varyingTextureCoordinate = attributeTextureCoordinate;
	gl_Position     		 = modelViewMatrix * attributePosition;
}