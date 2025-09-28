extends Area2D


@onready var shadow: CharacterBody2D = $shadow
@onready var chap1_scenes: AnimationPlayer = $chap1_scenes
var player = null
const DEAD_BODY_SCENE = preload("uid://cx0jm3g5w25iw")
var counter = 5

func _ready() -> void:
	player = Global.protagonist

func _on_body_entered(body: Node2D) -> void:
	
	if body == Global.protagonist and counter > 2:
		DialogueManager.connect("dialogue_ended",_on_dialogue_done)
		player = Global.protagonist
		player.play_classroom()
		shadow.play_idle()
		player.input_enabled = false
		counter -= 1
		first_scene()
		
func first_scene():
	player.input_enabled = false
	player.play_idle()
	DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'classroomp1')
	
func _on_dialogue_done(_ignore):
	if counter == 5:  # Changed from > 0 to == 0
		print("failed to decrement")
	elif counter == 4:
		second_scene()
	elif counter == 3:
		play_animation()
	elif counter == 2:
		third_scene()
	elif counter == 1:
		fourth_scene()
	else:
		play_last_scene()
		
func second_scene():
	player.input_enabled = false	
	DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'classroomp2')
	counter -= 1
	
func play_animation():
	player.input_enabled = false
	chap1_scenes.stop()  # Stop any current animation
	chap1_scenes.play("shadow")
	chap1_scenes.seek(0, true) 
	await chap1_scenes.animation_finished
	counter -=1
	third_scene()

func third_scene():
	player.input_enabled = false
	DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'classroomp3')
	counter -=1
	
func fourth_scene():
	player.input_enabled = false
	DialogueManager.show_dialogue_balloon(DEAD_BODY_SCENE,'classroomp4')
	counter -=1

const CHAPT_1_DENIAL_LABYRINTH = preload("uid://c44uf4xt5ylif")

func play_last_scene():
	Engine.time_scale = 0.3
	chap1_scenes.play("final")
	await chap1_scenes.animation_finished
	Engine.time_scale = 1
	# Safer method - waits until the current frame is done processing
	var player = Global.protagonist
	player.stop_classroom()
	get_tree().change_scene_to_file("res://denial_labyrinth/scenes/chapt_1_denial_labyrinth.tscn")
	
	
	
	
