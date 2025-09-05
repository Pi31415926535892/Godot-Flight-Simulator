extends Node3D

@onready var sun = $DirectionalLight3D  # DirectionalLight3D
@onready var environment : WorldEnvironment = $WorldEnvironment

# CONFIG
var day_speed := 24         # Degrees per second (real-time = 0.25)
var current_time := 6.0      # Start at 6 AM
var full_day_hours := 24.0

# Optional: dynamic sky colors
var sky_color_day := Color(0.6, 0.8, 1.0)
var sky_color_night := Color(0.01, 0.01, 0.05)

func _process(delta):
	# Advance time
	current_time += delta * (day_speed / 15.0)
	current_time = fmod(current_time, full_day_hours)

	# Convert to sun angle (0h = -90°, 12h = +90°)
	var angle = ((current_time / full_day_hours) * 360.0) - 90.0
	sun.rotation_degrees.x = angle

	# Dim sunlight at night
	var sun_strength = clamp(sin(deg_to_rad(angle)), 0.0, 1.0)
	sun.light_energy = sun_strength * 1.5  # adjust to taste

	# Optional: darken sky at night
	if environment and environment.environment:
		var sky = environment.environment.sky
		if sky is ProceduralSkyMaterial:
			var new_color = sky_color_day.lerp(sky_color_night, 1.0 - sun_strength)
			sky.sky_color = new_color
