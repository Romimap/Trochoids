shader_type spatial;

uniform float height : hint_range(-2.0, 0.0, 0.001) = -0.05;
uniform float wavelength : hint_range(0.1, 5.0, 0.001) = 1.0;
uniform float direction : hint_range(0.0, 6.2831, 0.001) = 0.0;

//See https://www.geogebra.org/calculator/ctyaxuma
vec3 addWave(vec3 v, float time, float theta, float lambda, float steepness) {
	vec2 d = vec2(cos(theta), sin(theta));
	float a = dot(d, v.xz);
	float b = v.y;

	float k = 2.0 * PI / lambda;
	float c = sqrt(9.8 / k);

	return vec3(
		0,
		(exp(k * b) / k) * (pow(cos(k * (a + c * time)) * 0.5 + 0.5, steepness) * 2.0 - 1.0), 
		0
	);
}

void vertex () {
	vec3 v = VERTEX;
	v.y = height;
	v += addWave(v, TIME, direction, wavelength, 2.0);
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