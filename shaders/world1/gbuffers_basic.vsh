#version 120




varying vec4 color;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;

	const vec2[8] offsets = vec2[8](vec2(1./8.,-3./8.),
									vec2(-1.,3.)/8.,
									vec2(5.0,1.)/8.,
									vec2(-3,-5.)/8.,
									vec2(-5.,5.)/8.,
									vec2(-7.,-1.)/8.,
									vec2(3,7.)/8.,
									vec2(7.,-7.)/8.);


void main() {

	color = pow(gl_Color,vec4(2.2,2.2,2.2,1.));

	gl_Position = ftransform();


}