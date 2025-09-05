extends MeshInstance3D

@export var ahead_color: Color = Color(0, 0.05, 0)   # Dark green
@export var behind_color: Color = Color(0.05, 0, 0)  # Dark red

var plane: Node3D

func _ready():
	plane = get_node("../../../../Plane")  # Adjust path if Plane is elsewhere
	
	# Give each duplicated light its own unique material
	var original_mat = get_active_material(0)
	if original_mat:
		var unique_mat: StandardMaterial3D = original_mat.duplicate()
		unique_mat.emission_enabled = true
		unique_mat.emission = behind_color  # default so it's not black
		set_surface_override_material(0, unique_mat)

func _process(delta):
	if not plane:
		return
	
	# Convert plane position to this light's local space
	var plane_local: Vector3 = to_local(plane.global_transform.origin)
	
	var mat = get_active_material(0)
	if mat is StandardMaterial3D:
		mat.emission = ahead_color if plane_local.z > 0.0 else behind_color


