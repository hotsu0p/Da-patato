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




void main() {
	lmtexcoord.xy = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;

	vec2 lmcoord = gl_MultiTexCoord1.xy/255.;
	lmtexcoord.zw = lmcoord*lmcoord;

	gl_Position = ftransform();
	color = gl_Color;
	
	
	#ifdef MC_NORMAL_MAP
		tangent = vec4(normalize(gl_NormalMatrix *at_tangent.rgb),at_tangent.w);
	#endif

	normalMat = vec4((gl_NormalMatrix *gl_Normal),1.0);	

}