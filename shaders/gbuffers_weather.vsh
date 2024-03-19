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
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
const float PI48 = 150.796447372;
float pi2wt = PI48*frameTimeCounter*10.;




void main() {
	lmtexcoord.xy = gl_MultiTexCoord0.xy;
	vec3 normal = normalize(gl_NormalMatrix *gl_Normal);

	float NdotL = dot(normal,sunVec)*lightCol.a;
	float NdotU = dot(normal,upVec)*(0.17*15.5/255.)+(0.83*15.5/255.);

	lmtexcoord.zw = (gl_MultiTexCoord1.xy*vec2(15.5/255.0,NdotU)+0.5)*texelSize;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
		vec3 worldpos = position.xyz + cameraPosition;
		bool istopv = worldpos.y > cameraPosition.y+5.0;
		float ft = frameTimeCounter*1.3;
	if (!istopv) position.xz += vec2(3.0,1.0)+sin(ft)*sin(ft)*sin(ft)*vec2(2.1,0.6);
	position.xz -= (vec2(3.0,1.0)+sin(ft)*sin(ft)*sin(ft)*vec2(2.1,0.6))*0.5;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	color = gl_Color;
	float bouncedSunlight = (abs(NdotL)*0.00002448837)*(gl_MultiTexCoord1.y*gl_MultiTexCoord1.y)*(abs(sunElevation));

	#ifdef MC_NORMAL_MAP
		tangent = vec4(normalize(gl_NormalMatrix *at_tangent.rgb),at_tangent.w);
	#endif

	normalMat = vec4(NdotL,gl_MultiTexCoord1.y/32.5,bouncedSunlight,0.0);

}
