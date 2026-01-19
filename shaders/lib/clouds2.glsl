#define DRAW_SHADOW_MAP gcolor //Configures which buffer to draw to the screen [gcolor shadowcolor0 shadowtex0 shadowtex1]


uniform float frameTimeCounter;
uniform int worldTime;
uniform sampler2D colortex2;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;



uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
//uniform float rainStrength;

uniform float ambientLight;
uniform float wetness;

uniform vec3 shadowLightPosition;
uniform vec3 skyColor;
uniform float sunAngle;

uniform vec3 cameraPosition;

varying vec2 texcoord;

const bool colortex1Clear = false;
const bool colortex2MipMapEnabled = true;

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

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homogeneousPos = projectionMatrix * vec4(position, 1.0);
	return homogeneousPos.xyz/homogeneousPos.w;
}

float patchmulti = 0.0115;

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

void main() {
	vec3 color = texture2D(colortex2, texcoord).rgb;
	vec3 sky_color = textureLod(colortex2, texcoord,6).rgb;

	float depth = 1.;//texture2D(depthtex0, texcoord).r;
	

	float cloud_time = worldTime * .1;

	vec4 pos = vec4(texcoord, depth, 1.)*2.0-1.0;
	
    
    

   
    pos.xyz = projectAndDivide(gbufferProjectionInverse, pos.xyz); //view Position
	vec3 view_pos = vec3(pos.xyz);

	pos = (gbufferModelViewInverse * vec4(pos.xyz, 1.)); // Feet Position

	
	vec3 raydir = normalize(pos.xyz);

    float starting_distance = 1./raydir.y;

	vec2 uv = raydir.xz * starting_distance + .05 * cloud_time * CLOUD_SPEED + cameraPosition.xz*0.01;

    vec4 clouds = vec4(vec3(1.),0.);

    float scale = .1;

	vec3 sundir = normalize(vec4(gbufferModelViewInverse * vec4(shadowLightPosition.xyz,1.)).xyz);

	float sun_dot = clamp(dot(raydir, sundir),0.,1.);

	float sunset_effect = pow(1.-sundir.y,10.);

	vec3 sun_color = (sunAngle<.5? vec3(1.) : vec3(.5,.5,.7))
	*(1.-vec3(1.,1.2,1.3)*sunset_effect);


    if(raydir.y > 0.)
	{
        vec3 player = vec3(uv,0.);
        

        float sky_density = .1;

		for(float s = 0.; s < CLOUD_SAMPLES && clouds.a < 0.99; s++ ) 
        {
            vec3 ray_pos = player + raydir * ((s-random3d(vec3((texcoord+.1*frameTimeCounter*CLOUD_SPEED),s*4)))) * scale;
            
			vec4 cloud = vec4(get_cloud(ray_pos));
            
			cloud.rgb = vec3(1.);

			//Shading
			vec3 light = vec3(1.);
			float cloud_top = player.y + CLOUD_SAMPLES + CLOUD_HEIGHT;
			
			vec3 ray_s_pos = ray_pos;


			for(float ss = 0.; ss < CLOUD_SHADING_SAMPLES && ray_s_pos.y < cloud_top; ss++ ) 
        	{
				ray_s_pos = ray_pos + sundir * (ss-random3d(frameTimeCounter+vec3(texcoord,ss))) * scale;
				
				float cloud_shading = pow(get_cloud(ray_s_pos),1.);
				light *= 1.-cloud_shading;
			}

			light += light.r * pow(sun_dot,1.+20.*(light.r));
			light += light.g * pow(sun_dot,1.+10.*(light.g));


			//sky ambient lighting			
			vec3 sky_color_final = sky_color;

			for(float ss = 0.; ss < 3.; ss++)
			{
				vec3 ray_s_pos = ray_pos + vec3(0.,1.,0.) * (ss-random3d(frameTimeCounter+vec3(texcoord,ss))) *scale;

				float cloud_shading= pow(get_cloud(ray_s_pos),3.);
				sky_color_final *= 1.-cloud_shading*vec3(1.1,1.2,1.3);
			}


			
			
			cloud.rgb *= clamp(light + sky_color_final*0.5 + sky_color *0.25, 0., 1.);


            //blend sample into total
            clouds.rgb = mix(clouds.rgb, cloud.rgb, (1.-clouds.a) * cloud.a);
            clouds.a = clamp(clouds.a+(1.-clouds.a) * cloud.a,0.,1.);
        }

		//horizon fog
        clouds.rgb = mix(clouds.rgb,sky_color,pow(1.-raydir.y,4.));
        

		
	} else {
        clouds = vec4(0.);
    }
    float cloud_fog = 1.+1./raydir.y;
    
	//setting cloud color to white
	//clouds.rgb = vec3(1.);
	//fake shading of cloud clumps
	//clouds.rgb*=1.-clamp((clouds.a-0.5)*0.1,0.,0.25);

	color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a,1.));// / max(1.,cloud_fog * CLOUD_FOG));

	
	
	
	depth = depth == 1.0 ? 1.0 : 0.0;

	#include "./reprojection.glsl"
	

	color = mix(color, ray_color.rgb,.9);
	color.rgb = texcoord.x < 0.05 && texcoord.y < sunset_effect ? sun_color : color.rgb;
	

/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(color, depth); //gcolor
}