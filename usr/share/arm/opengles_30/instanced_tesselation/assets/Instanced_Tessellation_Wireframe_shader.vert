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

/* Input vertex coordinates. */ 
in vec4 position;

/* Constant transformation matrices. */
uniform mat4 cameraMatrix;
uniform mat4 projectionMatrix;
uniform mat4 scaleMatrix;

/* Coefficients of rotation needed for configuration of rotation matrix. */
uniform vec3 rotationVector;

void main()
{		
	mat4 modelViewMatrix;
	mat4 modelViewProjectionMatrix;
	
	/* Matrix rotating Model-View matrix around X axis. */
	mat4 xRotationMatrix = mat4(1.0,  0.0, 				  			  0.0, 	 						  0.0, 
							    0.0,  cos(radians(rotationVector.x)), sin(radians(rotationVector.x)), 0.0, 
							    0.0, -sin(radians(rotationVector.x)), cos(radians(rotationVector.x)), 0.0, 
							    0.0,  0.0, 			      			  0.0,   		  	    		  1.0);
	
	/* Matrix rotating Model-View matrix around Y axis. */	
	mat4 yRotationMatrix = mat4( cos(radians(rotationVector.y)), 0.0,	-sin(radians(rotationVector.y)), 0.0, 
							     0.0, 							 1.0, 	 0.0, 							 0.0, 
							     sin(radians(rotationVector.y)), 0.0, 	 cos(radians(rotationVector.y)), 0.0, 
							     0.0,			    			 0.0, 	 0.0, 			    			 1.0);
	
	/* Matrix rotating Model-View matrix around Z axis. */
	mat4 zRotationMatrix = mat4( cos(radians(rotationVector.z)), sin(radians(rotationVector.z)), 0.0, 0.0, 
							    -sin(radians(rotationVector.z)), cos(radians(rotationVector.z)), 0.0, 0.0, 
							     0.0, 						  	 0.0,    			  			 1.0, 0.0, 
							     0.0,			    		  	 0.0,    		      			 0.0, 1.0);
	
	/* Model-View matrix trasnformations. */
	modelViewMatrix = scaleMatrix;
	modelViewMatrix = xRotationMatrix  * modelViewMatrix;
	modelViewMatrix = yRotationMatrix  * modelViewMatrix;
	modelViewMatrix = zRotationMatrix  * modelViewMatrix;
	modelViewMatrix = cameraMatrix     * modelViewMatrix;
	
	/* Configure Model-View-ProjectionMatrix. */
	modelViewProjectionMatrix = projectionMatrix * modelViewMatrix;
	
	/* Set vertex posisiton in Model-View-Projection space. */
	gl_Position = modelViewProjectionMatrix * position;
}