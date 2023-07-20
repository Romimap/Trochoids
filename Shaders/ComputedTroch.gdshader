shader_type spatial;

uniform float height : hint_range(-2.0, 0.0, 0.001) = -0.05;
uniform float wavelength : hint_range(0.1, 10.0, 0.001) = 1.0;
uniform float direction : hint_range(0.0, 6.2831, 0.001) = 0.0;

uniform float elapsedtime = 0;

const int npoint = 1024;
uniform float[npoint] lookuptable;


float interp(vec2 a, vec2 b, float x)
{
	return (a.x - x) / (a.x - b.x) * (b.y - a.y) + a.y;
}

float fmod(float a, float b)
{
	return a - floor(a / b) * b;
}

// Return the point resulting in the trochoid evaluation at theta
float getComputedTrochoidHeightFromPhase(float theta)
{
	return lookuptable[int(fmod(theta / (2.0 * PI), 1.0) * float(npoint))];
}

// Return coordinates of trochoid centered on abc
float waveHeight(vec3 abc, float time, float theta, float lambda)
{
	float k = 2.0 * PI / lambda;
	float omega = sqrt(k * 9.8);
	
	// * 2 bc to gain precision, trochoid were computed times 0.5
	return 2.0 * exp(k * abc.y) / k * getComputedTrochoidHeightFromPhase(k*dot(abc.xz, vec2(cos(theta), sin(theta))) - omega * time);
}

// Return the wave height by interpolating between two point on a trochoidal trajectory
//float waveHeightInterpolation(vec3 abc, float time, float theta, float lambda, float frequency) {
//	vec2 d = vec2(cos(theta), sin(theta));
//
//	float b = abc.y;
//	float k = 2.0 * PI / lambda;
//
//	vec3 offset =  pointsampling * vec3(d.x,0.0,d.y);
//
//	float interp1 = trochoidHeight(abc - offset, time, theta, lambda, frequency);
//	float interp2 = trochoidHeight(abc + offset, time, theta, lambda, frequency);
//
//	return interp(interp2, interp1, dot(d,abc.xz));
//}

void vertex () {
	vec3 v = VERTEX;
	v.y = height;
	v.y += waveHeight(v, TIME, direction, wavelength) + waveHeight(v, TIME, direction + PI / 4.0, wavelength / 2.0) + waveHeight(v, TIME, direction - PI / 2.0, wavelength / 2.0) + waveHeight(v, TIME, direction + PI / 4.0, wavelength / 2.0) + waveHeight(v, TIME, direction + 3.0 * PI / 2.0, wavelength / 1.5);

	VERTEX = v;
}

//Draw a grid on the surface
void fragment() {
	vec2 uv = UV * 32.0;
	uv = mod(uv, vec2(2.0)) - vec2(1.0);
	if (sign(uv.x) == sign(uv.y)) ALBEDO = vec3(1.0);
	else ALBEDO = vec3(0.8);
	
	uv = UV * 8.0;
	uv = mod(uv, vec2(2.0)) - vec2(1.0);
	if (sign(uv.x) == sign(uv.y)) ALBEDO *= vec3(0.5);
	
	uv = UV * 2.0;
	uv = mod(uv, vec2(2.0)) - vec2(1.0);
	if (sign(uv.x) == sign(uv.y)) ALBEDO *= vec3(0.2);
}
