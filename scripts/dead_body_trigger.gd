extends Area2D

@onready var dead_body_camera: Camera2D = $dead_body_camera
const DEAD_BODY_SCENE = preload("uid://cx0jm3g5w25iw")

var counter = 1

func _ready() -> void:
	pass


func _on_dialogue_done(_ignore):
	var cam = Global.camera
	var player = Global.protagonist
	cam.make_current()             # switch back to main camera
	player.input_enabled = true    # re-enable input


func _on_body_entered(body: Node2D) -> void:
	var cam = Global.camera
	var player = Global.protagonist
	if body == Global.protagonist and counter == 1:
		DialogueManager.connect('dialogue_ended',_on_dialogue_done)
		dead_body_camera.make_current()
		player.input_enabled = false
		counter -= 1
		player.play_town()
		DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'intro')
	
		
