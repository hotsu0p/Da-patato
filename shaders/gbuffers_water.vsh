#version 120
#extension GL_EXT_gpu_shader4 : enable


varying vec4 lmtexcoord;
varying vec4 color;
 varying vec4 normalMat;
varying vec3 binormal;
varying vec3 tangent;
varying vec3 normalR;
uniform mat4 gbufferModelViewInverse;
uniform vec4 lightCol;
attribute vec4 at_tangent;
attribute vec4 mc_Entity;
uniform vec2 texelSize;
uniform vec3 sunVec;
uniform float sunElevation;
uniform vec3 upVec;
#define SHADOW_MAP_BIAS 0.8





void main() {
  lmtexcoord.xy = gl_MultiTexCoord0.xy;
	normalR = normalize(gl_NormalMatrix *gl_Normal);
  tangent = normalize( gl_NormalMatrix *at_tangent.rgb);
	binormal = normalize(cross(tangent.rgb,normalR.xyz)*at_tangent.w);

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normalR.x,
								  tangent.y, binormal.y, normalR.y,
						     	  tangent.z, binormal.z, normalR.z);


  float mat = 0.0;
  if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) mat = 1.0;


  if(mc_Entity.x == 79.0) mat = 0.5;
  if (mc_Entity.x == 10002) mat = 0.1;
	  if (mc_Entity.x == 10003.0) mat = .5;
	float NdotL = dot(normalR,sunVec)*lightCol.a;
	float NdotU = dot(normalR,upVec)*(0.17*15.5/255.)+(0.83*15.5/255.);

	lmtexcoord.zw = (gl_MultiTexCoord1.xy*vec2(15.5/255.0,NdotU)+0.5)*texelSize;

	gl_Position = ftransform();
	color = gl_Color;
	float bouncedSunlight = (abs(NdotL)*0.00002448837)*(gl_MultiTexCoord1.y*gl_MultiTexCoord1.y)*(abs(sunElevation));


	normalMat = vec4(NdotL,gl_MultiTexCoord1.y/32.5,bouncedSunlight,mat);





}
