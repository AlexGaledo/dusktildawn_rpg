extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var shadow_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	
	move_and_slide()


func play_idle():
	shadow_sprite.play('shadow_idle')
