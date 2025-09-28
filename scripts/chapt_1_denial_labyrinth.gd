extends Node2D


@onready var platformer_bgm: AudioStreamPlayer = $PlatformerBgm

const DEAD_BODY_SCENE = preload("uid://cx0jm3g5w25iw")


var second_dialogue_shown = false

func _ready() -> void:
	DialogueManager.connect("dialogue_ended", _next_dialogue)
	platformer_bgm.play()
	DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'denial1')


func _next_dialogue(_ignore):
	if not second_dialogue_shown:
		second_dialogue_shown = true
		DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'denial2')
	else:
		# Disconnect after second dialogue
		DialogueManager.disconnect("dialogue_ended", _next_dialogue)
		print("All dialogues finished")
