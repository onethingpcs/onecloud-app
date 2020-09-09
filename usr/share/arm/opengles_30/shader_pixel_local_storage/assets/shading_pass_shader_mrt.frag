#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

precision highp float;
precision highp sampler2D;

uniform vec3 uLightPos;
uniform float uLightRadius;
uniform vec3 uLightColor;
uniform mat4 uInvViewProj;
uniform vec2 uInvViewport;

uniform sampler2D uNormalXY;
uniform sampler2D uColorRGBNormalSign;
uniform sampler2D uDepth32;

out vec4 outColor;

float unpackFloat2x8(vec2 v)
{
    return v.y + v.x / 256.0;
}

float unpackFloat4x8(vec4 v)
{
	return v.w + v.z / 256.0 + v.y / (256.0 * 256.0) + v.x / (256.0 * 256.0 * 256.0);
}

void main()
{
    vec2 texel = gl_FragCoord.xy * uInvViewport;

    // Extract depth
    float depth = unpackFloat4x8(texture(uDepth32, texel));

    // Skip background
    //if (depth < 0.0001)
    //  discard;

    // Extract normal
    vec4 texNormalXY = texture(uNormalXY, texel);
    vec4 texColorRGBNormalSign = texture(uColorRGBNormalSign, texel);
    float Nx = -1.0 + 2.0 * unpackFloat2x8(texNormalXY.rg);
    float Ny = -1.0 + 2.0 * unpackFloat2x8(texNormalXY.ba);
    float Nz = texColorRGBNormalSign.a * sqrt(1.0 - Nx * Nx - Ny * Ny);
    vec3 N = vec3(Nx, Ny, Nz);

    // Compute world position
    vec4 ndc = vec4(-1.0) + 2.0 * vec4(texel, depth, 1.0);
    vec4 worldPos = uInvViewProj * ndc;
    worldPos /= worldPos.w;

    // Direction to light
    vec3 lightVector = uLightPos - worldPos.xyz;
    float lightVectorLength = length(lightVector);
    lightVector /= lightVectorLength;

    float lightAttenuation = clamp(1.0 - lightVectorLength / uLightRadius, 0.0, 1.0);
    float normalDotLightVector = clamp(dot(N, lightVector), 0.0, 1.0);

    vec3 diffuseColor = texColorRGBNormalSign.rgb;

    outColor.rgb = uLightColor * normalDotLightVector * lightAttenuation * diffuseColor;
    outColor.a = 1.0;

	//outColor.rgb *= 0.0001;
	//outColor.rgb += vec3(normalDotLightVector);

	//outColor.rgb *= 0.0001;
    //outColor.rgb += vec3(pow(ndc.x, 0.1));
}