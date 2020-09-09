#version 300 es

/*
 * This proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2012 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
 
const int numberOfCubes = 10;
const float pi = 3.14159265358979323846;
const float radius = 20.0;

in      vec4 attributeColor;
in      vec4 attributePosition;
out     vec4 vertexColor;
uniform vec3 cameraVector;
uniform vec4 perspectiveVector;

uniform float time; /* Time value used for determining positions and rotations. */

/*
 * We use uniform block in order to reduce amount of memory transfers to minimum. 
 * The uniform block uses data taken directly from a buffer object. 
 */
uniform CubesUniformBlock
{
    float startPosition[numberOfCubes];
    vec4  cubeColor[numberOfCubes];
};

void main()
{
    float fieldOfView = 1.0 / tan(perspectiveVector.x * 0.5);
    
    /* Vector data used for translation of cubes (each cube is placed on and moving around a circular curve). */
    vec3 locationOfCube = vec3(radius * cos(startPosition[gl_InstanceID] + (time/3.0)),
                               radius * sin(startPosition[gl_InstanceID] + (time/3.0)),
                               1.0);

    /* 
     * Vector data used for setting rotation of cube. Each cube has different speed of rotation,
     * first cube has the slowest rotation, the last one has the fastest. 
     */
    vec3 rotationOfube = vec3 (float(gl_InstanceID + 1) * 5.0 * time);
    
    /* 
     * Set different random colors for each cube. 
     * There is one color passed in per cube set for each cube (cubeColor[gl_InstanceID]).
     * There are also different colors per vertex of a cube (attributeColor).
     */
    vertexColor = attributeColor * cubeColor[gl_InstanceID];
    
    /* Create transformation matrices. */
    mat4 translationMatrix = mat4 (1.0,             0.0,             0.0,             0.0, 
                                   0.0,             1.0,             0.0,             0.0, 
                                   0.0,             0.0,             1.0,             0.0, 
                                   locationOfCube.x, locationOfCube.y, locationOfCube.z, 1.0);
                                  
    mat4 cameraMatrix = mat4 (1.0,           0.0,           0.0,           0.0, 
                              0.0,              1.0,           0.0,           0.0, 
                              0.0,           0.0,           1.0,           0.0, 
                              cameraVector.x, cameraVector.y, cameraVector.z, 1.0);
    
    mat4 xRotationMatrix = mat4 (1.0,  0.0,                               0.0,                                0.0, 
                                 0.0,  cos(pi * rotationOfube.x / 180.0), sin(pi * rotationOfube.x / 180.0),  0.0, 
                                 0.0, -sin(pi * rotationOfube.x / 180.0), cos(pi * rotationOfube.x / 180.0),  0.0, 
                                 0.0,  0.0,                               0.0,                                1.0);
                                
    mat4 yRotationMatrix = mat4 (cos(pi * rotationOfube.y / 180.0), 0.0, -sin(pi * rotationOfube.y / 180.0), 0.0, 
                                 0.0,                               1.0, 0.0,                                0.0, 
                                 sin(pi * rotationOfube.y / 180.0), 0.0, cos(pi * rotationOfube.y / 180.0),  0.0, 
                                 0.0,                               0.0, 0.0,                                1.0);
                                
    mat4 zRotationMatrix = mat4 ( cos(pi * rotationOfube.z / 180.0), sin(pi * rotationOfube.z / 180.0), 0.0, 0.0, 
                                 -sin(pi * rotationOfube.z / 180.0), cos(pi * rotationOfube.z / 180.0), 0.0, 0.0, 
                                  0.0,                               0.0,                               1.0, 0.0, 
                                  0.0,                               0.0,                               0.0, 1.0);
                                 
    mat4 perspectiveMatrix = mat4 (fieldOfView/perspectiveVector.y, 0.0,        0.0,                                                                                              0.0, 
                                   0.0,                            fieldOfView, 0.0,                                                                                              0.0, 
                                   0.0,                            0.0,        -(perspectiveVector.w + perspectiveVector.z) / (perspectiveVector.w - perspectiveVector.z),        -1.0, 
                                   0.0,                            0.0,        (-2.0 * perspectiveVector.w * perspectiveVector.z) / (perspectiveVector.w - perspectiveVector.z), 0.0);

    /* Compute rotation. */
    mat4 tempMatrix = xRotationMatrix;
    
    tempMatrix = yRotationMatrix * tempMatrix;
    tempMatrix = zRotationMatrix * tempMatrix;
    
    /* Compute translation. */
    tempMatrix = translationMatrix * tempMatrix;
    tempMatrix = cameraMatrix      * tempMatrix;
                
    /* Compute perspective. */
    tempMatrix = perspectiveMatrix * tempMatrix;
                
    /* Return gl_Position. */
    gl_Position = tempMatrix * attributePosition;
}