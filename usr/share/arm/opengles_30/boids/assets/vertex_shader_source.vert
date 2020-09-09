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
 
const int numberOfSpheres = 30;
const float pi = 3.14159265358979323846;

in      vec4 attributePosition;
in      vec4 attributeColor;
out     vec4 vertexColor;
uniform vec4 perspectiveVector;
uniform vec3 scalingVector;
uniform vec3 cameraVector;

/* 
 * We use uniform block in order to reduce amount of memory transfers to minimum. 
 * The uniform block uses data taken directly from a buffer object. 
 */
uniform BoidsUniformBlock
{
    vec4 sphereLocation[numberOfSpheres];
};

void main()
{
    float fieldOfAngle     = 1.0 / tan(perspectiveVector.x * 0.5);
    vec3  locationOfSphere = vec3 (sphereLocation[gl_InstanceID].x, sphereLocation[gl_InstanceID].y, sphereLocation[gl_InstanceID].z);
    
    /* Set red color for leader and green color for followers. */
    if(gl_InstanceID == 0)
    {
        vertexColor = vec4(attributeColor.x, 0.5 * attributeColor.y, 0.5 * attributeColor.z, attributeColor.w);
    }
    else
    {
        vertexColor = vec4(0.5 * attributeColor.x, attributeColor.y, 0.5 * attributeColor.z, attributeColor.w);
    }
    
    /* Create transformation matrices. */
    mat4 translationMatrix = mat4(1.0,                 0.0,                   0.0,                 0.0, 
                                  0.0,                 1.0,                   0.0,                 0.0, 
                                  0.0,                 0.0,                   1.0,                 0.0, 
                                  locationOfSphere.x,  locationOfSphere.y,    locationOfSphere.z,  1.0);
                                  
    mat4 cameraMatrix      = mat4(1.0,                 0.0,                   0.0,                 0.0, 
                                  0.0,                 1.0,                   0.0,                 0.0, 
                                  0.0,                 0.0,                   1.0,                 0.0, 
                                  cameraVector.x,      cameraVector.y,        cameraVector.z,      1.0);
                                  
    mat4 scalingMatrix     = mat4(scalingVector.x,     0.0,                   0.0,                 0.0, 
                                  0.0,                 scalingVector.y,       0.0,                 0.0, 
                                  0.0,                 0.0,                   scalingVector.z,     0.0, 
                                  0.0,                 0.0,                   0.0,                 1.0);
                                  
    mat4 perspectiveMatrix = mat4(fieldOfAngle/perspectiveVector.y,  0.0,            0.0,                                                                                              0.0, 
                                  0.0,                               fieldOfAngle,   0.0,                                                                                              0.0, 
                                  0.0,                               0.0,            -(perspectiveVector.w + perspectiveVector.z) / (perspectiveVector.w - perspectiveVector.z),       -1.0, 
                                  0.0,                               0.0,            (-2.0 * perspectiveVector.w * perspectiveVector.z) / (perspectiveVector.w - perspectiveVector.z), 0.0);
    /* Compute scaling. */
    mat4 tempMatrix = scalingMatrix;
    
    /* Compute translation. */
    tempMatrix      = translationMatrix * tempMatrix;
    tempMatrix      = cameraMatrix      * tempMatrix;
                
    /* Compute perspective. */
    tempMatrix      = perspectiveMatrix * tempMatrix;
                
    /* Return gl_Position. */
    gl_Position     = tempMatrix * attributePosition;
}

