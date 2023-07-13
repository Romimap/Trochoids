shader_type spatial;

uniform float height : hint_range(-2.0, 0.0, 0.001) = -0.05;
uniform float wavelength : hint_range(0.1, 5.0, 0.001) = 1.0;
uniform float wavefrequency : hint_range(0.1, 5.0, 0.001) = 0.1;
uniform float direction : hint_range(0.0, 6.2831, 0.001) = 0.0;
uniform float pointsampling : hint_range(0.1, 2.0, 0.01) = 0.5;
uniform bool moveXZ = true;

uniform vec2[256] lookuptable;

// -------- Maths Methods -----------

float interp(vec2 a, vec2 b, float x)
{
	return (a.x - x) / (a.x - b.x) * (b.y - a.y) + a.y;
}

float fmod(float a, float b)
{
	return a - floor(a / b) * b;
}

// -------- Trochoid computation ethods --------

// Return the point resulting in the trochoid evaluation at theta
vec2 get2DComputedTrochoidFromPhase(float theta)
{
	return lookuptable[int(fmod(theta / (2.0 * PI), 1.0) * 256.0)];
}

// Return offset of trochoid centered on abc
vec2 trochoidoffset(vec3 abc, float time, float theta, float lambda, float frequency)
{
	vec2 d = vec2(cos(theta), sin(theta));
	
	float k = 2.0 * PI / lambda;
	float omega = 2.0 * PI * frequency;
	
	float x = dot(abc.xz,d);
	float b = abc.y;
	
	vec2 troch = get2DComputedTrochoidFromPhase(k * x - omega * time);
	
	return vec2(
		(exp(k * b) / k) * troch.x,
		- (exp(k * b) / k) * troch.y
	);
}

// Return coordinates of trochoid centered on abc
vec2 trochoid(vec3 abc, float time, float theta, float lambda, float frequency)
{
	vec2 trocho = trochoidoffset(abc, time, theta, lambda, frequency);
	
	return trocho + vec2(abc.x * cos(theta) + abc.z * sin(theta), abc.y);
}

//see https://en.wikipedia.org/wiki/Trochoidal_wave
//abc are the lagrangian coordinates (xyz0)
//time the time
//theta the direction
//lambda the wavelength
//returns an offset.
vec3 addWave(vec3 abc, float time, float theta, float lambda) {
	vec2 d = vec2(cos(theta), sin(theta));
	float a = dot(d, abc.xz);
	float b = abc.y;
	float k = 2.0 * PI / lambda;
	float c = sqrt(9.8 / k);
	
	vec2 troch = get2DComputedTrochoidFromPhase(k * (a + c * time));

	return vec3(
		d.x * (exp(k * b) / k) * troch.x,
		(exp(k * b) / k) * troch.y,
		d.y * (exp(k * b) / k) * troch.x
	);
}

vec3 addWaveNewMethod(vec3 abc, float time, float theta, float lambda, float frequency) {
	
	vec2 trocho =  trochoidoffset(abc, time, theta, lambda, frequency);
	
	return vec3(
		cos(theta) * trocho.x,
		trocho.y,
		sin(theta) * trocho.x
	);
}

// Return the height of a wave at given coordinates
float waveHeight(vec3 abc, float time, float theta, float lambda, float frequency) {
	vec2 d = vec2(cos(theta), sin(theta));
	float a = dot(d, abc.xz);
	float b = abc.y;
	float k = 2.0 * PI / lambda;
	float c = sqrt(9.8 / k);

	return trochoid(abc, time, theta, lambda, frequency).y;
}

// Return the wave height by interpolating between two point on a trochoidal trajectory
float waveHeightInterpolation(vec3 abc, float time, float theta, float lambda, float frequency) {
	vec2 d = vec2(cos(theta), sin(theta));
	
	float b = abc.y;
	float k = 2.0 * PI / lambda;
	
	vec3 offset =  pointsampling * vec3(d.x,0.0,d.y);

	vec2 interp1 = trochoid(abc - offset, time, theta, lambda, frequency);
	vec2 interp2 = trochoid(abc + offset, time, theta, lambda, frequency);
	
	return interp(interp2, interp1, dot(d,abc.xz));
}

void vertex () {
	vec3 v = VERTEX;
	v.y = height;
	if(!moveXZ)
		v.y += waveHeightInterpolation(v, TIME, direction, wavelength, wavefrequency);
	else
		v += addWave(v, TIME, direction, wavelength);
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
