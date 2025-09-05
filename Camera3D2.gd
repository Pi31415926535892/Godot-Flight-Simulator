extends Camera3D

@onready var plane = get_parent().get_parent()  # Adjust if camera is deeper/nested

func _process(_delta):
	# Position camera at tail, slightly above and behind
	var tail_offset = Vector3(0, 0.6, 4.0)  # X = side, Y = up, Z = back
	global_transform.origin = plane.global_transform.origin + plane.transform.basis * Vector3(tail_offset)

	# Look toward landing gear (slightly below and forward)
	var gear_focus = plane.global_transform.origin + plane.transform.basis * Vector3(Vector3(0, -0.5, 0.5))
	look_at(gear_focus, Vector3.UP)
