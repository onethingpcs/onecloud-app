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

float noise1f(int x)
{
    x = (x<<13) ^ x;
    return ( 1.0 - float((x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0);
}

float snoise(float x)
{
    int xi = int(floor(x));
    float xf = x - float(xi);

    float h0 = noise1f(xi);
    float h1 = noise1f(xi + 1);

    // Smoothly nterpolate between noise values
    float t = smoothstep(0.0, 1.0, xf);
    return h0 + (h1 - h0) * t;
}

layout (local_size_x = 8) in;

layout (std140, binding = 0) buffer SpawnBuffer {
    vec4 SpawnInfo[];
};

uniform vec3 emitterPos;
uniform float particleLifetime;
uniform float time;

void main()
{
    uint index = gl_GlobalInvocationID.x;
    
    vec3 p;

    // Random offset
    float seed = float(index) * 100.0 * time;
    p.x = snoise(seed);
    p.z = snoise(seed + 13.0);
    p.y = snoise(seed + 127.0);

    // Normalize to get sphere distribution
    p = (0.06 + 0.04 * snoise(seed + 491.0)) * normalize(p);

    // Particle respawns at emitter
    p += emitterPos;

    // New lifetime with slight variation
    float newLifetime = (1.0 + 0.25 * snoise(seed)) * particleLifetime;

    SpawnInfo[index] = vec4(p, newLifetime);
}
