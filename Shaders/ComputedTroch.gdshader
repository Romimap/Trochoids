shader_type spatial;

#include "res://Shaders/phasor.gdshaderinc"

uniform float height : hint_range(-2.0, 0.0, 0.001) = -0.05;
uniform float wavelength : hint_range(0.1, 10.0, 0.001) = 1.0;
uniform float direction : hint_range(0.0, 6.2831, 0.001) = 0.0;

// Interpolation
// Distance entre les points interp1 et interp2 et le point qu'on souhait évaluer dans la fonction waveHeightInterpolation
uniform float pointsampling : hint_range(0.01, 0.2, 0.01) = 0.01;

// Nombre de point echantillonne pour un motif de la trochoide
// /!\ Doit être aussi ajuste dans le script de generation du tableau (computed.gd)
const int npoint = 1024;
// Table du profil de la trochoide lookuptable[abscisse] = hauteur de la trochoide à l'abscisse donnee
uniform float[npoint] lookuptable;

float interp(float a, float b, float t)
{
	return (b - a) * t + a;
}

float fmod(float a, float b)
{
	return a - floor(a / b) * b;
}

// Evaluation de la trochoide
float trochoid(float theta)
{
	return lookuptable[int(fmod(theta / (2.0 * PI), 1.0) * float(npoint))];
}

// Hauteur de vague du point le plus proche
float waveHeight(vec3 abc, float time, float theta, float lambda)
{
	float k = 2.0 * PI / lambda;
	float omega = sqrt(k * 9.8);
	
	return exp(k * abc.y) / k * trochoid(k*dot(abc.xz, vec2(cos(theta), sin(theta))) - omega * time);
}

// Hauteur de vague en interpolant la position entre deux points où la hauteur de la trochoïde est connue
float waveHeightInterpolation(vec3 abc, float time, float theta, float lambda) {
	vec2 d = vec2(cos(theta), sin(theta));

	float b = abc.y;
	float k = 2.0 * PI / lambda;

	vec3 offset =  pointsampling * vec3(d.x,0.0,d.y);

	float interp1 = waveHeight(abc - offset, time, theta, lambda);
	float interp2 = waveHeight(abc + offset, time, theta, lambda);

	return interp(interp1, interp2, dot(d,abc.xz));
}

void vertex () {
	vec3 v = VERTEX;
	v.y += waveHeightInterpolation(v, TIME, direction, wavelength);
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
