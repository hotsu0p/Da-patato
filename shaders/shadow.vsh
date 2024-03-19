#version 120
#extension GL_EXT_gpu_shader4 : enable



#define SHADOW_MAP_BIAS 0.8
const float PI = 3.1415927;
varying vec3 texcoord;


attribute vec4 mc_Entity;
vec4 BiasShadowProjection(in vec4 projectedShadowSpacePosition) {

	vec2 pos = abs(projectedShadowSpacePosition.xy * 1.165);
	vec2 posSQ = pos*pos;

	float dist = pow(posSQ.x*posSQ.x*posSQ.x + posSQ.y*posSQ.y*posSQ.y, 1.0 / 6.0);

	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;

	projectedShadowSpacePosition.xy /= distortFactor*0.92;



	return projectedShadowSpacePosition;
}
void main() {



	gl_Position = BiasShadowProjection(ftransform());
	gl_Position.z /= 3.0;

	texcoord.xy = gl_MultiTexCoord0.xy;

	texcoord.z = 1.0;
	if(mc_Entity.x == 8 || mc_Entity.x == 9) texcoord.z = 0.0;
}
