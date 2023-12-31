shader_type spatial;

uniform float height : hint_range(-2.0, 0.0, 0.001) = -0.05;
uniform float wavelength : hint_range(0.1, 10.0, 0.001) = 1.0;

uniform float direction : hint_range(0.0, 6.2831, 0.001) = 0.0;
uniform float pointsampling : hint_range(0.1, 2.0, 0.01) = 0.5;
uniform bool useinterpolation = true;

float interp(vec2 a, vec2 b, float x)
{
	return (a.x - x) / (a.x - b.x) * (b.y - a.y) + a.y;
}

// Return offset of trochoid centered on abc
vec2 trochoidoffset(vec3 abc, float time, float theta, float lambda)
{
	vec2 d = vec2(cos(theta), sin(theta));
	
	float k = 2.0 * PI / lambda;
	float omega = sqrt(k * 9.8);
	
	float x = dot(abc.xz,d);
	float b = abc.y;
	
	return vec2(
		(exp(k * b) / k) * sin(k * x - omega * time),
		- (exp(k * b) / k) * cos(k * x - omega * time)
	);
}

// Return coordinates of trochoid centered on abc
vec2 trochoid(vec3 abc, float time, float theta, float lambda)
{
	vec2 trocho = trochoidoffset(abc, time, theta, lambda);
	
	return trocho + vec2(abc.x * cos(theta) + abc.z * sin(theta), abc.y);
}

// Return the height of a wave at given coordinates
float waveHeight(vec3 abc, float time, float theta, float lambda) {
	vec2 d = vec2(cos(theta), sin(theta));
	float a = dot(d, abc.xz);
	float b = abc.y;
	float k = 2.0 * PI / lambda;
	float c = sqrt(9.8 / k);

	return trochoid(abc, time, theta, lambda).y;
}

// Return the wave height by interpolating between two point on a trochoidal trajectory
float waveHeightInterpolation(vec3 abc, float time, float theta, float lambda) {
	vec2 d = vec2(cos(theta), sin(theta));
	
	float b = abc.y;
	float k = 2.0 * PI / lambda;
	
	vec3 offset =  pointsampling * vec3(d.x,0.0,d.y);

	vec2 interp1 = trochoid(abc - offset, time, theta, lambda);
	vec2 interp2 = trochoid(abc + offset, time, theta, lambda);
	
	return interp(interp2, interp1, dot(d,abc.xz));
}

void vertex() {
	vec3 v = VERTEX;
	v.y = height;
	if(useinterpolation)
		v.y += waveHeightInterpolation(v, TIME, direction, wavelength);
	else
		v.y += waveHeight(v, TIME, direction, wavelength);
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