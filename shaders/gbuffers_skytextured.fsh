#version 120



/* DRAWBUFFERS:1 */

varying vec4 color;
varying vec2 texcoord;
//faster and actually more precise than pow 2.2
vec3 toLinear(vec3 sRGB){
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}

uniform sampler2D texture;
void main() {

	gl_FragData[0] = texture2D(texture,texcoord.xy)*color*1.8;
	gl_FragData[0].rgb = toLinear(gl_FragData[0].rgb);
}
