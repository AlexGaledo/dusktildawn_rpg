extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $thinking/AnimationPlayer

const SPEED = 200.0
@onready var mc_sprite: AnimatedSprite2D = $protagonist_rpg_sprite
@onready var cam: Camera2D = $Camera2D
@onready var thinking: Label = $thinking


var last_position = '0'

var input_enabled = true

func _ready() -> void:
	Global.protagonist = self
	Global.camera = cam
	Global.thinking = thinking
	thinking.visible = false
	print("Global.thinking set to: ", Global.thinking)

func get_cam():
	return cam

func die():
	mc_sprite.play('death')
	get_tree().reload_current_scene()
	
func _physics_process(_delta: float) -> void:
	# Get input
	if not input_enabled:
		return
		
	var xdir := Input.get_axis("left", "right")
	var ydir := Input.get_axis("up", "down")
	if ydir < 0: mc_sprite.play("walk_up");mc_sprite.play('walk_up');last_position = '1'
	elif ydir > 0: mc_sprite.play("walk_down");mc_sprite.play('walk_down');last_position = '2'
	elif xdir < 0: mc_sprite.play("walk_side");mc_sprite.flip_h = true;last_position = '0'
	elif xdir > 0: mc_sprite.play("walk_side");mc_sprite.flip_h = false;last_position = '0'
	else: 
		if last_position == '1': 
			mc_sprite.play('idle_up')
		elif last_position == '2': 
			mc_sprite.play('idle_down') 
		else: 
			mc_sprite.play('idle')
			
			

	var input_vector := Vector2(xdir, ydir)
	
	# Normalize to prevent diagonal speed boost
	if input_vector.length() > 0:
		input_vector = input_vector.normalized() * SPEED
	
	# Apply velocity
	velocity = input_vector
	
	# Move the character using CharacterBody2D's built-in velocity
	move_and_slide()
