extends Area2D


@onready var timer: Timer = $Timer

		
func _on_body_entered(body: Node2D) -> void:
	if body == Global.platprog:
		print("PLAYER DIED!!")
		timer.start()
		body.play_death()
		Engine.time_scale = 0.5
		
#
	
func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	var player = Global.platprog
	player.stop_dead()            # restore player state
	player.teleport_checkpoint()  # move to last checkpoint
