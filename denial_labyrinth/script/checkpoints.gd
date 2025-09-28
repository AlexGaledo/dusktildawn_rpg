extends Area2D

var active_checkpoint: String = ""
var checkpoint_positions: Dictionary = {}

func _ready():
	# Store all checkpoint positions for easy lookup
	for child in get_children():
		if child is CollisionShape2D:
			checkpoint_positions[child.name] = child
			print("Registered checkpoint: ", child.name, " at position: ", child.global_position)

func _on_body_entered(body):
	if body == Global.platprog:
		# Find which specific checkpoint was triggered
		var triggered_checkpoint = find_overlapping_checkpoint(body.global_position)
		
		if triggered_checkpoint and triggered_checkpoint != active_checkpoint:
			activate_checkpoint(triggered_checkpoint)

func find_overlapping_checkpoint(player_pos: Vector2) -> String:
	# Check which checkpoint collision shape the player is currently overlapping
	for child in get_children():
		if child is CollisionShape2D and not child.disabled:
			# Get the area of this checkpoint
			var shape_bounds = child.shape.get_rect()
			var shape_pos = child.global_position
			var area = Rect2(shape_pos - shape_bounds.size/2, shape_bounds.size)
			
			# Check if player is within this checkpoint area
			if area.has_point(player_pos):
				return child.name
	return ""

func activate_checkpoint(checkpoint_name: String):
	active_checkpoint = checkpoint_name
	print("Checkpoint activated: ", checkpoint_name)
	
	# Update Global reference to this checkpoint
	if checkpoint_name in checkpoint_positions:
		Global.last_checkpoint = checkpoint_positions[checkpoint_name]
		print("Global checkpoint updated to: ", checkpoint_name)
	
	# Optional: Add visual/audio feedback
	create_checkpoint_effect()

func create_checkpoint_effect():
	# Play checkpoint sound if available
	var player = Global.platprog
	if player and player.has_method("play_enter_new_area"):
		player.play_enter_new_area()
	
	# Optional: Create visual effect at checkpoint location
	if active_checkpoint in checkpoint_positions:
		var checkpoint_pos = checkpoint_positions[active_checkpoint].global_position
		spawn_checkpoint_particles(checkpoint_pos)

func spawn_checkpoint_particles(pos: Vector2):
	# Simple particle effect for checkpoint activation
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(0.2, 1.0, 0.5, 0.8)  # Green checkpoint color
		
		var angle = (PI * 2 / 6) * i
		var radius = 16
		var offset = Vector2(cos(angle), sin(angle)) * radius
		particle.position = pos + offset - Vector2(2, 2)
		
		get_parent().add_child(particle)
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(particle, "position", particle.position + offset.normalized() * 20, 0.5)
		tween.tween_property(particle, "color:a", 0.0, 0.5)
		
		tween.tween_callback(particle.queue_free).set_delay(0.5)
