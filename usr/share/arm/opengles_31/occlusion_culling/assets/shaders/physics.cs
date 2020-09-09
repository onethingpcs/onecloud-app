#version 310 es

/*
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 *     ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */

// Not a very interesting shader.
// It's purpose is to move the spheres around a bit to see how Hi-Z works on more dynamic objects.

precision highp float;
precision highp int;

layout(local_size_x = 128) in;
layout(location = 0) uniform uint uNumBoundingBoxes;
layout(location = 1) uniform float uDeltaTime;

struct SphereInstance
{
    vec4 position;
    vec4 velocity;
};

layout(std430, binding = 0) buffer SphereInstances
{
    SphereInstance instance[];
} spheres;

#define RANGE 20.0
#define RANGE_Y 10.0
// Super basic collision against some arbitrary walls.
void compute_collision(inout vec3 pos, float radius, inout vec3 velocity)
{
    vec3 dist = pos - vec3(0.0, 2.0, 0.0);
    float dist_sqr = dot(dist, dist);
    float minimum_distance = 2.0 + radius;
    if (dist_sqr < minimum_distance * minimum_distance)
    {
        if (dot(dist, velocity) < 0.0) // Sphere is heading towards us, "reflect" it away.
            velocity = reflect(velocity, normalize(dist));
    }
    else
    {
        // If we collide against our invisible walls, reflect the velocity.
        if (pos.x - radius < -RANGE)
            velocity.x = abs(velocity.x);
        else if (pos.x + radius > RANGE)
            velocity.x = -abs(velocity.x);

        if (pos.y - radius < 0.0)
            velocity.y = abs(velocity.y);
        else if (pos.y + radius > RANGE_Y)
            velocity.y = -abs(velocity.y);

        if (pos.z - radius < -RANGE)
            velocity.z = abs(velocity.z);
        else if (pos.z + radius > RANGE)
            velocity.z = -abs(velocity.z);
    }
}

void main()
{
    uint ident = gl_GlobalInvocationID.x;
    if (ident >= uNumBoundingBoxes)
        return;

    // Load instance data.
    // position.w is sphere radius.
    SphereInstance sphere = spheres.instance[ident];

    // Move the sphere.
    sphere.position.xyz += sphere.velocity.xyz * uDeltaTime;

    // Test collision.
    compute_collision(sphere.position.xyz, sphere.position.w, sphere.velocity.xyz);

    // Write back result.
    spheres.instance[ident] = sphere;
}

