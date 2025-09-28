extends Area2D

@export var target_path: NodePath     # drag the target teleporter in the Inspector

var target: Area2D
func _ready() -> void:
	
	if Global.transition == null:
		await get_tree().process_frame  # wait one frame
		
	var color_rect: ColorRect = Global.transition
	color_rect.color = Color(0, 0, 0, 0) # black with alpha 0 (transparent)
	color_rect.z_index = 6
	if target_path != NodePath(""):
		target = get_node(target_path)

# --------- Screen Transitions ----------
func fade_out(duration: float = 1) -> Tween:
	var tween = create_tween()
	var color_rect: ColorRect = Global.transition
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	return tween

func fade_in(duration: float = 1) -> Tween:
	var tween = create_tween()
	var color_rect: ColorRect = Global.transition
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	return tween

func fade_out_in(callback: Callable, duration: float = 0.5, interval: float = 0.2) -> void:
	var tween = create_tween()
	var color_rect: ColorRect = Global.transition
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	tween.tween_interval(interval)
	tween.tween_callback(callback)   # call teleport function
	tween.tween_property(color_rect, "color:a", 0.0, duration)


# --------- Teleport Handling ----------
func _on_body_entered(body: Node2D) -> void:
	print("collided with something??")
	var player = Global.protagonist
	if body == Global.protagonist and target:
		player.stop_music()
		fade_out_in(Callable(self, "_teleport"))
		
func _teleport() -> void:
	if not target:
		return
		
	var player = Global.protagonist
	var cam = Global.camera
	cam.position_smoothing_enabled = false
	player.global_position = target.global_position
	await get_tree().create_timer(0.1).timeout
	cam.position_smoothing_enabled = true
	print("Player teleported to ", target.name)
