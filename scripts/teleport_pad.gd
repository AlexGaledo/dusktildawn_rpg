extends Area2D

@onready var color_rect: ColorRect = $"../../ScreenTransition/ColorRect"
@onready var target: Area2D = $"../../dorm_room_mc/to_hall"
@onready var protagonist_rpg: CharacterBody2D = $"../../dorm_room_mc/protagonist_rpg"
@onready var camera_2d: Camera2D = $"../../dorm_room_mc/protagonist_rpg/Camera2D"

func _ready() -> void:
	color_rect.color = Color(0, 0, 0, 0)  # black with alpha 0 (transparent)


func fade_out(duration:float = 1)->Tween:
	var tween = create_tween()
	tween.tween_property(color_rect,"color:a",1.0,duration)
	return tween

func fade_in(duration:float = 1)->Tween:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	return tween
	
func fade_out_in(callback: Callable, duration: float = 0.5, interval: float = 0.2)-> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	tween.tween_interval(interval)
	tween.tween_callback(callback)   # call teleport function
	tween.tween_property(color_rect, "color:a", 0.0, duration)


func _on_body_entered(body: Node2D) -> void:
	if body == protagonist_rpg:
		fade_out_in(Callable(self,"_teleport"))
		
		
func _teleport () -> void:
	camera_2d.position_smoothing_enabled = false
	protagonist_rpg.global_position = target.global_position
	await get_tree().create_timer(0.1).timeout
	camera_2d.position_smoothing_enabled = true
	print("Player teleported to house exterior")
