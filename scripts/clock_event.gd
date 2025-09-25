extends Area2D




const CLOCK_EVENT = preload("uid://crjkfvq72buhu")

var can_interact:bool = false
var clock_interaction = 1



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
		DialogueManager.show_dialogue_balloon(CLOCK_EVENT,'clockevent')
		clock_interaction -= 1;
	else:DialogueManager.show_dialogue_balloon(CLOCK_EVENT,'clockeventdone')
	
func _hide_prompt():
	var promptlabel = Global.thinking
	promptlabel.visible = false
#func show_floating_text():
	#promptlabel.modulate.a=1.0
	#promptlabel.position = Vector2(0,-20)
	#promptlabel.visible = true
#
	#var tween = create_tween()
	#tween.tween_property(promptlabel, "position:y", -40, 0.5)
	#tween.tween_property(promptlabel, "modulate:a", 0.0, 0.0)
	#tween.tween_callback(Callable(self, "_hide_prompt"))


	
