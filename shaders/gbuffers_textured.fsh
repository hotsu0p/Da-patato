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

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

//faster and actually more precise than pow 2.2
vec3 toLinear(vec3 sRGB){
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}

#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)
vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = p * 2. - 1.;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}
float interleaved_gradientNoise(){
	vec2 coord = gl_FragCoord.xy;
	float noise = fract(52.9829189*fract(0.06711056*coord.x + 0.00583715*coord.y));
	return noise;
}

#ifdef PCF
const vec2 shadowOffsets[8] = vec2[8](vec2( -0.7071,  0.7071 ),
vec2( -0.0000, -0.8750 ),
vec2(  0.5303,  0.5303 ),
vec2( -0.6250, -0.0000 ),
vec2(  0.3536, -0.3536 ),
vec2( -0.0000,  0.3750 ),
vec2( -0.1768, -0.1768 ),
vec2( 0.1250,  0.0000 ));
#endif
float facos(float sx){
    float x = clamp(abs( sx ),0.,1.);
    float a = sqrt( 1. - x ) * ( -0.16882 * x + 1.56734 );
    return sx > 0. ? a : 3.14159265359 - a;
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
	gl_FragData[0] = texture2D(texture, lmtexcoord.xy);
	if (gl_FragData[0].a  > 0.0) {
	vec3 albedo = toLinear(gl_FragData[0].rgb*color.rgb);
	vec3 fragpos = toScreenSpace(gl_FragCoord.xyz*vec3(texelSize,1.0));

	float NdotL = normalMat.x;
	float diffuseSun = 0.712;
	vec3 direct = lightCol.rgb;


		vec3 p3 = mat3(gbufferModelViewInverse) * fragpos + gbufferModelViewInverse[3].xyz;
		vec3 projectedShadowPosition = mat3(shadowModelView) * p3 + shadowModelView[3].xyz;
		projectedShadowPosition = diagonal3(shadowProjection) * projectedShadowPosition + shadowProjection[3].xyz;

		//apply distortion
		float distortFactor = calcDistort(projectedShadowPosition.xy);
		projectedShadowPosition.xy *= distortFactor;
		//do shadows only if on shadow map
		if (abs(projectedShadowPosition.x) < 1.0-1.5/shadowMapResolution && abs(projectedShadowPosition.y) < 1.0-1.5/shadowMapResolution){
			const float sr = 1024./shadowMapResolution;
			float diffthresh = 0.0002;

			projectedShadowPosition = projectedShadowPosition * vec3(0.5,0.5,0.5/3.0) + vec3(0.5,0.5,0.5);

			#ifdef PCF
				float shading = 0.0;
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
				float shading = shadow2D(shadow,vec3(projectedShadowPosition)).x;

			#endif

			diffuseSun *= shading;
		}


	vec3 lightmap = texture2D(gaux1,lmtexcoord.zw).xyz;

	direct *= diffuseSun*normalMat.y+normalMat.z;


	vec3 diffuseLight = direct + lightmap;

	vec3 color = diffuseLight*albedo;


	gl_FragData[0].rgb = color;
}


}
