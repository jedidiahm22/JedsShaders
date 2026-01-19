#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]


uniform float frameTimeCounter;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float rainStrength;

uniform vec3 cameraPosition;

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

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homogeneousPos = projectionMatrix * vec4(position, 1.0);
	return homogeneousPos.xyz/homogeneousPos.w;
}

void main() {
	vec3 color = texture2D(colortex2, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;
	

	#if BACKGROUND_RESOLUTION_DIVIDER == 1
	if(depth == 1.0) 
	#endif
	{
		vec4 pos = vec4(texcoord, depth, 1.)*2.0-1.0;
        pos.xyz = projectAndDivide(gbufferProjectionInverse, pos.xyz); //view Position
		pos = (gbufferModelViewInverse * vec4(pos.xyz, 1.)); // Feet Position
		pos.xyz += cameraPosition; //World Position
		vec3 raydir = normalize(pos.xyz);

		vec2 uv = raydir.xz * 1. * 1./raydir.y + .1 * frameTimeCounter * CLOUD_SPEED;
		vec2 uv2 = raydir.xz * 3./raydir.y - .1 * frameTimeCounter*CLOUD_PERMUTATION_SPEED;




		//add clouds
		vec4 clouds = (raydir.y > 0.) ? vec4(fractal_noise(uv)*fractal_noise(uv2)) : vec4(0.);

		float cloud_fog = 1.+1./raydir.y;


		//making holes in the noise to emulate cloud clumps
		clouds.a =clamp((clouds.a-0.3*(1.-rainStrength))*4.0,0.,2.);
		//setting cloud color to white
		clouds.rgb = vec3(1.);
		//fake shading of cloud clumps
		clouds.rgb*=1.-clamp((clouds.a-0.5)*0.1,0.,0.25);

		color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a,1.) / max(1.,cloud_fog * CLOUD_FOG));
	}
	
	
	depth = depth == 1.0 ? 1.0 : 0.0;
	

/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(color, depth); //gcolor
}