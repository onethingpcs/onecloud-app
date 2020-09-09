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

/* Shading pass fragment shader */

/* [Enable extensions] */
#extension GL_EXT_shader_pixel_local_storage : require
#extension GL_ARM_shader_framebuffer_fetch_depth_stencil : require
/* [Enable extensions] */

precision highp float;

/* [Declare gbuf accessible to read and write] */
__pixel_localEXT FragData
/* [Declare gbuf accessible to read and write] */
{
    layout(rgba8) highp vec4 Color;
    layout(rg16f) highp vec2 NormalXY;
    layout(rg16f) highp vec2 NormalZ_LightingB;
    layout(rg16f) highp vec2 LightingRG;
} gbuf;

uniform vec2  uInvViewport;
uniform mat4  uInvViewProj;
uniform vec3  uLightPos;
uniform vec3  uLightColor;
uniform float uLightRadius;

void main(void)
{
    vec4 ClipCoord;

    /* [Calculate clip coordinates] */
    ClipCoord.xy               = gl_FragCoord.xy * uInvViewport;
    ClipCoord.z                = gl_LastFragDepthARM;
    ClipCoord.w                = 1.0;
    ClipCoord                  = ClipCoord * 2.0 - 1.0;
    /* [Calculate clip coordinates] */

    /* [Transform to world space] */
    vec4 worldPosition         = uInvViewProj * ClipCoord;
    worldPosition             /= worldPosition.w;
    /* [Transform to world space] */

    /* [Calculate light vector] */
    vec3 lightVector           = uLightPos - worldPosition.xyz;
    float lightVectorLength    = length(lightVector);
    lightVector               /= lightVectorLength;
    /* [Calculate light vector] */

    /* [Unpack normal vector from pixel local storage] */
    vec3 normalVector          = vec3(gbuf.NormalXY, gbuf.NormalZ_LightingB[0]);
    /* [Unpack normal vector from pixel local storage] */

    /* [Compute light attenuation factor] */
    float lightAttenuation     = clamp(1.0 - lightVectorLength / uLightRadius, 0.0, 1.0);
    float normalDotLightVector = clamp(dot(lightVector, normalVector), 0.0, 1.0);
    /* [Compute light attenuation factor] */

    /* [Add light value to pixel local storage light accumulator] */
    vec3 texelLighting         = vec3(gbuf.LightingRG, gbuf.NormalZ_LightingB[1]);
    texelLighting             += uLightColor * normalDotLightVector * lightAttenuation;
    gbuf.LightingRG            = texelLighting.rg;
    gbuf.NormalZ_LightingB[1]  = texelLighting.b;
    /* [Add light value to pixel local storage light accumulator] */
}
