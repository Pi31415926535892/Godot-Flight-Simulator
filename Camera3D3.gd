extends Camera3D

@onready var plane = get_parent().get_parent()  # Adjust path to match your tree

func _process(_delta):
	global_transform.origin = plane.global_transform.origin + Vector3(0, 50, 0)
	look_at(plane.global_transform.origin, Vector3.FORWARD)
