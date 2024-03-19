#version 120
#extension GL_EXT_gpu_shader4 : enable



varying vec4 lmtexcoord;
varying vec4 color;
varying vec4 normalMat;
#ifdef MC_NORMAL_MAP
varying vec4 tangent;
attribute vec4 at_tangent;
#endif

attribute vec4 mc_Entity;
uniform vec2 texelSize;
uniform vec3 sunVec;
uniform vec4 lightCol;
uniform vec3 upVec;
uniform float sunElevation;


void main() {
	lmtexcoord.xy = gl_MultiTexCoord0.xy;
	vec3 normal = normalize(gl_NormalMatrix *gl_Normal);

	float NdotL = dot(normal,sunVec)*lightCol.a;
	float NdotU = dot(normal,upVec)*(0.17*15.5/255.)+(0.83*15.5/255.);

	lmtexcoord.zw = (gl_MultiTexCoord1.xy*vec2(15.5/255.0,NdotU)+0.5)*texelSize;

	gl_Position = ftransform();
	color = gl_Color;
	float bouncedSunlight = (abs(NdotL)*0.00002448837)*(gl_MultiTexCoord1.y*gl_MultiTexCoord1.y)*(abs(sunElevation));

	#ifdef MC_NORMAL_MAP
		tangent = vec4(normalize(gl_NormalMatrix *at_tangent.rgb),at_tangent.w);
	#endif

	normalMat = vec4(NdotL,gl_MultiTexCoord1.y/32.5,bouncedSunlight,0.0);

}
