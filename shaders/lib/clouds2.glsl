#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]


uniform float frameTimeCounter;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float rainStrength;

uniform vec3 cameraPosition;

varying vec2 texcoord;

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
	float total = 0.5;
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

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homogeneousPos = projectionMatrix * vec4(position, 1.0);
	return homogeneousPos.xyz/homogeneousPos.w;
}

void main() {
	vec3 color = texture2D(colortex2, texcoord).rgb;
	float depth = texture2D(depthtex0, texcoord).r;
	
    vec3 sky_color = color;
    

    vec4 pos = vec4(texcoord, depth, 1.)*2.0-1.0;
    pos.xyz = projectAndDivide(gbufferProjectionInverse, pos.xyz); //view Position
	pos = (gbufferModelViewInverse * vec4(pos.xyz, 1.)); // Feet Position
	pos.xyz += cameraPosition; //World Position
	vec3 raydir = normalize(pos.xyz);
    float starting_distance = 1./raydir.y;

	vec2 uv = raydir.xz * 1. * starting_distance + .1 * frameTimeCounter * CLOUD_SPEED;
	vec2 uv2 = raydir.xz * 3. * starting_distance - .1 * frameTimeCounter*CLOUD_PERMUTATION_SPEED;

    

    vec4 clouds = vec4(vec3(1.),0.);

    float scale = .1;

    if(raydir.y > 0.)
	{
        vec3 player = vec3(uv,0.);
        vec3 player2 = vec3(uv2, 0.);
        

        float sky_density = .1;

		for(float s = 0.; s < CLOUD_SAMPLES && clouds.a < 0.99; s++ ) 
        {
            vec3 ray_pos = player + raydir * ((s-random3d(vec3((texcoord+.1*frameTimeCounter*CLOUD_SPEED),s*6)))) * scale;
            vec3 ray_pos2 = player + raydir * (s-random3d(vec3(texcoord+.1*frameTimeCounter*CLOUD_PERMUTATION_SPEED,s*6))) * 3. * scale;   
            vec4 cloud = vec4(fractal_noise3d(ray_pos)*fractal_noise3d(ray_pos2));

            //making holes in the noise to emulate cloud clumps and increase density when raining
	        clouds.a =clamp((clouds.a-0.3*(1.-rainStrength))*4.0,sky_density,2.);
            cloud.rgb = mix(vec3(1.), sky_color, min(1.,s/CLOUD_SAMPLES+sky_density*(1.-clouds.a)));

            //blend it with existing
            clouds.rgb = mix(clouds.rgb, cloud.rgb, (1.-clouds.a) * cloud.a);
            clouds.a = clamp(clouds.a+(1.-clouds.a) * cloud.a,0.,1.);
        }
        clouds.rgb = mix(clouds.rgb,sky_color,pow(1.-raydir.y,4.));
        

		
	} else {
        clouds = vec4(0.);
    }
    float cloud_fog = 1.+1./raydir.y;
    
	//setting cloud color to white
	//clouds.rgb = vec3(1.);
	//fake shading of cloud clumps
	//clouds.rgb*=1.-clamp((clouds.a-0.5)*0.1,0.,0.25);

	color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a,1.) / max(1.,cloud_fog * CLOUD_FOG));
	
	
	depth = depth == 1.0 ? 1.0 : 0.0;
	

/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(color, depth); //gcolor
}