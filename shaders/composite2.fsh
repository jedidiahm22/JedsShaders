#version 120

#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]

#include "./settings.glsl"


uniform float frameTimeCounter;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;

varying vec2 texcoord;

float random(in vec2 p) 
{
	return fract(sin(p.x*456.+p.y*56.)*100.);
} 

vec2 smooth_v2(in vec2 v)
{
	return v*v*(3.-2.*v);
}

float smooth_noise(in vec2 p) 
{
	vec2 f = smooth_v2(fract(p));
	float a = random(floor(p));
	float b = random(vec2(ceil(p.x),floor(p.y)));
	float c = random(vec2(floor(p.x), ceil(p.y)));
	float d = random(vec2(ceil(p)));

	return 
	mix(
		mix(a, b, f.x),
		mix(c, d, f.x),
		f.y
	);
}

float fractal_noise(in vec2 p)
{
	float total = 0.5;
	float amplitude = 1.;
	float frequency = 1.;
	float iterations = 4.;
	for(float i = 0; i < iterations; i++)
	{
		total += (smooth_noise(p*frequency)-.5)*amplitude;
		amplitude *= 0.5;
		frequency *= 2.;
	}
	return total;
}

void main() {
	vec3 color = texture2D(colortex0, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;
	
	if(depth == 1.0) {
		vec2 uv = texcoord*10.;
		vec2 uv2 = texcoord*30.+frameTimeCounter*0.1;
		color.rgb += vec3(fractal_noise(uv)*fractal_noise(uv2));
	}
	
	
	
	

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}