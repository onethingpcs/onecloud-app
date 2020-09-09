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

/* Number of control points in one dimension for a patch.. */
const uint patchDimension = 4u;
/* Total number of control points in a patch. */
const uint controlPointsPerPatchCount = patchDimension * patchDimension;
/* Number of quads in a patch. */
const uint quadsInPatchCount = (patchDimension - 1u) * (patchDimension - 1u);
/* Total number of vertices in a patch. */
const uint verticesCount = 144u;

/* Input patch vertex coordinates. */
in vec2 patchUVPosition;

/* Constant transofrmation matrices. */
uniform mat4 cameraMatrix;
uniform mat4 projectionMatrix;
uniform mat4 scaleMatrix;

/* Coefficients of rotation needed for configuration of rotation matrix. */
uniform vec3 rotationVector;

/* Uniform block that stores control mesh indices. */
uniform ControlPointsIndices
{
	uint indices[controlPointsPerPatchCount * verticesCount / quadsInPatchCount];
};

/* Uniform block that stores control mesh vertices. */
uniform ControlPointsVertices
{
	vec4 vertices[verticesCount];
};

/* Normal vector set in Model-View-Projection space. */
out vec3 modelViewProjectionNormalVector;

void main()
{	
	const float pi = 3.14159265358979323846;

	mat4 modelViewMatrix;
	mat4 modelViewProjectionMatrix;
	
	/* Array storing control vertices of current patch. */
	vec4 controlVertices[controlPointsPerPatchCount];
	
	/* Initialize array of current control vertices. */
	for (uint i = 0u; i < controlPointsPerPatchCount; ++i)
	{
		controlVertices[i] = vertices[indices[uint(gl_InstanceID) * controlPointsPerPatchCount + i]];
	}
	
	/* Coefficients of Bernstein polynomials. */
	vec2 bernsteinUV0 = (1.0 - patchUVPosition) * (1.0 - patchUVPosition) * (1.0 - patchUVPosition);
	vec2 bernsteinUV1 =  3.0 * patchUVPosition  * (1.0 - patchUVPosition) * (1.0 - patchUVPosition);
	vec2 bernsteinUV2 =  3.0 * patchUVPosition  *        patchUVPosition  * (1.0 - patchUVPosition);
	vec2 bernsteinUV3 =        patchUVPosition  *        patchUVPosition  *        patchUVPosition ;
	
	/* Position of a patch vertex on Bezier surface. */
	vec3 position = bernsteinUV0.x * (bernsteinUV0.y * controlVertices[ 0].xyz + bernsteinUV1.y * controlVertices[ 1].xyz + bernsteinUV2.y * controlVertices[ 2].xyz + bernsteinUV3.y * controlVertices[ 3].xyz) +
					bernsteinUV1.x * (bernsteinUV0.y * controlVertices[ 4].xyz + bernsteinUV1.y * controlVertices[ 5].xyz + bernsteinUV2.y * controlVertices[ 6].xyz + bernsteinUV3.y * controlVertices[ 7].xyz) +
					bernsteinUV2.x * (bernsteinUV0.y * controlVertices[ 8].xyz + bernsteinUV1.y * controlVertices[ 9].xyz + bernsteinUV2.y * controlVertices[10].xyz + bernsteinUV3.y * controlVertices[11].xyz) +
					bernsteinUV3.x * (bernsteinUV0.y * controlVertices[12].xyz + bernsteinUV1.y * controlVertices[13].xyz + bernsteinUV2.y * controlVertices[14].xyz + bernsteinUV3.y * controlVertices[15].xyz);
	
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
	modelViewMatrix = xRotationMatrix * modelViewMatrix;
	modelViewMatrix = yRotationMatrix * modelViewMatrix;
	modelViewMatrix = zRotationMatrix * modelViewMatrix;
	modelViewMatrix = cameraMatrix    * modelViewMatrix;
	
	/* Configure Model-View-ProjectionMatrix. */
	modelViewProjectionMatrix = projectionMatrix * modelViewMatrix;
	
	/* Set vertex posisiton in Model-View-Projection space. */
	gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
		
	/* Angle on the "big circle" of torus. */
	float phi = (patchUVPosition.x + mod(float(gl_InstanceID), 4.0)) * pi / 2.0;
	
	/* Angle on the "small circle" of torus. */
	float theta = (patchUVPosition.y + mod(float(gl_InstanceID / 4), 4.0)) * pi / 2.0;
	
	/* Horizontal tangent to torus. */
	vec3 dBdu = vec3(-sin(phi), 0.0, cos(phi));
	/* Vertical tangent to torus. */
	vec3 dBdv = vec3(cos(phi) * (-sin(theta)), cos(theta), sin(phi) * (-sin(theta)));
	
	/* Calculate normal vector. */
	vec3 normalVector = normalize(cross(dBdu, dBdv));
	/* Calculate normal matrix. */
	mat3 normalMatrix = transpose(inverse(mat3x3(modelViewMatrix)));
	
	/* Transform normal vector to Model-View-Projection space. */
	modelViewProjectionNormalVector = normalize(normalMatrix * normalVector);
}