#define COLORED_SHADOWS 1 //0: Stained glass will cast ordinary shadows. 1: Stained glass will cast colored shadows. 2: Stained glass will not cast any shadows. [0 1 2]
#define SHADOW_BRIGHTNESS 0.75 //Light levels are multiplied by this number when the surface is in shadows [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

uniform sampler2D lightmap;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D texture;
uniform sampler2D normals;

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

varying vec2 jedlm;

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
        vec3 bitangent = normalize(cross(tangent_face.rgb,normals_face.xyz)*tangent_face.w);
        mat3 tbn_matrix = mat3(tangent_face.xyz, bitangent.xyz, normals_face.xyz);

        vec4 normals_texture = texture2D(normals, texcoord).rgba;
        normals_texture.xy = normals_texture.xy * 2. - 1.;
        normals_texture.z = sqrt(1.0-dot(normals_texture.xy, normals_texture.xy));
        normals_texture.xyz = tbn_matrix * normals_texture.xyz;

		float lightDot = clamp(dot(normalize(shadowLightPosition), normals_texture.xyz),0.1,1.);
        

		vec4 jedlmap = texture2D(lightmap, jedlm);
		
        

		//Lighting
		color.rgb *= (lightDot * jedlm.y + jedlmap.x * jedlm.x);


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