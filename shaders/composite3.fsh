#version 120

#include "./settings.glsl"

uniform float frameTimeCounter;
uniform sampler2D colortex1;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

varying vec2 texcoord;



void main() {
	vec4 color = texture2D(colortex1, texcoord);
	vec3 ground_color = texture2D(colortex0, texcoord).rgb;


	color.rgb = texture2D(depthtex0, texcoord).r < 1.0 ? ground_color : color.rgb;

	

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color.rgb, 1.0); //gcolor
}