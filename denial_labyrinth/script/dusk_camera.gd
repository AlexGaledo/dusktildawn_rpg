extends Camera2D
const SCREEN_SIZE := Vector2(320, 180)
var cur_screen := Vector2(0, 0)
var target_node: Node2D  # Store reference to the node we're following

# Smooth transition settings
var transition_duration := 0.2  # How long the transition takes
var transition_curve := Tween.EASE_OUT  # Easing type for smooth feel
var is_transitioning := false
var current_tween: Tween

func _ready():
	# Store reference to parent before making top-level
	target_node = get_parent()
	set_as_top_level(true)
	# Make this camera the active one
	make_current()
	# Calculate which screen the target is actually on
	var parent_screen: Vector2 = (target_node.global_position / SCREEN_SIZE).floor()
	update_screen(parent_screen, false)  # Start without transition

func _physics_process(delta):
	var parent_screen: Vector2 = (target_node.global_position / SCREEN_SIZE).floor()
	if not parent_screen.is_equal_approx(cur_screen) and not is_transitioning:
		update_screen(parent_screen, true)  # Use transition

func update_screen(new_screen: Vector2, use_transition: bool = true):
	cur_screen = new_screen
	var target_pos = cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5
	
	if use_transition and transition_duration > 0:
		# Stop any existing tween
		if current_tween:
			current_tween.kill()
		
		# Create smooth transition
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
