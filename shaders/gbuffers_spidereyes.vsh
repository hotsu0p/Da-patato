#version 120
#define TAA



varying vec4 color;
varying vec2 texcoord;


void main() {


	texcoord = (gl_MultiTexCoord0).xy;
	color = gl_Color;

	gl_Position = ftransform();

}
