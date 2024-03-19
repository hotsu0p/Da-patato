#version 120
#extension GL_EXT_gpu_shader4 : enable
flat varying vec3 ambientUp;
const int noiseTextureResolution = 1;

const float ambientOcclusionLevel = 1.0;
const float	sunPathRotation	= -40.;	//[0. -5. -10. -15. -20. -25. -30. -35. -40. -45. -50. -55. -60. -70. -80. -90.]

const int shadowMapResolution = 1024; //[512 768 1024 1536 2048 3172 4096 8192]
const float shadowDistance = 90.0;		//draw distance of shadows
const float shadowDistanceRenderMul = 1.;
const bool 	shadowHardwareFiltering0 = true;
/*
const int colortex0Format = RGB8;
const int colortex1Format = R11F_G11F_B10F;

const int colortex4Format = R11F_G11F_B10F;
*/
//no need to clear the buffers, saves a few fps
const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = false;
const bool colortex4Clear = false;
#define MIN_LIGHT_AMOUNT 1.0 //[0.0 0.5 1.0 1.5 2.0 3.0 4.0 5.0]
#define TORCH_AMOUNT 1.0 //[0.0 0.5 0.75 1. 1.2 1.4 1.6 1.8 2.0]
#define TORCH_R 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_G 0.42 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.42 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define TORCH_B 0.11 //[0.0 0.05 0.1 0.11 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define SKY_BRIGHTNESS_DAY 1.0 //[0.0 0.5 0.75 1. 1.2 1.4 1.6 1.8 2.0]
#define SKY_BRIGHTNESS_NIGHT 1.0 //[0.0 0.5 0.75 1. 1.2 1.4 1.6 1.8 2.0]

uniform float rainStrength;
uniform vec3 nsunColor;
uniform float skyIntensity;
uniform float skyIntensityNight;

void main() {
/* DRAWBUFFERS:4 */
gl_FragData[0] = vec4(0.0);
if (gl_FragCoord.x < 17. && gl_FragCoord.y < 17.){
  float skyLut = floor(gl_FragCoord.y)/16.;
  float sky_lightmap = pow(skyLut,2.23);
  float torchLut = floor(gl_FragCoord.x)/16.;
  torchLut *= torchLut;
  float torch_lightmap = ((torchLut*torchLut)*(torchLut*torchLut))*(torchLut*20.)+torchLut*2.;
  vec3 ambient = ambientUp*sky_lightmap+torch_lightmap*0.23*vec3(TORCH_R,TORCH_G,TORCH_B)*TORCH_AMOUNT+MIN_LIGHT_AMOUNT*0.004;
  gl_FragData[0] = vec4(ambient*10.,1.0);
}
const float pi = 3.141592653589793238462643383279502884197169;
if (gl_FragCoord.x > 18. && gl_FragCoord.y > 1.){
  float cosY = clamp(floor(gl_FragCoord.x - 18.0)/256.*2.0-1.0,-1.0+1e-5,1.0-1e-5);
  float mCosT = clamp(floor(gl_FragCoord.y-1.0)/256.,0.0+1e-5,1.0-1e-5);
  float Y = acos(cosY);
  const float a = -1.1;
  const float b = -0.3;
  const float c = 7.0;
  const float d = -4.;
  const float e = 0.45;

  //luminance (cie model)
  float L0 = (1.0+a*exp(b/mCosT))*(1.0+c*(exp(d*Y)-exp(d*3.1415/2.))+e*cosY*cosY);
	float L0Moon = (1.0+a*exp(b/mCosT))*(1.0+c*(exp(d*(pi-Y))-exp(d*3.1415/2.))+e*cosY*cosY);
	vec3 skyColor0 = mix(vec3(0.07,0.4,1.)/1.5,vec3(0.4,0.5,0.6)/1.5,rainStrength);
	vec3 normalizedSunColor = nsunColor;

	vec3 skyColor = mix(skyColor0,normalizedSunColor,1.0-pow(1.0+L0,-1.2))*(1.0-rainStrength*0.8);
  gl_FragData[0].rgb = pow(L0,1.0-rainStrength*0.5)*skyIntensity*skyColor*vec3(0.8,0.9,1.)*20.*SKY_BRIGHTNESS_DAY + pow(L0Moon,1.0-rainStrength*0.5)*skyIntensityNight*vec3(0.08,0.12,0.18)*vec3(0.3)*SKY_BRIGHTNESS_NIGHT;


}

}
