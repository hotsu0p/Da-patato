#version 120




varying vec4 color;
varying vec2 texcoord;

uniform sampler2D texture;



void main() {
	vec4 albedo = texture2D(texture, texcoord);

	albedo *= color;

/* DRAWBUFFERS:1 */
	gl_FragData[0] = albedo;
	
}