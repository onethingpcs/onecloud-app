#version 300 es

/*
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 *     ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

precision mediump float;

uniform sampler2D cloud_texture;
uniform sampler2D daytime_texture;
uniform sampler2D nighttime_texture;

in vec2 tex2dcoord;
in vec3 normal;
in vec3 light;
in vec3 view;

out vec4 color;

void main()
{
    /* Material properties. */
    vec3 diffuse_albedo  = vec3(2.0, 2.0, 3.0);
    vec3 specular_albedo = vec3(0.1);
    float specular_power = 16.0;

    /* Calculate normalized vectors for incomings. */
    vec3 Normal = normalize(normal);
    vec3 Light  = normalize(light);
    vec3 View   = normalize(view);

    /* Calculate the reflection direction. */
    vec3 reflected_light = reflect(-Light, Normal);

    /* Calculate diffuse and specular components. */
    vec3 diffuse = max(dot(Normal, Light), 0.0) * diffuse_albedo;
    vec3 specular = pow(max(dot(reflected_light, View), 0.0), specular_power) * specular_albedo;

    /* Read textures colors and combine daytime/nighttime textures colors with clouds layer and light. */
    vec2 clouds    = texture(cloud_texture,     tex2dcoord).rg;
    vec3 daytime   = (texture(daytime_texture,  tex2dcoord).rgb * diffuse + specular * clouds.g) * (1.0 - clouds.r) + clouds.r * diffuse;
    vec3 nighttime = texture(nighttime_texture, tex2dcoord).rgb * (1.0 - clouds.r) * 2.0;

    /* Compute final color and output it to the frame buffer. */
    color = vec4(mix(nighttime, daytime, 0.5), 1.0);
}