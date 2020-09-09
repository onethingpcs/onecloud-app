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

/* Combination pass vertex shader */

void main(void)
{
    /* [Render full screen quad] */
    switch(gl_VertexID)
    {
        case 0: gl_Position = vec4( 1.0,  1.0, -1.0, 1.0); break;
        case 1: gl_Position = vec4(-1.0,  1.0, -1.0, 1.0); break;
        case 2: gl_Position = vec4( 1.0, -1.0, -1.0, 1.0); break;
        case 3: gl_Position = vec4(-1.0, -1.0, -1.0, 1.0); break;
    }
    /* [Render full screen quad] */
}
