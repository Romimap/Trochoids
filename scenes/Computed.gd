@tool
extends MeshInstance3D

var n_points = 1024

func lerp(a:float, b:float, t:float):
	return (b - a) * t + a

func inverse_lerp(min:float, max:float,t:float):
	return (t - min) / (max - min)

func inverse_lerp_array(arr):
	var min = arr[0].x
	var max = arr[arr.size() - 1].x
	
	var inverse_lerp_arr = []
	for v in arr:
		v.x = inverse_lerp(min, max, v.x)
		inverse_lerp_arr.append(v)
	return inverse_lerp_arr
	
func trocho(cx, cy, r, x):
	return Vector2(
		cx + r * sin(x),
		cy - r * cos(x)
	);

# Return resampled trochoid height so that points are equally spaced
func resample_trochoid_coords(coords, N):
	var Z_resampled = []
	Z_resampled.resize(N)

	for i in range(N):
		var j_min = 0
		var min_dist = 2.0 * PI
		
		var x = 2.0 * PI * i / N
		
		var j_interp_min
		var j_interp_max
		
		for j in range(N):
			var candidate_dist = abs(x - coords[j].x)
			
			if candidate_dist < min_dist:
				j_min = j
				min_dist = candidate_dist
				
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
	
	# 257 = 256 + 1 bc we want to be able to interpolate the last point
	for i in range(n_points + 1):
		coords += [trocho(2.0 * i * PI / n_points, 0.0, 0.5, 2.0 * PI * i / n_points)]
	var resampled_coords = resample_trochoid_coords(coords, n_points)
	print(resampled_coords)
	self.material_override.set_shader_parameter("lookuptable", resampled_coords)
