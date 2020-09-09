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

out vec4 mask0;

uniform mat4 projection;
uniform mat4 view;
const float scale = 0.7;

void main()
{
    vec4 viewPos = view * vec4(position.xyz, 1.0);
    gl_Position = projection * viewPos;
    gl_PointSize = scale * (16.0 - 6.0 * (length(viewPos.xyz) - 1.0) / (3.0 - 1.0));

    float z = 0.5 + 0.5 * gl_Position.z;
    mask0 = clamp(floor( mod(vec4(z) + vec4(1.00, 0.75, 0.50, 0.25), vec4(1.25)) ), vec4(0.0), vec4(1.0));
}
