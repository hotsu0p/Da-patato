#version 120
#extension GL_EXT_gpu_shader4 : enable
const int shadowMapResolution = 1024; //[512 768 1024 1536 2048 3172 4096 8192]
varying vec4 lmtexcoord;
varying vec4 color;
 varying vec4 normalMat;
varying vec3 binormal;
varying vec3 tangent;
varying vec3 normalR;
//#define PCF

#define SHADOW_MAP_BIAS 0.8
uniform vec3 cloudCol;
uniform sampler2D texture;
uniform sampler2D noisetex;
uniform sampler2DShadow shadow;
uniform sampler2D gaux1;
uniform vec4 lightCol;
uniform vec3 sunVec;
uniform float frameTimeCounter;
uniform float lightPosSign;

uniform float moonIntensity;
uniform float sunIntensity;
uniform vec3 sunColor;
uniform vec3 nsunColor;
uniform vec3 upVec;
uniform float sunElevation;
uniform vec2 texelSize;
uniform float rainStrength;
uniform float skyIntensityNight;
uniform float skyIntensity;


#include "lib/color_transforms.glsl"
#include "lib/projections.glsl"
#include "lib/sky_gradient.glsl"
#include "lib/waterBump.glsl"
#include "lib/clouds.glsl"
#include "lib/stars.glsl"

float interleaved_gradientNoise(){
	vec2 coord = gl_FragCoord.xy;
	float noise = fract(52.9829189*fract(0.06711056*coord.x + 0.00583715*coord.y));
	return noise;
}
//area light approximation (from horizon zero dawn siggraph presentation)
float GetNoHSquared(float radiusTan, float NoL, float NoV, float VoL)
{
    // radiusCos can be precalculated if radiusTan is a directional light
    float radiusCos = inversesqrt(1.0 + radiusTan * radiusTan);

    // Early out if R falls within the disc
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan * inversesqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    // Calculate dot(cross(N, L), V). This could already be calculated and available.
    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL,0.,1.));

    // Do one Newton iteration to improve the bent light vector
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr; // use new T to update NoTr
    VoTr = cosTheta * VoTr + sinTheta * VoBr; // use new T to update VoTr

    // Calculate (N.H)^2 based on the bent light vector
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return max(0.0, NoH * NoH / HoH);
}
//optimized ggx from jodie with area light approximation
float GGX (vec3 n, vec3 v, vec3 l, float r, float F0,float lightSize) {
  r*=r;r*=r;

  vec3 h = l + v;
  float hn = inversesqrt(dot(h, h));

  float dotLH = clamp(dot(h,l)*hn,0.,1.);
  float dotNH = clamp(dot(h,n)*hn,0.,1.);
  float dotNL = clamp(dot(n,l),0.,1.);
  float dotNHsq = GetNoHSquared(lightSize,dotNL,dot(n,v),dot(v,l));

  float denom = dotNHsq * r - dotNHsq + 1.;
  float D = r / (3.141592653589793 * denom * denom);
  float F = F0 + (1. - F0) * exp2((-5.55473*dotLH-6.98316)*dotLH);
  float k2 = .25 * r;

  return dotNL * D * F / (dotLH*dotLH*(1.0-k2)+k2);
}
const vec2 shadowOffsets[8] = vec2[8](vec2( -0.7071,  0.7071 ),
vec2( -0.0000, -0.8750 ),
vec2(  0.5303,  0.5303 ),
vec2( -0.6250, -0.0000 ),
vec2(  0.3536, -0.3536 ),
vec2( -0.0000,  0.3750 ),
vec2( -0.1768, -0.1768 ),
vec2( 0.1250,  0.0000 ));
float facos(float sx){
    float x = clamp(abs( sx ),0.,1.);
    float a = sqrt( 1. - x ) * ( -0.16882 * x + 1.56734 );
    return sx > 0. ? a : pi - a;
}

#define SHADOW_MAP_BIAS 0.8
float calcDistort(vec2 worlpos){

	vec2 pos = worlpos * 1.165;
	vec2 posSQ = pos*pos;

	float distb = pow(posSQ.x*posSQ.x*posSQ.x + posSQ.y*posSQ.y*posSQ.y, 1.0 / 6.0);
	return 1.08695652/((1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS);
}


/* DRAWBUFFERS:1 */
void main() {
	float iswater = normalMat.a;
	gl_FragData[0] = texture2D(texture, lmtexcoord.xy)*color;
	if (iswater > 0.4) gl_FragData[0] = vec4(0.42,0.6,0.7,0.6);
	if (iswater > 0.9) gl_FragData[0] = vec4(vec3(0.06,0.27,0.35),0.8);

		vec3 albedo = toLinear(gl_FragData[0].rgb);

		vec3 normal = normalR;
		vec3 fragpos = toScreenSpace(gl_FragCoord.xyz*vec3(texelSize,1.0));
		vec3 p3 = mat3(gbufferModelViewInverse) * fragpos + gbufferModelViewInverse[3].xyz;

		if (iswater > 0.4){
		float bumpmult = 1.0;
		if (iswater > 0.9) bumpmult = .6;
		float parallaxMult = bumpmult;
		vec3 posxz = p3+cameraPosition;



		vec3 bump;
		bump = getWaveHeight(posxz.xz - posxz.y,iswater);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);



		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);

		normal = normalize(bump * tbnMatrix);
		}

		float NdotL = lightCol.a*dot(normal,sunVec);
		float NdotU = dot(upVec,normal);
		float diffuseSun = clamp(NdotL,0.0f,1.0f);
		float skyLight = (NdotU*0.33+1.0);

		vec3 direct = lightCol.rgb;

		float shading = 0.5;
		//compute shadows only if not backface
		if (diffuseSun > 0.001) {
			vec3 p3 = mat3(gbufferModelViewInverse) * fragpos + gbufferModelViewInverse[3].xyz;
			vec3 projectedShadowPosition = mat3(shadowModelView) * p3 + shadowModelView[3].xyz;
			projectedShadowPosition = diagonal3(shadowProjection) * projectedShadowPosition + shadowProjection[3].xyz;

			//apply distortion
			float distortFactor = calcDistort(projectedShadowPosition.xy);
			projectedShadowPosition.xy *= distortFactor;
			//do shadows only if on shadow map
			if (abs(projectedShadowPosition.x) < 1.0-1.5/shadowMapResolution && abs(projectedShadowPosition.y) < 1.0-1.5/shadowMapResolution){
				float diffthresh = (facos(diffuseSun)*0.008+0.00008)/(distortFactor*distortFactor);

				projectedShadowPosition = projectedShadowPosition * vec3(0.5,0.5,0.5/3.0) + vec3(0.5,0.5,0.5);

				#ifdef PCF

				float noise = interleaved_gradientNoise();
				mat2 noiseM = mat2( cos( noise*3.14159265359*2.0 ), -sin( noise*3.14159265359*2.0 ),
								   sin( noise*3.14159265359*2.0 ), cos( noise*3.14159265359*2.0 )
									);


				for(int i = 0; i < 8; i++){
					vec2 offsetS = shadowOffsets[i];

					float weight = 1.0+length(offsetS)*1.412*distortFactor*0.2;
					shading += shadow2D(shadow,vec3(projectedShadowPosition + vec3((noiseM*offsetS)*(distortFactor*0.2*1.412/shadowMapResolution),-diffthresh*weight))).x/8.0;
					}
				#endif


				#ifndef PCF
				projectedShadowPosition.z -= diffthresh;
				shading = shadow2D(shadow,vec3(projectedShadowPosition)).x;

				#endif

				direct *= shading;
			}

		}

    vec3 lightmap = texture2D(gaux1,lmtexcoord.zw).xyz;

  	direct *= diffuseSun*normalMat.y+normalMat.z;


  	vec3 diffuseLight = direct + lightmap;

  	vec3 color = diffuseLight*albedo;

		if (iswater > 0.0){
		float f0 = 0.02;

		float roughness = 0.05;
		if (iswater > 0.9) roughness=0.05;

		float emissive = 0.0;
		float F0 = f0;

				vec3 reflectedVector = reflect(normalize(fragpos), normal);
				float normalDotEye = dot(normal, normalize(fragpos));
				float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 5.0) ;
				fresnel = fresnel+F0*(1.0-fresnel);

				float sunSpec = GGX(normal,-normalize(fragpos),  lightCol.a*sunVec, roughness, f0+0.05,lightCol.a>0.0? 0.035 : 0.065)*0.0005;


				vec3 wrefl = mat3(gbufferModelViewInverse)*reflectedVector;
				vec3 sky_c = cloud2D(wrefl,getSkyColorLut(wrefl,mat3(gbufferModelViewInverse)*sunVec,wrefl.y,gaux1))*normalMat.y*32.5/255.;


				vec3 reflected= sky_c*fresnel*10.+10.*shading*sunSpec* lightCol.rgb;

				float alpha0 = gl_FragData[0].a;

		//correct alpha channel with fresnel
		gl_FragData[0].a = -gl_FragData[0].a*fresnel+gl_FragData[0].a+fresnel;
		gl_FragData[0].rgb = color/gl_FragData[0].a*alpha0*(1.0-fresnel)+reflected/gl_FragData[0].a;
		if (gl_FragData[0].r > 65000.) gl_FragData[0].rgba = vec4(0.);
		}
		else
		gl_FragData[0].rgb = color;

}
