extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $thinking/AnimationPlayer

const SPEED = 150.0
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
	

const DEADZONE = 0.2

func flip():
	mc_sprite.flip_h
	
func play_idle():
	mc_sprite.play('idle')

func _physics_process(_delta: float) -> void:
	if not input_enabled:
		return
	

	# --- read axes and apply deadzone (prevents tiny float noise) ---
	var raw_x := Input.get_axis("left", "right")
	var raw_y := Input.get_axis("up", "down")
	var x := raw_x if abs(raw_x) > DEADZONE else 0.0
	var y := raw_y if abs(raw_y) > DEADZONE else 0.0

	# --- discrete signs (order-independent) ---
	var sx := 0
	if x > 0:
		sx = 1
	elif x < 0:
		sx = -1

	var sy := 0
	if y > 0:
		sy = 1
	elif y < 0:
		sy = -1

	# --- decide animation from (sx, sy) combos ---
	if sx == 0 and sy == 0:
		# idle based on last_position
		match last_position:
			'1':
				mc_sprite.play('idle_up')
			'2':
				mc_sprite.play('idle_down')
			'3':
				mc_sprite.play('walk_down_right_idle')
			'4':
				mc_sprite.play('walk_down_left_idle')
			'5':
				mc_sprite.play('walk_up_right_idle')
			'6':
				mc_sprite.play('walk_up_left_idle')
			'7':
				mc_sprite.play('idle') # right
			'0':
				mc_sprite.play('idle') # left/default
			_:
				mc_sprite.play('idle')
	else:
		# explicit combos (no nested ifs so sequence doesn't matter)
		
		if sx == -1 and sy == 0:
			mc_sprite.play("walk_side")
			mc_sprite.flip_h = true
			last_position = '0'   # left
		elif sx == 1 and sy == 1:
			mc_sprite.play('walk_down_right')
			mc_sprite.flip_h = false
			last_position = '3'   # down-right
		elif sx == -1 and sy == 1:
			mc_sprite.play('walk_down_left')
			mc_sprite.flip_h = false
			last_position = '4'   # down-left
		elif sx == 1 and sy == 0:
			mc_sprite.play("walk_side")
			mc_sprite.flip_h = false
			last_position = '7'   # right
		elif sx == 0 and sy == -1:
			mc_sprite.play("walk_up")
			mc_sprite.flip_h = false
			last_position = '1'   # up
		elif sx == 0 and sy == 1:
			mc_sprite.play("walk_down")
			mc_sprite.flip_h = false
			last_position = '2'   # down
		elif sx == 1 and sy == -1:
			mc_sprite.play('walk_up_right')
			mc_sprite.flip_h = false
			last_position = '5'   # up-right
		elif sx == -1 and sy == -1:
			mc_sprite.play('walk_up_left')
			mc_sprite.flip_h = false
			last_position = '6'   # up-left

	# --- movement (use filtered raw x,y so analog sticks still scale) ---
	var input_vector := Vector2(x, y)
	if input_vector.length() > 0:
		input_vector = input_vector.normalized() * SPEED
	else:
		input_vector = Vector2.ZERO

	velocity = input_vector
	move_and_slide()
	
	
