#define COLORED_SHADOWS 1 //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows. 2: Stained glass will not cast any shadows. [0 1 2]
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

uniform sampler2D lightmap;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D depthtex0;

uniform float sunAngle;
uniform vec3 shadowLightPosition;



uniform float viewWidth;
uniform float viewHeight;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec4 viewPos;
varying vec4 mc_entity;

varying vec3 viewPos_v3;

//Fog
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform float far;

uniform vec3 cameraPosition;

uniform vec3 skyColor;

uniform float ambientLight;

varying vec2 jedlm;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;


uniform float wetness;
uniform float frameTimeCounter;


//lighting
varying vec4 tangent_face;
varying vec3 normals_face;

//in vec3 vaNormal;

//fix artifacts when colored shadows are enabled
const bool shadowcolor0Nearest = true;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;

const float gamma = 0.5;
//only using this include for shadowMapResolution,
//since that has to be declared in the fragment stage in order to do anything.
#include "/distort.glsl"
#include "/settings.glsl"

float random3d(in vec3 p) 
{
	return fract(sin(p.x*456.+p.y*56.+p.z*741.)*100.);
} 

vec3 smooth_v3(in vec3 v)
{
	return v*v*(3.-2.*v);
}

float smooth_noise3d(in vec3 p) 
{
	vec3 f = smooth_v3(fract(p));

	float a = random3d(floor(p));
	float b = random3d(vec3(ceil(p.x),floor(p.y),floor(p.z)));
	float c = random3d(vec3(floor(p.x), ceil(p.y),floor(p.z)));
	float d = random3d(vec3(ceil(p.xy),floor(p.z)));

	float bottom =  
	mix(
		mix(a, b, f.x),
		mix(c, d, f.x),
		f.y
	);

    a = random3d(vec3(floor(p.x),floor(p.y),ceil(p.z)));
	b = random3d(vec3(ceil(p.x),floor(p.y),ceil(p.z)));
	c = random3d(vec3(floor(p.x), ceil(p.y),ceil(p.z)));
	d = random3d(vec3(ceil(p.xy), ceil(p.z)));

    float top = 
    mix(
        mix(a,b,f.x),
        mix(c,d,f.x),
        f.y
    );

    return mix(bottom, top, f.z);

}

float fractal_noise3d(in vec3 p)
{
	float total = 0.25;
	float amplitude = 1.;
	float frequency = 1.;
	float iterations = 4.;
	for(float i = 0; i < iterations; i++)
	{
		total += (smooth_noise3d(p*frequency)-.5)*amplitude;
		amplitude *= 0.5;
		frequency *= 2.;
	}
	return total;
}

float get_cloud(in vec3 p)
{
	return clamp(
		//noise for clouds
		fractal_noise3d(p)
		//Patches for clouds
		*fractal_noise3d(p*0.1)*
		(1.-(0.3*(1.-wetness)))*2.0
	,0.,1.);
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homogeneousPos = projectionMatrix * vec4(position, 1.0);
	return homogeneousPos.xyz/homogeneousPos.w;
}

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	vec2 lm = lmcoord;
	#if LIGHTING_STYLE == 0
		if (shadowPos.w > 0.0) {
			//surface is facing towards shadowLightPosition
			#if COLORED_SHADOWS == 0
				//for normal shadows, only consider the closest thing to the sun,
				//regardless of whether or not it's opaque.
				if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
			#else
				//for invisible and colored shadows, first check the closest OPAQUE thing to the sun.
				if (texture2D(shadowtex1, shadowPos.xy).r < shadowPos.z) {
			#endif
				//surface is in shadows. reduce light level.
				lm.y *= SHADOW_BRIGHTNESS;
			}
			else {
				//surface is in direct sunlight. increase light level.
				lm.y = mix(31.0 / 32.0 * SHADOW_BRIGHTNESS, 31.0 / 32.0, sqrt(shadowPos.w));
				#if COLORED_SHADOWS == 1
					//when colored shadows are enabled and there's nothing OPAQUE between us and the sun,
					//perform a 2nd check to see if there's anything translucent between us and the sun.
					if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
						//surface has translucent object between it and the sun. modify its color.
						//if the block light is high, modify the color less.
						vec4 shadowLightColor = texture2D(shadowcolor0, shadowPos.xy);
						//make colors more intense when the shadow light color is more opaque.
						shadowLightColor.rgb = mix(vec3(1.0), shadowLightColor.rgb, shadowLightColor.a);
						//also make colors less intense when the block light level is high.
						shadowLightColor.rgb = mix(shadowLightColor.rgb, vec3(1.0), lm.x);
						//apply the color.
						color.rgb *= shadowLightColor.rgb;
					}
				#endif
			}
		}
		color *= texture2D(lightmap, lm);
	#endif

	#if LIGHTING_STYLE == 1
		//normalize(gl_NormalMatrix * glnormal);
        vec3 bitangent = cross(tangent_face.rgb,normals_face.xyz)*tangent_face.w;
        mat3 tbn_matrix = mat3(tangent_face.xyz, bitangent.xyz, normals_face.xyz);

        vec4 normals_texture = texture2D(normals, texcoord).rgba;
        normals_texture.xy = normals_texture.xy * 2. - 1.;
        normals_texture.z = sqrt(1.0-dot(normals_texture.xy, normals_texture.xy));
        normals_texture.xyz = normalize( tbn_matrix * normals_texture.xyz);

		float lightDot = clamp(dot(normalize(shadowLightPosition), normals_texture.xyz),0.,1.);
        

		vec4 jedlmap = texture2D(lightmap, jedlm);
		
        
		float lighting_coefficient = lightDot * jedlm.y + jedlmap.x * jedlm.x + ambientLight;
		//Lighting
		color.rgb *= (sunAngle<.5) ? vec3(1.0, 0.9, 0.8) * lighting_coefficient : vec3(.5,.5,.7) * lighting_coefficient;


		// Fog

		#if USE_CUSTOM_FOG_SETTINGS == 1
			float current_fog_start = CUSTOM_FOG_START;
			float current_fog_end = CUSTOM_FOG_END;
			float current_fog_max = MAX_FOG_VALUE;
		#else
			float current_fog_start = fogStart;
			float current_fog_end = fogEnd;
			float current_fog_max = 1.0;
		#endif
		
		#if BORDER_FOG == 1
			float border_fog_amount = clamp((distance(vec3(0.), viewPos_v3)-(BORDER_FOG_START*far))/(1.-(BORDER_FOG_START*far)),0.,current_fog_max);
		#endif
		
		#if FOG_ON == 1
			#ifdef border_fog_amount
				float fog_amount = max(
					clamp((length(viewPos_v3)-current_fog_start)/(current_fog_end-current_fog_start),0.,current_fog_max),
					border_fog_amount);
			#else
				float fog_amount = clamp((length(viewPos_v3)-current_fog_start)/(current_fog_end-current_fog_start),0.,current_fog_max);
			#endif
			color.rgb = mix(color.rgb, fogColor, fog_amount);
		#endif

        #if DEBUG_VIEW == 1
            color.rgb = normals_face.xyz * 0.5 + 0.5;
        #endif

        #if DEBUG_VIEW == 2
            color.rgb = (texture2D(normals, texcoord).xyz);
        #endif

        #if DEBUG_VIEW == 3
            color.rgb = normals_texture.rgb * 0.5 + 0.5;
        #endif
	
	#endif

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}