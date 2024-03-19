#version 120



varying vec4 color;
varying vec2 texcoord;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
//////////////////////////////VOID MAIN//////////////////////////////
	const vec2[8] offsets = vec2[8](vec2(1./8.,-3./8.),
									vec2(-1.,3.)/8.,
									vec2(5.0,1.)/8.,
									vec2(-3,-5.)/8.,
									vec2(-5.,5.)/8.,
									vec2(-7.,-1.)/8.,
									vec2(3,7.)/8.,
									vec2(7.,-7.)/8.);
void main() {


	texcoord = (gl_MultiTexCoord0).xy;
	color = gl_Color;

	gl_Position = ftransform();

	int frame = int(mod(frameCounter*1.0,8.));

	vec2 offset = offsets[frame];

	vec2 jitter = offset/vec2(viewWidth,viewHeight);

	gl_Position.xy += jitter * gl_Position.w;

}