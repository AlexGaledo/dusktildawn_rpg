extends Area2D

const CLOCK_EVENT = preload("uid://crjkfvq72buhu")

var can_interact:bool = false
var clock_interaction = 1
var promptlabel = Global.thinking

func _ready() -> void:
	pass
	
func _on_body_entered(body: Node2D) -> void:
	var promptlabel = Global.thinking
	if body == Global.protagonist:
		can_interact = true
		promptlabel.visible = true
		
func _on_body_exited(body: Node2D) -> void:
	var promptlabel = Global.thinking
	if body == Global.protagonist:
		can_interact = false
		promptlabel.visible = false
		
func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed('interact'):
		interact()
		
func interact() -> void:
	var promptlabel = Global.thinking
	promptlabel.visible = true
	if clock_interaction > 0:
		DialogueManager.show_dialogue_balloon(CLOCK_EVENT,'angelstatue')
		clock_interaction -= 1;
	else:
		DialogueManager.show_dialogue_balloon(CLOCK_EVENT,'clockeventdone')
	
func _hide_prompt():
	var promptlabel = Global.thinking
	promptlabel.visible = false
