@tool
extends MeshInstance3D

var lookuptable = []

func trocho(x):
	return Vector2(
		sin(x),
		- cos(x)
	);

func _ready():
	for i in range(256):
		lookuptable += [trocho(2 * PI * i / 256)]
	
	self.material_override.set_shader_parameter("lookuptable", lookuptable)
