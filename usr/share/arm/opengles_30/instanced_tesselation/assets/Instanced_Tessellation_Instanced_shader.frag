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

precision mediump float;

/* Input normal vector. */
in vec3 modelViewProjectionNormalVector;

/* Structure storing directional light parameters. */
struct Light
{
	vec3  lightColor;
	vec3  lightDirection;
	float ambientIntensity;
};

/* Color of the drawn torus. */
uniform vec4  color;
/* Uniform representing light parameters. */
uniform Light light;

/* Output variable. */
out vec4 fragColor;

void main()
{
	/* Calculate the value of diffuse intensity. */
	float diffuseIntensity = max(0.0, -dot(modelViewProjectionNormalVector, normalize(light.lightDirection)));
	
	/* Calculate the output color value considering the light. */
	fragColor = color * vec4(light.lightColor * (light.ambientIntensity + diffuseIntensity), 1.0);
}