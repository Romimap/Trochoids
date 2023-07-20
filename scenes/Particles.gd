@tool
extends MeshInstance3D

var lookuptable = []

func interpolate(a:float, b:float, t:float):
	return (b - a) * t + a

func trocho(x):
	return Vector2(
		sin(x),
		- cos(x)
	);
	
func resample_trochoid_coords(P, N:int):
	var Z_resampled = [0.0]
	Z_resampled.resize(N)

	for i in range(N):
		var j_min = 0
		var min_dist = 2*PI
		
		var j_interp_min = 0
		var j_interp_max = 0
		
		for j in range(N):
			var x = P[j].x
			var candidate_dist = abs(x - 2.0 * i * PI / N)
			if candidate_dist < min_dist:
				j_min = j
				min_dist = candidate_dist
		if 2.0 * i * PI / N < P[j_min].x:
			j_interp_min = j_min - 1
			j_interp_max = j_min
		else:
			j_interp_min = j_min
			j_interp_max = j_min + 1
		
		Z_resampled[i] = interpolate(P[j_interp_min].z, P[j_interp_max].z, (2.0 * i * PI / N - P[j_interp_min].x) / (P[j_interp_max].x - P[j_interp_min].x))

	return Z_resampled

func _ready():
	print("Computing Lookup Table")
	for i in range(256):
		lookuptable += [trocho(2 * PI * i / 256)]
	lookuptable = resample_trochoid_coords(lookuptable, 256)
	
	print("Sending Lookup Table to Shader")
	self.material_override.set_shader_parameter("lookuptable", lookuptable)
	print("Task ended")
