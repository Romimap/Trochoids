@tool
extends MeshInstance3D

# Taille de l'échantillon
var n_points = 1024

# Renvoie l'interpolation de t entre a et b, on transforme l'intervalle [0, 1] en [a, b] linéairement
func lerp(a:float, b:float, t:float):
	return (b - a) * t + a

# Renvoie l'interpolation inverse de t en sachant que min <= t <= max, on transforme l'intervalle [min, max] en [0, 1] linéairement
func inverse_lerp(min:float, max:float,t:float):
	return (t - min) / (max - min)

func trocho(cx, cy, r, x):
	return Vector2(
		cx + r * sin(x),
		cy - r * cos(x)
	);

# Retourne l'échantillonnage régulier de la trochoide par interpolation
func resample_trochoid_coords(coords, N):
	var Z_resampled = []
	Z_resampled.resize(N)
	
	# Pour chaque point d'abscisse x = 2.0 * PI * i / N
	for i in range(N):
		var j_min = 0
		var min_dist = 2.0 * PI
		
		# Abscisse du point actuel
		var x = 2.0 * PI * i / N
		
		# Contient le point qu'on utilise pour interpoler et qui est à la gauche de x
		var j_interp_min
		# Contient le point qu'on utilise pour interpoler et qui est à la droite de x
		var j_interp_max
		
		# Pour tous les points où la hauteur de la trochoïde est connue
		for j in range(N):
			# On cherche le point de la trochoïde dont l'absisse est la plus proche de x
			var candidate_dist = abs(x - coords[j].x)
			
			if candidate_dist < min_dist:
				j_min = j
				min_dist = candidate_dist
		
		# En fonction de la position du point d'abscisse coords[j_min].x, on change l'intervalle sur lequel on interpole
		if x < coords[j_min].x:
			j_interp_min = j_min - 1
			j_interp_max = j_min
		else:
			j_interp_min = j_min
			j_interp_max = j_min + 1
			
		Z_resampled[i] = lerp(coords[j_interp_min].y, coords[j_interp_max].y, inverse_lerp(coords[j_interp_min].x, coords[j_interp_max].x, x))
	
	return Z_resampled
	
func _init():
	upload_lookup_table()

func upload_lookup_table():
	print("Computing Lookup Table")
	var coords = []
	
	# n_points + 1 pour pouvoir interpoler le dernier point
	for i in range(n_points + 1):
		# Pour éviter les problèmes d'échantillonnage, il est preferable de prendre r = 0.5
		coords += [trocho(2.0 * i * PI / n_points, 0.0, 0.5, 2.0 * PI * i / n_points)]
	var resampled_coords = resample_trochoid_coords(coords, n_points)
	# Envoie des coordonnées au shader
	self.material_override.set_shader_parameter("lookuptable", resampled_coords)
	print("Lookuptable sent to shader")
