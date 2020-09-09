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

/* Combination pass fragment shader */

#extension GL_EXT_shader_pixel_local_storage : require

precision highp float;

/* [Declare gbuf available to read] */
__pixel_local_inEXT FragData
/* [Declare gbuf available to read] */
{
    layout(rgba8) highp vec4 Color;
    layout(rg16f) highp vec2 NormalXY;
    layout(rg16f) highp vec2 NormalZ_LightingB;
    layout(rg16f) highp vec2 LightingRG;
} gbuf;

/* Declare fragment shader output.
 * Writing to it effectively clears the contents of
 * the pixel local shader storage.
 */
out vec4 fragColor;

void main(void)
{
    /* [Read diffuse and lighting values from pixel local gbuf storage] */
    vec3 diffuseColor  = gbuf.Color.xyz;
    vec3 texelLighting = vec3(gbuf.LightingRG, gbuf.NormalZ_LightingB[1]);
    /* [Read diffuse and lighting values from pixel local gbuf storage] */

    /* [Write the contents to fragColor] */
    /* This will effectively write the color data to the native framebuffer
     * format of the currently attached color attachment.
     */
    fragColor          = vec4(diffuseColor * texelLighting, 1.0);
    /* [Write the contents to fragColor] */
}
