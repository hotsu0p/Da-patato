//faster and actually more precise than pow 2.2
vec3 toLinear(vec3 sRGB){
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float A = 0.2;
float B = 0.25;
float C = 0.10;
float D = 0.35;
float E = 0.02;
float F = 0.3;
vec3 Uncharted2Tonemap(vec3 x)
{
	x*= 4.;
   return pow(((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F,vec3(1.0/2.2));
}

vec3 reinhard(vec3 x){
x *= 1.66;
return pow(x/(1.0+x),vec3(1.0/2.2));
}

vec3 ACESFilm( vec3 x )
{

    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
	vec3 r = (x*(a*x+b))/(x*(c*x+d)+e);

    return pow(r,vec3(1.0/2.2,1./2.3,1./2.4));
}

vec3 invACESFilm( vec3 r )
{
	r = toLinear(r);
	return (0.00617284 - 0.121399*r - 0.00205761 *sqrt(9 + 13702*r - 10127*r*r))/(-1.03292 + r);
}
