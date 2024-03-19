#version 120
#extension GL_EXT_gpu_shader4 : enable

#define TONEMAP_ACES





varying vec2 texcoord;
varying float exposure;
uniform sampler2D depthtex0;
uniform sampler2D colortex1;
uniform sampler2D gaux1;
uniform vec3 nsunColor;
uniform vec3 sunVec;
uniform vec2 texelSize;
uniform vec3 sunPosition;
uniform float skyIntensity;
uniform float skyIntensityNight;
uniform float fogAmount;
uniform float rainStrength;
uniform ivec2 eyeBrightness;
uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform vec4 lightCol;
#include "lib/color_transforms.glsl"
#include "lib/color_dither.glsl"
#include "lib/projections.glsl"
#include "lib/sky_gradient.glsl"



void main() {
/* DRAWBUFFERS:0 */
	vec3 color = texture2D(colortex1,texcoord).rgb/10.;


	float z = texture2D(depthtex0,texcoord).x;
	if (isEyeInWater == 0){
		if (z < 1.0){
			vec3 fragpos = toScreenSpace(vec3(texcoord,z));
			float dist = length(fragpos);
			float atten = eyeBrightness.y/255.+0.006;

			vec3 np3 = mat3(gbufferModelViewInverse) * (fragpos/(dist));
			vec3 skyColor = getSkyColorLut(np3,mat3(gbufferModelViewInverse)*sunVec,np3.y,gaux1) ;

			float fogFactorAbs = exp(-dist*fogAmount*0.2);
			float fogFactorScat = exp(-dist*fogAmount*0.7);

			vec3 col0 = normalize(skyColor)*(skyIntensity*mix(vec3(1.),vec3(0.8,0.9,1.),rainStrength)+skyIntensityNight*0.01)*2.;
			vec3 fogColor = mix(col0,skyColor,clamp(dist/512.,0.,1.));

			color.rgb = fogColor*(1.0-fogFactorScat)*atten+color*fogFactorAbs;
			}
	}
	else {
		vec3 fragpos = toScreenSpace(vec3(texcoord,z));
		float dist = length(fragpos);
		float fogFactorAbs = exp2(-dist/10.*0.8);
		float fogFactorScat = fogFactorAbs;
		vec3 waterFogCol = (lightCol.g + skyIntensity + skyIntensityNight)*vec3(0.06,0.27,0.35);
		color.rgb = waterFogCol*(1.0-fogFactorScat)/exposure*0.01+color*fogFactorAbs;
	}



	//vignetting
	color *= 15.0-dot(texcoord-0.5,texcoord-0.5)*20.;
	//color = texture2D(gaux1,texcoord).rgb;
	//tonemap
	#ifndef TONEMAP_ACES
		gl_FragData[0].rgb = int8Dither(Uncharted2Tonemap(exposure*color*0.5*vec3(1.0,0.87,0.78))/Uncharted2Tonemap(vec3(11.2)),texcoord);
	#endif
	#ifdef TONEMAP_ACES
		gl_FragData[0].rgb = int8Dither(ACESFilm(exposure*color*0.5*vec3(1.0,0.87,0.78)),texcoord);
	#endif

}
