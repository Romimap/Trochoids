shader_type spatial;

#include "phasor.gdshaderinc"

uniform float waveLength : hint_range(0.1, 10.0, 0.001) = 1.0;

// Etalement de la direction des vagues
uniform float waveDirectionMax : hint_range(0.0, 6.14, 0.01) = 0.0;
uniform float waveDirectionMin : hint_range(0.0, 6.14, 0.01) = 0.0;

uniform float waveAmplitude : hint_range(0.0, 1.0, 0.01) = 0.5;

// paramètres phasor 
uniform int nb_kernel = 100;
uniform float kernel_size = 0.15;

// Paramètre de la fonctio Rho
uniform float useAttenuation : hint_range(0.0, 1.0, 1.0) = 0;
uniform float attenuation : hint_range(0.0, 8.0, 0.1) = 6.0;

// Ajustement de la vitesse du temps
uniform float timefactor : hint_range(0.0, 1.0, 0.01) = 1.0;

// Méthode de rendu : 
// 0 : grille, 
// 1 : hauteur (plus haut => plus rouge),
// 2 : variation de la hauteur (variation négative => plus vert, variation positive => plus bleu)
uniform int rendermode = 0;

// Nombre de point echantillonne pour un motif de la trochoide
// /!\ Doit être aussi ajuste dans le script de generation du tableau (computed.gd)
const int npoint = 1024;
// Table du profil de la trochoide lookuptable[abscisse] = hauteur de la trochoide à l'abscisse donnee
uniform float[npoint] lookuptable;

// Stockage des hauteurs pour le calcul de la variation de hauteur
varying float currHeight;
varying float lastHeight;

float interp(float a, float b, float t)
{
	return (b - a) * t + a;
}

float fmod(float a, float b)
{
	return a - floor(a / b) * b;
}

// Fonction d'atténuation lorsque g est proche de zéro en norme
float rho(vec2 g)
{
	return 2.0 / PI * atan(attenuation * length(g));
}

// Evaluation du profil de trochoide dans l'intervalle [0.0, 2.0 * PI] modulo 2.0 * PI
float trochoid(float theta)
{
	return lookuptable[int(fmod(theta / (2.0 * PI), 1.0) * float(npoint))];
}

float waveHeightPhasor(vec3 abc, vec2 uv, float time, float lambda, float amplitude, float directionMin, float directionMax)
{
	float k = 2.0 * PI / lambda;
	float omega = sqrt(9.8 * 2.0 * PI / lambda);
	
	vec2 noise = Gabor_noise(uv, nb_kernel, k, k, directionMin, directionMax, 0.258, kernel_size);
	
	// Pour atténuer les point d'ambiguité, on multiplie la hauteur par la fonction rho si useAttenuation vaut 1.0
	float heightMultiplier = (rho(noise) - 1.0) * useAttenuation + 1.0;
	
	return amplitude * heightMultiplier * trochoid(phasor(noise.x, noise.y) - omega * time);
}

void vertex () {
	vec3 v = VERTEX;
	lastHeight = currHeight;
	currHeight = waveHeightPhasor(v, UV, TIME, waveLength, waveAmplitude, waveDirectionMin, waveDirectionMax);
	v.y = currHeight;
	VERTEX = v;
}

void fragment() 
{
	// Dessine une grille à la surface
	if(rendermode == 0)
	{
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
	// Attribution des couleurs en fonction de la hauteur
	else if(rendermode == 1)
	{
		// Les hauteurs peuvent être négative on les ramène entre 0.0 et 1.0
		float normalizedheight = (currHeight + waveAmplitude) / 2.0;
		ALBEDO = vec3(normalizedheight, 0.0, 0.0);
	}
	// Attribution des couleurs en fonction de la variation de hauteur de la vertice
	else if(rendermode == 2)
	{
		float deltaHeight = lastHeight - currHeight;
		ALBEDO = vec3(0.0, 0.2 * waveAmplitude * deltaHeight * step(0.0, deltaHeight), - 0.2 * waveAmplitude * deltaHeight * step(0.0, - deltaHeight));
	}
}
