shader_type canvas_item;

// CONSTANTE -----------------------------
#define _PI_ 3.14159265358979

// ---- tools -------------------------------------
float rndi(int i, int j, float seed)
{
	//return fract(1e5*sin(float(i)+3.*float(j)+seed)); // 0.567
	return fract(sin(float(i)+9876.*float(j))*(12345.+seed) + cos(float(i)+6789.*float(j))*(12345.-seed));
}

float gaussian(float x, float size){
	return exp(-(x*x)/(2.*size*size));
}

// ---- gabor noise -------------------------------------
vec2 gabor(vec2 position, vec2 offset, vec2 direction, float freq, float kernel_size)
{
	// cloche gaussienne
	float gauss = gaussian((position-offset).x, kernel_size)*gaussian((position-offset).y, kernel_size);
	
	// sinusoides complexe
	float cosinus = cos(2.*_PI_*freq*dot((position-offset), direction)); // partie réel
	float sinus = sin(2.*_PI_*freq*dot((position-offset), direction)); // partie imaginaire
	
	// dérivation complexe
	vec2 d_cos = (offset-position)/(kernel_size*kernel_size) * cosinus - 2.*_PI_*freq*direction * sinus; // partie réel
	vec2 d_sin = (offset-position)/(kernel_size*kernel_size) * sinus + 2.*_PI_*freq*direction * cosinus; // partie imaginaire
	
	return gauss*vec2(sinus, cosinus);// vec3(sinus, d_sin);
}

vec2 Gabor_noise(vec2 uv, int nb_kernel, float freq_min, float freq_max, float omega_min, float omega_max, float seed, float kernel_size)
{
	vec2 noises= vec2(0.);
	
	for (int i=0; i<nb_kernel; i++) 
	{
		float Omega = omega_min + (omega_max-omega_min)*rndi(i, 2, seed);
		float Freq = freq_min + (freq_max-freq_min)*rndi(i, 4, seed);
		
		vec2 pos = vec2(rndi(i,0, seed),rndi(i,1, seed));
		vec2 dir = vec2(cos(Omega), sin(Omega));
		
		vec2 gabor_noise = gabor(uv, pos, dir, Freq, kernel_size);
		
		noises += gabor_noise;
	}
	
	return noises;
}

float phasor(float x, float y)
{
	return atan(y, x);
}

void fragment() {
	int nb_kernel = 100;
	float size_kernel = 0.08;
	
	vec2 noise = Gabor_noise(UV, nb_kernel, 12., 12., 0., PI/2., 0.248, size_kernel)+0.5;
	COLOR = vec4(phasor(noise.x, noise.y));
}
