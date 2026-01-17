#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

#include "./settings.glsl"


uniform float frameTimeCounter;
uniform sampler2D gcolor;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

varying vec2 texcoord;

vec3 make_green(in vec3 color, in float amount) {
	vec3 temp = mix(color, vec3(0.,1.,0.), amount);
	return temp;
}

vec3 make_blue(in vec3 color, in float amount) {
	vec3 temp = mix(color, vec3(0.,0.,1.), amount);
	return temp;
}

vec3 make_red(in vec3 color, in float amount) {
	vec3 temp = mix(color, vec3(1.,0.,0.), amount);
	return temp;
}

void main() {
	vec3 color = texture2D(DRAW_SHADOW_MAP, texcoord).rgb;

	float blue_amount = 0.5;
	
	float avg_val = (color.x + color.y + color.z) / 3.0;

	vec3 red_tex = make_red(color, JedSliderRed);
	vec3 green_tex = make_green(color, JedSliderGreen);
	vec3 blue_tex = make_blue(color, JedSliderBlue);

	vec3 rgmix = mix(red_tex, green_tex, 0.33);
	vec3 rgbmix = mix(rgmix, blue_tex, 0.33);
	
	vec3 gray_scale = vec3(avg_val);

	color = mix(color, rgbmix, 0.33);

	color = mix(color, gray_scale, Gray_Amount);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color.xyz, 1.0); //gcolor
}