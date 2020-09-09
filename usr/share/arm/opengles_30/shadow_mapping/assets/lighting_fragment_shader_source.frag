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
precision lowp sampler2DShadow;

in vec4 outputLightPosition; 	   /* Vector of the spot light position translated into eye-space. */
in vec3 outputNormal;              /* Normal vector for the coordinates. */
in vec4 outputPosition;            /* Vertex coordinates expressed in eye space. */
in mat4 outputViewToTextureMatrix; /* Matrix we will use in the fragment shader to sample the shadow map for given fragment. */

uniform vec4 		    colorOfGeometry; /* Color of the geometry. */
uniform vec3  			lightDirection;  /* Normalized direction vector for the spot light. */
uniform sampler2DShadow shadowMap; 		 /* Sampler of the depth texture used for shadow-mapping. */

out vec4 color; /* Output color variable. */

#define PI 3.14159265358979323846

/* Structure holding properties of the directional light. */
struct DirectionalLight
{
	float ambient;   /* Value of ambient intensity for directional lighting of a scene. */
	vec3  color;     /* Color of the directional light. */ 
	vec3  direction; /* Direction for the directional light. */ 
};

/* Structure holding properties of spot light. */
struct SpotLight
{
	float ambient; 				/* Value of ambient intensity for spot lighting. */
	float angle;				/* Angle between spot light direction and cone face. */
	float spotExponent; 		/* Value indicating intensity distribution of light. */
	float constantAttenuation;  /* Value of light's attenuation. */
	float linearAttenuation; 	/* Value of linear light's attenuation. */
	float quadraticAttenuation; /* Value of quadratic light's attenuation. */
	vec3  direction;			/* Vector of direction of spot light. */
	vec4  position;				/* Coordinates of position of spot light source. */	
};

void main()
{
	DirectionalLight directionalLight;
	
	directionalLight.ambient   = 0.01; 
	directionalLight.color     = vec3(1.0,  1.0,  1.0);
	directionalLight.direction = vec3(0.2, -1.0, -0.2);

	SpotLight spotLight;

	spotLight.ambient              = 0.1;
	spotLight.angle 			   = 30.0;
	spotLight.spotExponent         = 2.0;
	spotLight.constantAttenuation  = 1.0;
	spotLight.linearAttenuation    = 0.1;
	spotLight.quadraticAttenuation = 0.9;
	spotLight.direction            = lightDirection; 
	spotLight.position             = outputLightPosition;

	/* Compute distance between the light position and the fragment position. */
	float xDistanceFromLightToVertex = (spotLight.position.x - outputPosition.x);
	float yDistanceFromLightToVertex = (spotLight.position.y - outputPosition.y);
	float zDistanceFromLightToVertex = (spotLight.position.z - outputPosition.z);
	float distanceFromLightToVertex  = sqrt((xDistanceFromLightToVertex * xDistanceFromLightToVertex) +
											(yDistanceFromLightToVertex * yDistanceFromLightToVertex) +
											(zDistanceFromLightToVertex * zDistanceFromLightToVertex));
	/* Directional light. */
	/* Calculate the value of diffuse intensity. */
	float diffuseIntensity = max(0.0, -dot(outputNormal, normalize(directionalLight.direction)));

    /* Calculate color for directional lighting. */
    color = colorOfGeometry * vec4(directionalLight.color * (directionalLight.ambient + diffuseIntensity), 1.0);
	
	/* Spot light. */
	/* Compute the dot product between normal and light direction. */
	float normalDotLight = max(dot(normalize(outputNormal), normalize(-spotLight.direction)), 0.0);
	
	/* Shadow. */
	/* Position of the vertex translated to texture space. */
	vec4 vertexPositionInTexture = outputViewToTextureMatrix * outputPosition;
	/* Normalized position of the vertex translated to texture space. */	
	vec4 normalizedVertexPositionInTexture = vec4(vertexPositionInTexture.x / vertexPositionInTexture.w, 
							                      vertexPositionInTexture.y / vertexPositionInTexture.w, 
							                      vertexPositionInTexture.z / vertexPositionInTexture.w,
							                      1.0);

	/* Depth value retrieved from the shadow map. */
	float shadowMapDepth = textureProj(shadowMap, normalizedVertexPositionInTexture);
	/* Depth value retrieved from drawn model. */
	float modelDepth = normalizedVertexPositionInTexture.z;
	
	/* Calculate vector from position of light to position of fragment. */
	vec3 vectorFromLightToFragment = vec3(outputPosition.x - spotLight.position.x, 
										  outputPosition.y - spotLight.position.y, 
										  outputPosition.z - spotLight.position.z);
										  
	/* Calculate cosinus value of angle between vectorFromLightToFragment and vector of spot light direction. */
	float cosinusAlpha = dot(spotLight.direction, vectorFromLightToFragment) /
                             (sqrt(dot(spotLight.direction, spotLight.direction)) * 
						      sqrt(dot(vectorFromLightToFragment, vectorFromLightToFragment)));
	/* Calculate angle for cosinus value. */					  
	float alpha = acos(cosinusAlpha);

	/* 
     * Check angles. If alpha is less than spotLight.angle then the fragment is inside light cone. 
	 * Otherwise the fragment is outside the cone - it is not lit by spot light. 
	 */
	const float shadowMapBias = 0.00001;
	 
	if (alpha < spotLight.angle)
	{
		if (modelDepth < shadowMapDepth + shadowMapBias)
		{
			float spotEffect = dot(normalize(spotLight.direction), normalize(vectorFromLightToFragment));
			
			spotEffect = pow(spotEffect, spotLight.spotExponent);
			
			/* Calculate total value of light's attenuation. */
			float attenuation = spotEffect / 
								(spotLight.constantAttenuation  +
								 spotLight.linearAttenuation    * distanceFromLightToVertex +
								 spotLight.quadraticAttenuation * distanceFromLightToVertex * distanceFromLightToVertex);
	
			/*
             * Calculate color for spot lighting. 
             * Scale the colour by 0.5 to make the shadows more obvious.
             */	
			color = color / 0.5 + (attenuation * (normalDotLight + spotLight.ambient));
		}
	}

    /* Angle (in radians) between the surfaces normal and the light direction. */
    float angle = acos(dot(normalize(outputNormal), normalize(spotLight.direction)));

    /* 
     * Reduce the intensitiy of the colour if the object is facing away from the light. 
     * scaleIntensity is 1 when the light is facing the surface, 0 when its facing the opposite direction.
     */
    float scaleIntensity = smoothstep(0.0, PI, angle);
    vec4 scaleVector = vec4(scaleIntensity, scaleIntensity, scaleIntensity, 1.0);
    color *= scaleVector;
}