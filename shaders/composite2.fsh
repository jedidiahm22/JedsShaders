#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

#include "./settings.glsl"


#if CLOUD_STYLE == 1
	#include "/lib/clouds1.glsl"
#endif

#if CLOUD_STYLE == 2
	#include "./lib/clouds2.glsl"
#endif