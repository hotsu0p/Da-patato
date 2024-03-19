#version 120
#extension GL_EXT_gpu_shader4 : enable
#define EXPOSURE_MULTIPLIER 1.0 //[0.25 0.4 0.5 0.6 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.2 1.3 1.4 1.5 2.0 3.0 4.0]
varying vec2 texcoord;
varying float exposure;
uniform ivec2 eyeBrightnessSmooth;

uniform float sunIntensity;
uniform float moonIntensity;
uniform float skyIntensity;
uniform float skyIntensityNight;



void main() {

	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0.xy;
	float avgEyeIntensity = ((sunIntensity*3.0+moonIntensity*0.001)*16.+(skyIntensity+skyIntensityNight*0.001)*8.)*pow(eyeBrightnessSmooth.y/255.,2.4) +0.02;
	exposure = EXPOSURE_MULTIPLIER*0.06*pow(avgEyeIntensity,-1./3.2);
}
