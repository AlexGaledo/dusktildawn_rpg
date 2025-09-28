extends Camera2D
const SCREEN_SIZE := Vector2(320, 180)
var cur_screen := Vector2(0, 0)
var target_node: Node2D  # Store reference to the node we're following
var current_level_bounds: Area2D = null

# Smooth transition settings
var transition_duration := 0.2  # How long the transition takes
var transition_curve := Tween.EASE_OUT  # Easing type for smooth feel
var is_transitioning := false
var current_tween: Tween

func _ready():
	make_current()
	# Set target_node to the parent (protagonist)
	target_node = get_parent()
	print("Target node set to: ", target_node.name if target_node else "null")

func _physics_process(delta):
	# Add safety check
	if not target_node:
		return
	
	# Check if we need to update camera bounds for current level
	update_camera_bounds_for_current_level()
		
	var parent_screen: Vector2 = (target_node.global_position / SCREEN_SIZE).floor()
	if not parent_screen.is_equal_approx(cur_screen) and not is_transitioning:
		update_screen(parent_screen, true)  # Use transition
	
	# ADD THIS NEW SECTION FOR PARALLAX:
	# Add smooth following within current screen for parallax
	if not is_transitioning:
		var screen_center = cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5
		var target_pos = target_node.global_position
		
		# Blend between screen center and player position
		var follow_strength = 0.3  # Adjust this (0.0 = no follow, 1.0 = full follow)
		var desired_pos = screen_center.lerp(target_pos, follow_strength)
		
		# Smoothly move camera
		global_position = global_position.lerp(desired_pos, 8.0 * delta)

func update_camera_bounds_for_current_level():
	var levels_node = get_tree().current_scene.get_node_or_null("levels")
	if not levels_node:
		return
		
	# Find which level the player is currently in
	for level in levels_node.get_children():
		var camera_area = level.get_node_or_null("camera")
		if camera_area and camera_area.has_method("has_overlapping_bodies"):
			# Check if player is in this level's bounds
			var bodies = camera_area.get_overlapping_bodies()
			for body in bodies:
				if body == target_node:
					# Player is in this level, update bounds if different
					if current_level_bounds != camera_area:
						set_bounds_for_level(camera_area)
						current_level_bounds = camera_area
					return

func set_bounds_for_level(camera_area: Area2D):
	var boundary_shape = camera_area.get_node_or_null("boundary")
	if boundary_shape and boundary_shape.shape:
		print("Updating bounds for level with camera area: ", camera_area.get_parent().name)
		var shape = boundary_shape.shape as RectangleShape2D
		var bounds_pos = boundary_shape.global_position
		var bounds_size = shape.size
		
		print("Setting limits: Left=", int(bounds_pos.x - bounds_size.x/2), 
			  " Right=", int(bounds_pos.x + bounds_size.x/2),
			  " Top=", int(bounds_pos.y - bounds_size.y/2),
			  " Bottom=", int(bounds_pos.y + bounds_size.y/2))
		
		set_limit(SIDE_LEFT, int(bounds_pos.x - bounds_size.x/2))
		set_limit(SIDE_RIGHT, int(bounds_pos.x + bounds_size.x/2))
		set_limit(SIDE_TOP, int(bounds_pos.y - bounds_size.y/2))
		set_limit(SIDE_BOTTOM, int(bounds_pos.y + bounds_size.y/2))


@onready var enter_new_area: AudioStreamPlayer = $"../../EnterNewArea"

func update_screen(new_screen: Vector2, use_transition: bool = true):
	cur_screen = new_screen
	var target_pos = cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5
	
	if use_transition and transition_duration > 0:
		
		# Stop any existing tween
		if current_tween:
			current_tween.kill()
		
		# Create smooth transition
		enter_new_area.play()
		current_tween = create_tween()
		current_tween.set_ease(transition_curve)
		current_tween.set_trans(Tween.TRANS_QUART)
		
		is_transitioning = true
		current_tween.tween_property(self, "global_position", target_pos, transition_duration)
		
		# Mark transition as complete when done
		current_tween.finished.connect(_on_transition_complete)
		
		print("Camera transitioning to screen: ", cur_screen, " at position: ", target_pos)
	else:
		# Instant snap (for initialization)
		global_position = target_pos
		print("Camera snapped to screen: ", cur_screen, " at position: ", target_pos)

func _on_transition_complete():
	is_transitioning = false
	print("Camera transition completed")

# Optional: Method to change transition settings during gameplay
func set_transition_settings(duration: float, curve: Tween.EaseType = Tween.EASE_OUT):
	transition_duration = duration
	transition_curve = curve

# Optional: Force instant camera movement (useful for teleports, scene changes, etc.)
func snap_to_target():
	var parent_screen: Vector2 = (target_node.global_position / SCREEN_SIZE).floor()
	update_screen(parent_screen, false)
