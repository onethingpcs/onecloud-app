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
 
in  	vec4  attributePosition;
uniform mat4  projectionMatrix;
uniform vec3  cubePosition;
uniform vec3  cameraPosition;

void main()
{
	/* Create transformation matrices. */
	mat4 modelTranslationMatrix = mat4 (1.0, 			0.0,            0.0, 			0.0, 
								        0.0, 			1.0,            0.0, 			0.0, 
								        0.0, 			0.0, 			1.0, 			0.0, 
								        cubePosition.x, cubePosition.y, cubePosition.z, 1.0);
	
	mat4 cameraTranslationMatrix = mat4 (1.0, 			     0.0,               0.0, 			  0.0, 
								         0.0, 			     1.0,               0.0, 			  0.0, 
								         0.0, 			     0.0, 			    1.0, 			  0.0, 
								         -cameraPosition.x, -cameraPosition.y, -cameraPosition.z, 1.0);
	

	/* Multiply model-space coordinates by model-view-projection matix to bring them into eye-space. */
	gl_Position = projectionMatrix * cameraTranslationMatrix * modelTranslationMatrix * attributePosition;
}