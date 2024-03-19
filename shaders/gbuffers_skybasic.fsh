#version 120

/* DRAWBUFFERS:1 */
#define CLOUDS
#define STARS


varying vec3 sunVec;
varying float sunIntensity;
varying float skyIntensity;
varying float moonIntensity;
varying float skyIntensityNight;

varying float SdotU;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform vec3 cameraPosition;
const int noiseTextureResolution = 1024;
uniform vec4 lightCol;
uniform float frameTimeCounter;

varying vec3 cloudCol;
uniform vec3 sunColor;
uniform vec3 nsunColor;
uniform vec3 sunPosition;
uniform vec2 texelSize;
uniform float far;

uniform float rainStrength;


#include "lib/color_dither.glsl"
#include "lib/color_transforms.glsl"
#include "lib/sky_gradient.glsl"
#include "lib/clouds.glsl"
#include "lib/stars.glsl"
vec4 smoothfilter(in sampler2D tex, in vec2 uv, in vec2 textureResolution)
{
	uv = uv*textureResolution + 0.5;
	vec2 iuv = floor( uv );
	vec2 fuv = fract( uv );
	uv = iuv + (fuv*fuv)*(3.0-2.0*fuv);
	uv = uv/textureResolution - 0.5/textureResolution;
	return texture2D( tex, uv);
}
vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
vec3 toScreenSpaceVector(vec3 p) {
    vec3 p3 = p * 2. - 1.;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return normalize(fragposition.xyz);
}




void main() {


	vec3 fragpos = toScreenSpaceVector(vec3(gl_FragCoord.xy*texelSize,1.));
	fragpos = mat3(gbufferModelViewInverse) * fragpos;


	vec3 color = getSkyColorLut(fragpos,sunVec,fragpos.y,gaux1);
	//vec3 color = getSkyColor(fragpos,sunVec,fragpos.y);
	if (fragpos.y > 0.){
		#ifdef STARS
		color += stars(fragpos);
		#endif
		color = drawSun(dot(sunVec,fragpos),sunIntensity, nsunColor,color);
		#ifdef CLOUDS
		color = cloud2D(fragpos,color);
		#endif
	}

	gl_FragData[0] = vec4(color*10.,1.0);
	gl_FragData[0].rgb = fp10Dither(gl_FragData[0].rgb,gl_FragCoord.xy*texelSize);

	//gl_FragData[0].rgb = pow(smoothfilter(noisetex,gl_FragCoord.xy*rcp(vec2(viewWidth,viewHeight))/10.,vec2(2048.)).xxx,vec3(2.2))*400.;
}
