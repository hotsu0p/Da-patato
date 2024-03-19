#version 120
#extension GL_EXT_gpu_shader4 : enable

//#define PCF
#define MIN_LIGHT_AMOUNT 1.0 //[0.0 0.5 1.0 1.5 2.0 3.0 4.0 5.0]

#define TORCH_AMOUNT 1.0 //[0.0 0.5 0.75 1. 1.2 1.4 1.6 1.8 2.0]
#define TORCH_R 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_G 0.42 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.42 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_B 0.11 //[0.0 0.05 0.1 0.11 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

const int shadowMapResolution = 1024; //[512 768 1024 1536 2048 3172 4096 8192]


varying vec4 lmtexcoord;
varying vec4 color;
varying vec4 normalMat;

#define SHADOW_MAP_BIAS 0.8

uniform sampler2D texture;
uniform sampler2D gaux1;
uniform sampler2DShadow shadow;

uniform vec4 lightCol;
uniform vec3 sunVec;

uniform vec2 texelSize;
uniform float rainStrength;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

//faster and actually more precise than pow 2.2
vec3 toLinear(vec3 sRGB){
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}



/* DRAWBUFFERS:1 */
void main() {
	gl_FragData[0] = texture2D(texture, lmtexcoord.xy).bbba*color.bbba;
			gl_FragData[0].a = clamp(gl_FragData[0].a -0.1,0.0,1.0)*0.6;
	vec3 albedo = gl_FragData[0].rgb*color.rgb;

	float NdotL = normalMat.x;
	vec3 direct = lightCol.rgb;





	vec3 lightmap = texture2D(gaux1,lmtexcoord.zw).xyz;

	direct *= normalMat.z;


	vec3 diffuseLight = direct + lightmap;

	vec3 color = diffuseLight*albedo;


	gl_FragData[0].rgb = color;



}
