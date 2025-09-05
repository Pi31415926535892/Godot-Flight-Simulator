extends RigidBody3D

var last_touchdown_fpm = 0.0
var previous_velocity = Vector3.ZERO
var acceleration = Vector3.ZERO

# --- CONTROL VARIABLES ---
var throttle := 0.0
var pitch_input := 0.0
var yaw_input := 0.0
var roll_input := 0.0

# --- PLANE CONSTANTS ---
const MASS := 620.0
const MAX_THRUST := 7300.0
const DRAG_COEFFICIENT := 0.0005
const AIR_DENSITY := 1.225
const WING_AREA := 16.2
const STALL_AOA := deg_to_rad(15.0)

# --- SETTINGS ---
var enable_auto_roll_stabilize := true
 
# --- NODES ---
@onready var propeller = $"cessna 150 NEW prop"
@onready var hud_label = $CanvasLayer/Label
@onready var left_ray = $Left
@onready var left_smoke = $nose_wheel2/Smoke
@onready var nose_ray = $Nose
@onready var nose_smoke = $nose_wheel/Smoke
@onready var right_ray = $Right
@onready var right_smoke = $nose_wheel3/Smoke
@onready var light1 = $Left_light
@onready var light2 = $Right_light
@onready var lightT = $Taxi_light
@onready var wheel_mesh_l = $Cessnagodotwheel3
@onready var wheel_mesh_r = $Cessnagodotwheel2
@onready var wheel_mesh_nose = $Cessnagodotwheel
@onready var wheel_col_l = $nose_wheel3
@onready var wheel_col_r = $nose_wheel2
@onready var wheel_col_nose = $nose_wheel
@onready var damagel_hardlanding = $cessnagodotnosegear
@onready var damagel_tailstrike = $cessnagodottail
@onready var damagel_overspeed_crash = [$cessnagodotnosegear, $cessnagodottail, $cessnagodotnose, $cessnagodotmiddle, $cessnagodotwing, $cessnagodotprop]
@onready var wheels = [$nose_wheel3/HingeJoint3D3, $nose_wheel2/HingeJoint3D2, $nose_wheel/HingeJoint3D]
@onready var flaps = $Flap_controll
@onready var elevator = $Elevator_controll
@onready var rudder = $Node3D/Rudder_controll

@onready var head = $Head
@onready var cam = $Head/Camera3D

# --- FLAPS ---
var flap_setting := 0  # 0 = clean, 1 = 10°, 2 = 20°...
const MAX_FLAPS := 4

const FLAP_LIFT_BOOST = [1.0, 1.15, 1.3, 1.4, 1.45]
const FLAP_DRAG_BOOST = [1.0, 1.2, 1.4, 1.8, 2.0]

var left_touched_last = false
var right_touched_last = false
var nose_touched_last = false
var n_speed = 0.0
var r_speed = 0.0
var l_speed = 0.0
var light_landing = false
var light_taxi = false

# --- HELPER ---
func is_on_ground() -> bool:
	return left_ray.is_colliding() or right_ray.is_colliding() or nose_ray.is_colliding()
	

# --- Realistic CL vs AoA curve ---
func get_cl_from_aoa(aoa_rad: float) -> float:
	var aoa_deg = rad_to_deg(aoa_rad)
	if aoa_deg < -15.0:
		return 0.0
	elif aoa_deg <= 15.0:
		return aoa_deg / 15.0 * 2.3
	else:
		return max(1.2 - (aoa_deg - 15.0) * 0.1, 0.0)
		
	
		
func update_wheel_y(mesh: Node3D, collider: Node3D):
	var mesh_pos = mesh.transform.origin
	var collider_y_local = to_local(collider.global_transform.origin).y
	mesh_pos.y = collider_y_local
	mesh.transform.origin = mesh_pos

# --- SETUP ---
func _ready():
	linear_damp = 0.2
	angular_damp = 3.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * 0.003)
		cam.rotate_x(-event.relative.y * 0.003)
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-40), deg_to_rad(60))

# --- THROTTLE + PROPELLER ---
func _process(delta):
	#print("Grounded")
	#print(is_on_ground())
	flaps.rotation_degrees.x = move_toward(flaps.rotation_degrees.x, flap_setting * 10, delta * 10)
	elevator.rotation_degrees.x = move_toward(elevator.rotation_degrees.x, pitch_input * -25, delta * 30)
	elevator.rotation_degrees.x = clamp(elevator.rotation_degrees.x, -15, 25)
	rudder.rotation_degrees.y = move_toward(rudder.rotation_degrees.y, yaw_input * -23, delta * 30)
	
	update_wheel_y(wheel_mesh_l, wheel_col_l)
	update_wheel_y(wheel_mesh_r, wheel_col_r)
	update_wheel_y(wheel_mesh_nose, wheel_col_nose)
	var throttle_rate = 0.5
	if Input.is_action_pressed("throttle_up"):
		throttle = clamp(throttle + throttle_rate * delta, 0.0, 1.0)
	if Input.is_action_pressed("throttle_down"):
		throttle = clamp(throttle - throttle_rate * delta, 0.0, 1.0)
	propeller.rotate_z((throttle * 250.0 + linear_velocity.length() * 0.2) * delta)

# --- INPUT ---
func _input(event):
	# Flap control
	if event.is_action_pressed("ui_down"):
		flap_setting = clamp(flap_setting + 1, 0, MAX_FLAPS)
	if event.is_action_pressed("ui_up"):
		flap_setting = clamp(flap_setting - 1, 0, MAX_FLAPS)

	# Flight controls (unchanged)
	pitch_input = int(Input.is_action_pressed("pitch_up")) - int(Input.is_action_pressed("pitch_down"))
	roll_input = int(Input.is_action_pressed("roll_right")) - int(Input.is_action_pressed("roll_left"))
	yaw_input = int(Input.is_action_pressed("yaw_right")) - int(Input.is_action_pressed("yaw_left"))
	
	# --- LIGHTS ---
	if event.is_action_pressed("Lights"):
		light_landing = !light_landing
	light1.visible = light_landing
	light2.visible = light_landing
	
	if event.is_action_pressed("Taxi_lights"):
		light_taxi = !light_taxi
	lightT.visible = light_taxi

# --- PHYSICS ---
func _physics_process(delta):
	acceleration = (linear_velocity - previous_velocity) / delta
	previous_velocity = linear_velocity
	#print("acceleration")
	print(acceleration.length() / 9.81)
	
	if linear_velocity.length() > 63.0:
		for part in damagel_overspeed_crash:
			#detach_visual_part(part)
			for wheel in wheels:
				if is_instance_valid(wheel):
					#wheel.queue_free()
					pass
		
	if linear_velocity.y < -5.0  and is_on_ground():
		#detach_visual_part(damagel_hardlanding)
		if is_instance_valid(wheels[2]):
				#wheels[2].queue_free()
				pass
		
	if linear_velocity.y < -8.0  and is_on_ground():
		for part in damagel_overspeed_crash:
			#detach_visual_part(part)
			for wheel in wheels:
				if is_instance_valid(wheel):
					#wheel.queue_free()
					pass
			
	var velocity = linear_velocity
	var speed = velocity.length()

	# --- TOUCHDOWN SMOKE ---
	if nose_ray.is_colliding() and speed - n_speed > 10:
		if not nose_touched_last:
			nose_smoke.restart()
			nose_smoke.emitting = true
			
			last_touchdown_fpm = round(linear_velocity.y * 196.85)
					
		nose_touched_last = true
	else:
		nose_touched_last = false

	if right_ray.is_colliding() and speed - r_speed > 10:
		if not right_touched_last:
			right_smoke.restart()
			right_smoke.emitting = true
		right_touched_last = true
	else:
		right_touched_last = false

	if left_ray.is_colliding() and speed - l_speed > 10:
		if not left_touched_last:
			left_smoke.restart()
			left_smoke.emitting = true
		left_touched_last = true
	else:
		left_touched_last = false

	if nose_ray.is_colliding(): n_speed = speed
	else: n_speed = move_toward(n_speed, 0.0, 5.0 * delta)

	if right_ray.is_colliding(): r_speed = speed
	else: r_speed = move_toward(r_speed, 0.0, 4.0 * delta)

	if left_ray.is_colliding(): l_speed = speed
	else: l_speed = move_toward(l_speed, 0.0, 4.0 * delta)

	# --- ORIENTATION VECTORS ---
	var forward = -transform.basis.z
	var up = transform.basis.y
	var right = transform.basis.x

	# --- THRUST ---
	apply_central_force(forward * throttle * MAX_THRUST / (int(FLAP_DRAG_BOOST[flap_setting]) ^ (1 / 2)))

	# --- GROUND FRICTION ---
	if is_on_ground() and speed > 0.1:
		apply_central_force(-velocity.normalized() * speed * 2.0)

	# --- GROUND STEERING ---
	if is_on_ground() and speed < 20.0:
		var steer_force = transform.basis.x * Input.get_axis("ui_left", "ui_right") * 3500.0
		var steer_point = global_transform.origin - transform.basis.z * 2.0
		apply_force(steer_force, steer_point - global_transform.origin)
		var brake_input = Input.get_action_strength("Wheel_brake")

		if brake_input > 0.0:
			# Local forward axis (+X in your setup)
			var forward_b = global_transform.basis.x.normalized()
			
			# Forward speed component
			var forward_speed = linear_velocity.dot(forward_b)
			
			if abs(forward_speed) > 0.1:
				# Apply brake force opposite to direction of motion
				var brake_force = -velocity * brake_input * 2000.0
				apply_central_force(brake_force)

	# === DRAG (includes flap-induced drag) ===
	if speed > 1.0:
		var drag = velocity.normalized() * (speed * speed) * (DRAG_COEFFICIENT * FLAP_DRAG_BOOST[flap_setting])
		apply_central_force(drag)
		#print("Drag")
		#print(drag.length())

	# --- LATERAL DRAG ---
	var side_speed = right.dot(velocity)
	if is_on_ground() and abs(side_speed) > 0.1:
		apply_central_force(-right * side_speed * 1500.0)
	else:
		apply_central_force(-right * side_speed * abs(side_speed) * 40.0)

	# --- ANGLE OF ATTACK + LIFT ---
	var forward_speed = forward.dot(velocity)
	var vertical_speed = up.dot(velocity)
	var aoa := 0.0
	if abs(forward_speed) > 0.1:
		aoa = atan2(-vertical_speed, forward_speed) + deg_to_rad(3.0)

	if speed > 10.0:
		var lift_coef = get_cl_from_aoa(aoa) * 0.50 * FLAP_LIFT_BOOST[flap_setting]
		var lift_force = 0.5 * AIR_DENSITY * forward_speed * forward_speed * lift_coef * WING_AREA
		apply_central_force(up * lift_force)

	# --- AERODYNAMIC STABILIZERS ---
	if speed > 5.0:
		apply_torque(right * -right.dot(angular_velocity) * abs(right.dot(angular_velocity)) * 400.0)
		apply_torque(up * -up.dot(angular_velocity) * abs(up.dot(angular_velocity)) * 500.0)
		apply_torque(forward * -forward.dot(angular_velocity) * abs(forward.dot(angular_velocity)) * 150.0)

	# --- AUTO RUDDER (air only) ---
	var adjusted_yaw_input = yaw_input
	if not is_on_ground():
		adjusted_yaw_input += roll_input * 0.2

	# --- CONTROL TORQUES ---
	var pitch_torque = right * pitch_input * 2500.0
	var yaw_torque = up * adjusted_yaw_input * 400.0
	var roll_torque = forward * -roll_input * 3000.0 + yaw_torque * 3
	apply_torque(pitch_torque + yaw_torque + roll_torque)

	# --- AUTO ROLL STABILIZE ---
	if enable_auto_roll_stabilize and roll_input == 0:
		apply_torque(forward * -angular_velocity.z * 500.0)

	# --- LIMIT MAX SPIN ---
	angular_velocity = angular_velocity.limit_length(100.0)

	# --- HUD ---
	var vsi = linear_velocity.y * 196.85  # Convert m/s to ft/min
	var pitch = rad_to_deg(rotation.x)  # In degrees

	hud_label.text = "Throttle: %d%%\nSpeed: %dkts\nAltitude: %dft\nFlaps: %d°\nPitch: %d°\nVSI: %d ft/min\nLast Touchdown: %d ft/min" % [
		int(throttle * 100),
		round(speed * 1.94384),
		round(global_position.y * 3.2808) - 2,
		flap_setting * 10,
		round(pitch),
		round(vsi),
		round(last_touchdown_fpm)
	]

# --- DEBRIS BREAKUP ---
func detach_visual_part(part: Node3D):
	var debris = RigidBody3D.new()
	debris.global_transform = part.global_transform
	debris.mass = 5.0
	get_tree().current_scene.add_child(debris)

	var mesh_copy = part.duplicate()
	debris.add_child(mesh_copy)

	debris.linear_velocity = linear_velocity + Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 30.0
	debris.angular_velocity = Vector3(randf(), randf(), randf()) * 5.0

	part.visible = false

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 5.0
	timer.connect("timeout", Callable(debris, "queue_free"))
	debris.add_child(timer)
	timer.start()

