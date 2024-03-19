#version 120





varying vec4 color;
varying vec2 texcoord;

uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;

vec3 toLinear(vec3 sRGB){
return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}
#include "lighting.glsl"	
	const vec2[8] offsets = vec2[8](vec2(1./8.,-3./8.),
									vec2(-1.,3.)/8.,
									vec2(5.0,1.)/8.,
									vec2(-3,-5.)/8.,
									vec2(-5.,5.)/8.,
									vec2(-7.,-1.)/8.,
									vec2(3,7.)/8.,
									vec2(7.,-7.)/8.);				


void main() {

	color = gl_Color;
	color.rgb = toLinear(color.rgb);
		
	gl_Position = ftransform();
	

	
	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);
	texcoord = (gl_MultiTexCoord0).xy;

	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
	
	
	
	color.rgb *= lightColor(lmcoord, normal, sunVec, -sunVec, upVec, false,1.);

}