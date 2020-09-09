#version 300 es
/** 
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
precision highp float;
precision highp sampler2DShadow;

/* Value used in float values comparison. */
#define EPSILON 0.00001

/* INPUTS */
in vec3 normalInEyeSpace; /* Normal vector for the coordinates. */
in vec4 vertexInEyeSpace; /* Vertex coordinates expressed in eye space. */

/* UNIFORMS */
uniform sampler2D       colorTexture;                   /* Colour texture that will be projected onto the scene. */
uniform float           directionalLightAmbient;        /* Directional light ambient. */
uniform vec3            directionalLightColor;          /* Directional light colour. */
uniform vec3            directionalLightPosition;       /* Directional light position. */
uniform vec4            geometryColor;                  /* Current colour of a geometry to be rendered. */
uniform sampler2DShadow shadowMap;                      /* Sampler of the depth texture used for shadow-mapping. */
uniform vec4            spotLightColor;                 /* Spot light colour. */
uniform float           spotLightCosAngle;              /* Cosine of the spot light angle. */
uniform vec4            spotLightLookAtPointInEyeSpace; /* Point coordinates translated into eye-space which spot light is looking at. */
uniform vec4            spotLightPositionInEyeSpace;    /* Vector of position of spot light source translated into eye-space. */
uniform mat4            viewToColorTextureMatrix;       /* Matrix we will use in the fragment shader to sample the colour texture for given fragment. */
uniform mat4            viewToDepthTextureMatrix;       /* Matrix we will use in the fragment shader to sample the shadow map for given fragment. */

/* OUTPUTS */
out vec4 color; /* Output colour variable. */

/* [Calculate directional light] */
/** \brief Get the directional lighting factor.
 *
 *  \return As per description.
 */
vec4 calculateDirectionalLight()
{
    vec3  normalizedNormal         = normalize(normalInEyeSpace);
    vec3  normalizedLightDirection = normalize(directionalLightPosition - vertexInEyeSpace.xyz);
    vec4  result                   = vec4(directionalLightColor, 1.0) * max(dot(normalizedNormal, normalizedLightDirection), 0.0);

    return result * directionalLightAmbient;
}
/* [Calculate directional light] */

/* [Get fragment to light cos value] */
/** \brief Get cosine of the angle between the current fragment and spot light direction.
 *
 *  \return As per description.
 */
float getFragmentToLightCosValue()
{
    vec4  fragmentToLightdirection = normalize(vertexInEyeSpace - spotLightPositionInEyeSpace);
    vec4  spotLightDirection       = normalize(spotLightLookAtPointInEyeSpace- spotLightPositionInEyeSpace);
    float cosine                   = dot(spotLightDirection, fragmentToLightdirection);

    return cosine;
}
/* [Get fragment to light cos value] */

/* [Calculate projected texture] */
/** \brief Get projected texture colour sampled for a specific fragment.
 *
 *  \return As per description.
 */
vec4 calculateProjectedTexture()
{
    vec3 textureCoordinates           = (viewToColorTextureMatrix * vertexInEyeSpace).xyz;
    vec3 normalizedTextureCoordinates = normalize(textureCoordinates);
    vec4 textureColor                 = textureProj(colorTexture, normalizedTextureCoordinates);

    return textureColor;
}
/* [Calculate projected texture] */

/* [Calculate spot light] */
/** \brief Get the spot lighting factor.
 *  \note  Can be called only if a fragment is placed in the spot light cone.
 *
 *  \param fragmentToLightCosValue Cosine of the angle between the current fragment and spot light direction.
 *
 *  \return As per description.
 */
vec4 calculateSpotLight(float fragmentToLightCosValue)
{
    const float constantAttenuation  = 0.01;
    const float linearAttenuation    = 0.001;
    const float quadraticAttenuation = 0.0004;
    vec4        result               = vec4(0.0);

    /* Calculate the distance from a spot light source to fragment. */
    float distance             = distance(vertexInEyeSpace.xyz, spotLightPositionInEyeSpace.xyz);
    float factor               = clamp((fragmentToLightCosValue - spotLightCosAngle), 0.0, 1.0);
    float attenuation          = 1.0 / (constantAttenuation             +
                                        linearAttenuation    * distance +
                                        quadraticAttenuation * distance * distance);
    vec4 projectedTextureColor = calculateProjectedTexture();

    result = (spotLightColor * 0.5 + projectedTextureColor)* factor * attenuation;

    return result;
}
/* [Calculate spot light] */

void main()
{
    /* Calculate directional light. */
    vec4 directionalLighting = calculateDirectionalLight();
    /* Position of the vertex translated to texture space. */
    vec4 vertexPositionInTexture = viewToDepthTextureMatrix * vertexInEyeSpace;
    /* Normalized position of the vertex translated to texture space. */
    vec4 normalizedVertexPositionInTexture = normalize(vertexPositionInTexture);
    /* [Get shadow map depth value] */
    /* Depth value retrieved from the shadow map. */
    float shadowMapDepth = textureProj(shadowMap, normalizedVertexPositionInTexture);
    /* [Get shadow map depth value] */
    /* [Get model depth value] */
    /* Depth value retrieved from drawn model. */
    float modelDepth = normalizedVertexPositionInTexture.z;
    /* [Get model depth value] */
    /* Calculate cosine of the angle between current fragment and the light direction. */
    float fragmentToLightCosValue = getFragmentToLightCosValue();

    /* Calculate colour of a geometry lit by directional light. */
    color = geometryColor * directionalLighting;

    /* [Project texture on a fragment if needed] */
    /* Apply spot lighting and shadowing if needed). */
    if ((fragmentToLightCosValue > spotLightCosAngle) && /* If fragment is in spot light cone. */
         modelDepth < shadowMapDepth + EPSILON)
    {
        vec4 spotLighting = calculateSpotLight(fragmentToLightCosValue);  

        color += spotLighting;
    }
    /* [Project texture on a fragment if needed] */
}