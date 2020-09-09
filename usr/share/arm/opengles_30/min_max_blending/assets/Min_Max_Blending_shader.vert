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

/* Input vertex position. */ 
in vec4 inputPosition;
/* Input U/V/W texture coordinates. */
in vec3 inputUVWCoordinates;

/* Constant tranformation matrices. */
uniform mat4 cameraMatrix;
uniform mat4 projectionMatrix;

/* Vector storing rotation coefficients for rotation matrices. */
uniform vec3 rotationVector;

/* Number of instances that are going to be drawn. */
uniform int instancesCount;

/* Output texture coordinates passed to fragment shader. */
out vec3 uvwCoordinates;

void main()
{
	mat4 modelViewProjectionMatrix;

	/* Matrix rotating texture coordinates around X axis. */
	mat3 xRotationMatrix = mat3(1.0,  0.0, 				  			  0.0, 	 						  
							    0.0,  cos(radians(rotationVector.x)), sin(radians(rotationVector.x)), 
							    0.0, -sin(radians(rotationVector.x)), cos(radians(rotationVector.x)));
	
	/* Matrix rotating texture coordinates around Y axis. */	
	mat3 yRotationMatrix = mat3(cos(radians(rotationVector.y)), 0.0,	-sin(radians(rotationVector.y)), 
							    0.0, 							 1.0, 	 0.0, 							 
							    sin(radians(rotationVector.y)), 0.0, 	 cos(radians(rotationVector.y)));
	
	/* Matrix rotating texture coordinates around Z axis. */
	mat3 zRotationMatrix = mat3( cos(radians(rotationVector.z)), sin(radians(rotationVector.z)), 0.0, 
							    -sin(radians(rotationVector.z)), cos(radians(rotationVector.z)), 0.0, 
							     0.0, 						  	 0.0,    			  			 1.0);
	
	/* U/V/W coordinates pointing at appropriate layer depending on gl_InstanceID. */
	vec3 translatedUVWCoordinates = inputUVWCoordinates - vec3(0.0, 0.0, float(gl_InstanceID) / float(instancesCount - 1));
		
	/* 
	 * Translate from <0.0, 1.0> interval to <-1.0, 1.0> to rotate texture coordinates around their center. 
     * Otherwise, the rotation would take place around the XYZ axes which would spoil the effect.
	 * The translated coordinates should be translated back to <0.0, 1.0> after all rotations are done.
	 */
	translatedUVWCoordinates = translatedUVWCoordinates * 2.0 - vec3(1.0);
	
	/* Rotate texture coordinates. */
	translatedUVWCoordinates = xRotationMatrix * translatedUVWCoordinates;
	translatedUVWCoordinates = yRotationMatrix * translatedUVWCoordinates;
	translatedUVWCoordinates = zRotationMatrix * translatedUVWCoordinates;
	
	/* Translate back to <0.0, 1.0> interval. */
	uvwCoordinates = (translatedUVWCoordinates + vec3(1.0)) / 2.0;
	
	/* Calculate Model-View-Projection matrix. */
	modelViewProjectionMatrix = projectionMatrix * cameraMatrix;
	
	/* Calculate position of vertex. With each instance squares are drawn closer to the viewer. */
	gl_Position = modelViewProjectionMatrix * (inputPosition + vec4(0.0, 0.0, float(gl_InstanceID) / float(instancesCount - 1), 0.0));
}