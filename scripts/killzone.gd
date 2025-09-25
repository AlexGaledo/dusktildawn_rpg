extends Area2D


@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	timer.start()
	Engine.time_scale = 0.5
	pass # Replace with function body.
	
	
func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	pass # Replace with function body.
