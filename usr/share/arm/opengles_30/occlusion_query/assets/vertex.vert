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

/* Vertex and normal vector attributes sent from the program. */
in vec4 vertex;
in vec3 normal;

/* Vector that stores the cubes' center location. */
uniform vec3 cubesLocations;

/* This matrix is used to set the perspective up and is sent from the program. */
uniform mat4 projectionMatrix;

/* This matrix is used to set the view up and is sent from the program. */
uniform mat4 viewMatrix;

/*
 * Determines if we want to draw a plane or a cube. 
 * If we want to draw a plane this value is 1, otherwise it's 0.
 */
uniform bool renderPlane;

/* Output color. */
out vec4 color;

/* Output normal vector (used to compute light). */
out vec3 normalOut;

/* Vertex position in world space that we pass to fragment shader. */
out vec4 modelPosition;

/* Inverted model-view-projection matrix passed to the fragment shader to compute light. */
out mat4 worldInverse;

void main()
{
	/* Vector that will be used to translate cubes and plane. */
	vec3 location;

	if(renderPlane) 
	{
		/* Set plane's color. */
		color = vec4(1.0, 0.8, 0.0, 1.0);

		/* Set plane's location (translation vector). */
		location = vec3(0.0);
	}
	else
	{	
        /* Set cube's color. */
		color = vec4(0.0, 0.75, 0.0, 1.0);

		/* Set cube's center position (translation vector). */
		location = cubesLocations;
	}

	/* Set up translation matrix. */
	mat4 translationMatrix 	= mat4(1.0,	       0.0,    	   0.0,		   0.0, 
								   0.0,	       1.0,    	   0.0,		   0.0, 
								   0.0,	       0.0,    	   1.0,		   0.0, 
								   location.x, location.y, location.z, 1.0);

	/* Model matrix. */
	mat4 modelMatrix = translationMatrix;

	/* Create normal matrix and temporary object's position vector. */
	mat4 normalMatrix = transpose(inverse(modelMatrix));

	/* Model-View-Projection matrix. */
	mat4 mvpMatrix = projectionMatrix * viewMatrix * modelMatrix;
	
	gl_Position = mvpMatrix * vertex;	
	
	/* Inverted mvp matrix (used to calculate light). */
	worldInverse = inverse(mvpMatrix);

	/* Calculate normal vector in world space (used to calculate light). */
	normalOut = vec3(normalMatrix * vec4(normal, 0.0));
}