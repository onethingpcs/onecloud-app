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

/* Number of cubes to be drawn. */ 
#define numberOfCubes 2

in vec4 attributePosition; /* Attribute: holding coordinates of triangles that make up a geometry. */
in vec3 attributeNormals;  /* Attribute: holding normals. */

uniform mat4 cameraProjectionMatrix; /* Projection matrix from camera point of view. */
uniform mat4 lightProjectionMatrix;  /* Projection matrix from light  point of view. */

uniform mat4 lightViewMatrix; /* View matrix from light point of view. */
uniform vec3 cameraPosition;  /* Camera position which we use to calculate view matrix for final pass. */

uniform vec3 lightPosition; /* Vector of position of spot light source. */

uniform bool isCameraPointOfView; /* If true: perform calculations from camera point of view, else: from light point of view. */
uniform bool shouldRenderPlane;	  /* If true: draw plane, else: draw cubes. */

uniform vec3 planePosition; /* Position of plane used to calculate translation matrix for a plane. */

/* Uniform block holding data used for rendering cubes (position of cubes) - used to calculate translation matrix for each cube in world space. */
uniform cubesDataUniformBlock
{
	vec4 cubesPosition[numberOfCubes];
};

out vec4 outputLightPosition; 	    /* Output variable: vector of position of spot light source translated into eye-space. */
out vec3 outputNormal;              /* Output variable: normal vector for the coordinates. */
out vec4 outputPosition;            /* Output variable: vertex coordinates expressed in eye space. */
out mat4 outputViewToTextureMatrix; /* Output variable: matrix we will use in the fragment shader to sample the shadow map for given fragment. */

void main()
{
	/* View matrix calculated from camera point of view. */
	mat4 cameraViewMatrix;
	
	/* Matrices and vectors used for calculating output variables. */
	vec3 modelPosition;
	mat4 modelViewMatrix;
	mat4 modelViewProjectionMatrix;
	
	/* Model consists of plane and cubes (each of them has different color and position). */
	if (shouldRenderPlane)
	{
		modelPosition = planePosition;
	}
	else
	{
		modelPosition = vec3(cubesPosition[gl_InstanceID].x, cubesPosition[gl_InstanceID].y, cubesPosition[gl_InstanceID].z);
	}

	/* Create transformation matrix (translation of a model). */
	mat4 translationMatrix = mat4 (1.0, 	        0.0,             0.0,             0.0, 
							       0.0, 	        1.0,             0.0,             0.0, 
							       0.0, 	        0.0,             1.0,             0.0, 
							       modelPosition.x, modelPosition.y, modelPosition.z, 1.0);
	
	/* Compute matices for camera point of view. */	
	if (isCameraPointOfView == true)
	{
		cameraViewMatrix = mat4 ( 1.0, 		          0.0,               0.0,              0.0, 
								  0.0, 		          1.0,               0.0,              0.0, 
								  0.0, 		          0.0,               1.0,              0.0, 
								 -cameraPosition.x,  -cameraPosition.y, -cameraPosition.z, 1.0);
											
		/* Compute model-view matrix. */
		modelViewMatrix = cameraViewMatrix * translationMatrix;
		/* Compute  model-view-perspective matrix. */
		modelViewProjectionMatrix = cameraProjectionMatrix * modelViewMatrix;

	}
	/* Compute matrices for light point of view. */
	else
	{
		/* Compute model-view matrix. */
		modelViewMatrix = lightViewMatrix * translationMatrix;
		/* Compute model-view-perspective matrix. */
		modelViewProjectionMatrix = lightProjectionMatrix * modelViewMatrix;
	}
	
	/* Bias matrix used to map values from a range <-1, 1> (eye space coordinates) to <0, 1> (texture coordinates). */
	const mat4 biasMatrix = mat4(0.5, 0.0, 0.0, 0.0,
						         0.0, 0.5, 0.0, 0.0,
						         0.0, 0.0, 0.5, 0.0,
						         0.5, 0.5, 0.5, 1.0);
						   
	/* Calculate normal matrix. */
	mat3 normalMatrix = transpose(inverse(mat3x3(modelViewMatrix)));
	
	/* Calculate and set output vectors. */
	outputLightPosition = modelViewMatrix * vec4(lightPosition, 1.0);
	outputNormal        = normalMatrix    * attributeNormals;
	outputPosition      = modelViewMatrix * attributePosition;

	if (isCameraPointOfView)
	{
		outputViewToTextureMatrix = biasMatrix * lightProjectionMatrix * lightViewMatrix * inverse(cameraViewMatrix);
	}
	
	/* Multiply model-space coordinates by model-view-projection matrix to bring them into eye-space. */
	gl_Position = modelViewProjectionMatrix * attributePosition;
}