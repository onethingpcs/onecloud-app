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

uniform vec3 uObjectColor;
in vec4 vPosition;
in vec3 vNormal;

layout(location = 0) out vec4 outNormalXY;
layout(location = 1) out vec4 outColorRGBNormalSign;
layout(location = 2) out vec4 outDepth32;

vec2 packFloat2x8(float v)
{
	v = floor(v * 65535.0) / 65536.0; // round to nearest discrete value
	float x = fract(v * 256.0) - fract(v * 256.0 * 256.0) / 256.0;
	float y = fract(v) - fract(v * 256.0) / 256.0;
	return vec2(x, y);
}

// http://stackoverflow.com/questions/9882716/packing-float-into-vec4-how-does-this-code-work
vec4 packFloat4x8(float v)
{
	const vec4 bit_shift = vec4(256.0*256.0*256.0, 256.0*256.0, 256.0, 1.0);
	const vec4 bit_mask  = vec4(0.0, 1.0/256.0, 1.0/256.0, 1.0/256.0);
	vec4 res = fract(v * bit_shift);
	res -= res.xxyz * bit_mask;
	return res;
}

void main()
{
	vec3 N = normalize(vNormal);

	// Pack data into textures
	outNormalXY.rg = packFloat2x8(0.5 + 0.5 * N.x);
	outNormalXY.ba = packFloat2x8(0.5 + 0.5 * N.y);
	outColorRGBNormalSign.a = sign(N.z);
	outColorRGBNormalSign.rgb = uObjectColor.rgb;
	outDepth32.rgba = packFloat4x8(0.5 + 0.5 * vPosition.z / vPosition.w);
}