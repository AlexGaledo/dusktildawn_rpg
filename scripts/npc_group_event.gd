extends Area2D


const DEAD_BODY_SCENE = preload("uid://cx0jm3g5w25iw")

var can_interact = false
var counter = 1

func _on_body_entered(body: Node2D) -> void:
	var thinking = Global.thinking
	if body == Global.protagonist:
		thinking.visible = true
		can_interact = true
		
	
func _on_body_exited(body: Node2D) -> void:
	var thinking = Global.thinking
	if body == Global.protagonist:
		thinking.visible = false
		
	
func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		interact()
	
func interact():
	if counter > 0:
		DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'story')
		counter -= 1
	else:
		DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'done')	
	
