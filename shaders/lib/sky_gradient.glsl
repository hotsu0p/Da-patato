#define DRAW_SUN //if not using custom sky
#define SKY_BRIGHTNESS_DAY 1.0 //[0.0 0.5 0.75 1. 1.2 1.4 1.6 1.8 2.0]
#define SKY_BRIGHTNESS_NIGHT 1.0 //[0.0 0.5 0.75 1. 1.2 1.4 1.6 1.8 2.0]

vec3 drawSun(float cosY, float sunInt,vec3 nsunlight,vec3 inColor){
	#ifdef DRAW_SUN
	cosY=clamp(cosY,0.,1.0);
	return inColor+nsunlight*10000.*sunInt*pow(clamp(cosY*cosY+0.0004,0.0,1.0),9000.)*(1.0-rainStrength*0.999);
	#endif
	#ifndef DRAW_SUN
	return vec3(0.);
	#endif
}

float fastAcos(float inX)
{
	const float PI = 3.14159265359;
	const float C0 = 1.56467;
	const float C1 = -0.155972;

    float x = abs(inX);
    float res = C1 * x + C0;
    res *= sqrt(1.0f - x);

    return (inX >= 0) ? res : PI - res;
}

const float pi = 3.141592653589793238462643383279502884197169;
vec3 getSkyColor(vec3 sVector, vec3 sunVec,float cosT) {
	const vec3 moonlight = vec3(0.8, 1.1, 1.4) * 0.06;

	float mCosT = clamp(cosT,0.0,1.);
	float cosY = dot(sunVec,sVector);
	float Y = fastAcos(cosY);

	const float a = -1.1;
	const float b = -0.3;
	const float c = 7.0;
	const float d = -4.;
	const float e = 0.45;

	//luminance (cie model)
	float L0 = (1.0+a*exp(b/mCosT))*(1.0+c*(exp(d*Y)-exp(d*3.1415/2.))+e*cosY*cosY);
	float L0Moon = (1.0+a*exp(b/mCosT))*(1.0+c*(exp(d*(pi-Y))-exp(d*3.1415/2.))+e*cosY*cosY);
	vec3 skyColor0 = mix(vec3(0.07,0.4,1.)/1.5,vec3(0.4,0.5,0.6)/1.5,rainStrength);
	vec3 normalizedSunColor = nsunColor;

	vec3 skyColor = mix(skyColor0,normalizedSunColor,1.0-pow(1.0+L0,-1.2))*(1.0-rainStrength*0.5);
	return pow(L0,1.0-rainStrength*0.5)*skyIntensity*skyColor*vec3(0.8,0.9,1.)*20.*SKY_BRIGHTNESS_DAY + pow(L0Moon,1.0-rainStrength*0.5)*skyIntensityNight*vec3(0.9,1.2,1.5)*vec3(0.01)*SKY_BRIGHTNESS_NIGHT;


}

vec3 getSkyColorLut(vec3 sVector, vec3 sunVec,float cosT,sampler2D lut) {
	const vec3 moonlight = vec3(0.8, 1.1, 1.4) * 0.06;

	float mCosT = clamp(cosT,0.0,1.);
	float cosY = dot(sunVec,sVector);

	float x = (cosY*0.5*256.+0.5*256.+18.+0.5)*texelSize.x;
	float y = (mCosT*256.+1.0+0.5)*texelSize.y;

	return texture2D(lut,vec2(x,y)).rgb;


}
