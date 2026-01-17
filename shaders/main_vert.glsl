attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

uniform int worldTime;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

varying vec4 tangent_face;
varying vec3 normals_face;

varying vec4 shadowPos;
varying vec4 viewPos;
varying float isWater;
varying vec4 mc_entity;


varying vec3 viewPos_v3;

in vec2 mc_midTexCoord;

varying vec2 jedlm;

#include "/distort.glsl"
#include "/settings.glsl"

float waving_sin() {
	return sin(worldTime*0.01)*0.06 + sin(worldTime*0.1) * 0.04 + sin(worldTime*0.05) * 0.05 + sin(worldTime * 0.02) * 0.04;
}

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    mc_entity = mc_Entity;

	jedlm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    normals_face = normalize(gl_NormalMatrix * gl_Normal);
    tangent_face = vec4(normalize(gl_NormalMatrix * at_tangent.xyz),at_tangent.w);

	viewPos = (gl_ModelViewMatrix * gl_Vertex);
	viewPos_v3 = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
	vec3 feetPlayerPos = (gbufferModelViewInverse * viewPos).xyz;


	
	//waving leaves
	#ifdef WAVING_LEAVES
	if (mc_Entity.x == 10001.0) {
		vec3 worldPos =(gbufferModelViewInverse * viewPos).xyz;
		worldPos.xyz += cameraPosition;
		worldPos.xyz = worldPos.xyz + waving_sin();
		viewPos = (gbufferModelView * vec4(worldPos - cameraPosition,1.0));
	}
	#endif
	
	//waving grass
	#ifdef WAVING_GRASS
	if(mc_Entity.x == 10002.0) {
		if(texcoord.y < mc_midTexCoord.y)
		{
			vec3 worldPos =(gbufferModelViewInverse * viewPos).xyz;
			worldPos.xyz += cameraPosition;
			worldPos.xyz = worldPos.xyz + waving_sin();
			viewPos = (gbufferModelView * vec4(worldPos - cameraPosition,1.0));
		}
		
	}
	#endif

	float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));

		
	#ifdef EXCLUDE_FOLIAGE
		//when EXCLUDE_FOLIAGE is enabled, act as if foliage is always facing towards the sun.
		//in other words, don't darken the back side of it unless something else is casting a shadow on it.
		if (mc_Entity.x == 10000.0) lightDot = 1.0;
		shadowPos = vec4(0.0); //mark that this vertex does not need to check the shadow map.
	#endif

	//viewPos = gl_ModelViewMatrix * gl_Vertex;
	if (lightDot > 0.0) { //vertex is facing towards the sun
		vec4 playerPos = gbufferModelViewInverse * viewPos;
		shadowPos = shadowProjection * (shadowModelView * playerPos); //convert to shadow ndc space.
		float bias = computeBias(shadowPos.xyz);
		shadowPos.xyz = distort(shadowPos.xyz); //apply shadow distortion
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
		//apply shadow bias.
		#ifdef NORMAL_BIAS
			//we are allowed to project the normal because shadowProjection is purely a scalar matrix.
			//a faster way to apply the same operation would be to multiply by shadowProjection[0][0].
			vec4 normal = shadowProjection * vec4(mat3(shadowModelView) * (mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal)), 1.0);
			shadowPos.xyz += normal.xyz / normal.w * bias;
		#else
			shadowPos.z -= bias / abs(lightDot);
		#endif
	}
	else { //vertex is facing away from the sun
		lmcoord.y *= SHADOW_BRIGHTNESS; //guaranteed to be in shadows. reduce light level immediately.
		shadowPos = vec4(0.0); //mark that this vertex does not need to check the shadow map.
	}
	shadowPos.w = lightDot;

	
	gl_Position = gl_ProjectionMatrix * viewPos;


}