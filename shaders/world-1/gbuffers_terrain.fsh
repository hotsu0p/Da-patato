#version 120



varying vec4 color;

varying vec2 texcoord;




uniform sampler2D texture;


vec3 toLinear(vec3 sRGB){
return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}


void main() {
	vec4 albedo = texture2D(texture,texcoord);
    albedo.rgb = color.rgb*toLinear(albedo.rgb)*0.5*170.*color.a*color.a*color.a;	//don't export to gamma 1/2.2 due to RGB11F format
/* DRAWBUFFERS:1 */
	gl_FragData[0] = albedo;
}