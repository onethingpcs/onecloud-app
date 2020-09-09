#version 310 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 *     ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */ 

in vec4 position;

out float lifetime;
out vec3 color;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 projectionViewLight;
uniform vec3 smokeColor;
uniform vec3 smokeShadow;
uniform sampler2D shadowMap0;

const float scale = 0.85;

void main()
{
    vec4 viewPos = view * vec4(position.xyz, 1.0);
    float viewDist = length(viewPos.xyz);
    gl_PointSize = scale * (20.0 - 6.0 * (viewDist - 1.0) / (3.0 - 1.0));
    lifetime = position.w;
    gl_Position = projection * viewPos;

    // Project particle position onto lightmap
    vec4 lightPos = projectionViewLight * vec4(position.xyz, 1.0);
    vec3 shadowTexel = vec3(0.5) + 0.5 * lightPos.xyz;
    vec4 shadow0 = texture(shadowMap0, shadowTexel.xy);

    // Mask out shadow layers that are ahead of the particle's own layer
    // and linearly interpolate between them based on its depth
    vec4 mask0 = clamp( (vec4(shadowTexel.z) - vec4(0.00, 0.25, 0.50, 0.75)) * 4.0, vec4(0.0), vec4(1.0));
    shadow0 *= mask0;

    // Sum up the components weighted by the mask
    float shadow = shadow0.x + shadow0.y + shadow0.z + shadow0.w;
    shadow = clamp(shadow, 0.0, 1.0);

    color = smokeColor * (1.0 - shadow) + shadow * smokeShadow;
}
