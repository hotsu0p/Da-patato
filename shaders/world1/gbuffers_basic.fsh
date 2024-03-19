#version 120



varying vec4 color;





void main(){



/* DRAWBUFFERS:1 */
	gl_FragData[0] = color;
}