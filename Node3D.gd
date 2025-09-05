extends Node3D

@export var plane: Node3D
@export var distance := 30.0
@export var height := 10.0

func _process(delta):
	if plane == null:
		return

	# Step 1: Position camera behind and above the plane
	var forward = -plane.global_transform.basis.z.normalized()
	var target_position = plane.global_position - forward * distance + Vector3.UP * height
	global_position = target_position

	# Step 2: Face the same direction as the plane (but stay upright)
	global_transform.basis = Basis().looking_at(forward, Vector3.UP)

