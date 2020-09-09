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

/* [Enable pixel local storage in gbuffer pass] */
#extension GL_EXT_shader_pixel_local_storage : require
/* [Enable pixel local storage in gbuffer pass] */

/* GBuffer generation pass fragment shader */

precision highp float;

/* [Declare gbuf as a pixel local storage] */
__pixel_local_outEXT FragData
{
    layout(rgba8) highp vec4 Color;
    layout(rg16f) highp vec2 NormalXY;
    layout(rg16f) highp vec2 NormalZ_LightingB;
    layout(rg16f) highp vec2 LightingRG;
} gbuf;
/* [Declare gbuf as a pixel local storage] */

in highp vec3 vColor;
in highp vec3 vNormal;

void main(void)
{
    /* [Initialize gbuf] */
    /* Store primitive color. */
    gbuf.Color                = vec4(vColor, 0.0);

    /* Store normal vector. */
    gbuf.NormalXY             = vNormal.xy;
    gbuf.NormalZ_LightingB[0] = vNormal.z;

    /* Reserve and set lighting to 0. */
    gbuf.LightingRG           = vec2(0.0);
    gbuf.NormalZ_LightingB[1] = 0.0;
    /* [Initialize gbuf] */
}
