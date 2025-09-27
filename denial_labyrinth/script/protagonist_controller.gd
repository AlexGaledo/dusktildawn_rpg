extends CharacterBody2D

# === CELESTE-STYLE MOVEMENT VARIABLES ===

# Horizontal movement
var run_speed = 200.0           # Max running speed
var accel_ground = 1500.0       # How fast we reach max speed on ground
var accel_air = 1000.0          # Slower acceleration in air
var friction_ground = 2000.0    # Stops fast when no input
var friction_air = 500.0        # Much slower friction in air

# Jumping
var jump_force = -400.0         # Jump impulse (negative = up)
var jump_force_double = -350.0  # Slightly weaker second jump
var gravity_force = 1200.0      # Pull down speed
var max_fall_speed = 800.0      # Clamp falling
var jump_buffer_time = 0.1      # Buffer jump input
var coyote_time = 0.1           # Jump grace period after leaving ground

# Double jump system
var max_jumps = 2               # Total jumps (ground + air)
var jumps_remaining = 2         # Current jumps available
var double_jump_consumed = false # Track if we used our air jump

# Dashing
var dash_speed = 500.0          # Strong burst
var dash_duration = 0.15        # Short and snappy
var dash_cooldown = 0.5         # Small cooldown

# Wall mechanics
var wall_slide_speed = 100.0
var wall_jump_force_x = 300.0
var wall_jump_force_y = -350.0

var facing = 1 # 1 = right, -1 = left

# Animation node
var anim: AnimatedSprite2D = null

# State tracking
var can_dash = true
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var is_wall_sliding = false
var was_on_floor_last_frame = false

# Roman Cancel system
var roman_cancel_available = true
var roman_cancel_cooldown = 5.0
var roman_cancel_cooldown_timer = 0.0
var roman_cancel_active = false
var roman_cancel_timer = 0.0
var roman_cancel_duration = 0.5

# Hidden Life system
var max_hidden_lives = 3
var hidden_lives = 3
var life_regen_timer = 0.0
var life_regen_interval = 10.0
var invincibility_timer = 0.0
var invincibility_duration = 1.0

# Visual effects
var damage_flash_timer = 0.0
var damage_flash_duration = 0.3
var dash_flash_timer = 0.0
var dash_flash_duration = 0.1

# Dash smoke particles
var dash_smoke_timer = 0.0
var dash_smoke_interval = 0.02  # Spawn smoke every 0.02s during dash

# Spring mechanics
var spring_velocity = Vector2.ZERO
var spring_timer = 0.0
var spring_duration = 0.2  # How long spring force lasts
@onready var mc_sprite: AnimatedSprite2D = $AgentAnimator/AnimatedSprite2D

func _ready() -> void:
	get_tree().process_frame
	Global.platprog = self
	if has_node("AgentAnimator"):
		var parent = $AgentAnimator
		for child in parent.get_children():
			if child is AnimatedSprite2D:
				anim = child
				break
	if not anim:
		push_warning("AnimatedSprite2D not found under AgentAnimator.")

var is_dead: bool = false

func play_death():
	if not is_dead:
		is_dead = true
		velocity = Vector2.ZERO
		mc_sprite.play('death')

func _physics_process(delta: float) -> void:
	# Don't process movement during Roman Cancel
	if roman_cancel_active:
		_update_roman_cancel(delta)
		return
	
	_update_timers(delta)
	_update_life_system(delta)
	
	var input_dir = Input.get_axis("left", "right")
	
	# Roman Cancel input (space key)
	if Input.is_action_just_pressed("roman_cancel") and roman_cancel_available and roman_cancel_cooldown_timer <= 0:
		_activate_roman_cancel()
		return
	
	# Handle jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Main movement logic
	if not is_dashing:
		_handle_horizontal_movement(input_dir, delta)
		_apply_gravity(delta)
		_handle_jump()
		_handle_wall_mechanics(delta)
	else:
		# During dash, still allow gravity and jump input for tech execution
		_apply_gravity(delta)
		_handle_dash_jump()  # Special dash-jump handling
	
	_handle_dash(input_dir, delta)
	
	# Update jump system and other timers
	var currently_on_floor = is_on_floor()
	
	if currently_on_floor:
		coyote_timer = coyote_time
		# Reset jumps when landing
		if not was_on_floor_last_frame:
			jumps_remaining = max_jumps
			double_jump_consumed = false
			print("LANDED - jumps reset! Jumps remaining: ", jumps_remaining)
			
			# Preserve horizontal momentum when landing from dash
			if is_dashing:
				# Landing during dash - preserve horizontal component
				var horizontal_momentum = velocity.x
				velocity.y = 0  # Stop vertical, keep horizontal
				print("DASH LANDING - preserved momentum: ", horizontal_momentum)
			
			if not can_dash:
				can_dash = true
				print("DASH RECHARGED on landing! can_dash: ", can_dash)
	else:
		coyote_timer = max(0, coyote_timer - delta)
	
	# Store floor state for next frame
	was_on_floor_last_frame = currently_on_floor
	
	jump_buffer_timer = max(0, jump_buffer_timer - delta)
	
	move_and_slide()
	_update_animation()

func _handle_horizontal_movement(input_dir: float, delta: float) -> void:
	if input_dir != 0:
		facing = 1 if input_dir > 0 else -1
		var accel = accel_ground if is_on_floor() else accel_air
		
		# Don't override high-speed momentum from dashes/techs
		var target_speed = input_dir * run_speed
		if abs(velocity.x) > run_speed * 1.2 and sign(velocity.x) == sign(input_dir):
			# Preserve high-speed momentum in same direction
			velocity.x = move_toward(velocity.x, velocity.x, accel * delta * 0.1)  # Very slow decay
		else:
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		var friction = friction_ground if is_on_floor() else friction_air
		
		# Reduce friction for high-speed momentum (let techs carry further)
		if abs(velocity.x) > run_speed * 1.2:
			friction *= 0.3  # Much less friction for tech momentum
		
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func _apply_gravity(delta: float) -> void:
	if not is_wall_sliding:
		velocity.y += gravity_force * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed

func _handle_jump() -> void:
	# Check if we have jump input
	if jump_buffer_timer > 0:
		var can_jump = false
		var jump_type = ""
		
		# Ground jump (includes coyote time)
		if is_on_floor() or coyote_timer > 0:
			can_jump = true
			jump_type = "GROUND"
		# Double jump (air jump)
		elif jumps_remaining > 0 and not double_jump_consumed:
			can_jump = true
			jump_type = "DOUBLE"
			double_jump_consumed = true
		
		if can_jump:
			# Apply appropriate jump force
			if jump_type == "DOUBLE":
				velocity.y = jump_force_double  # Slightly weaker
				jumps_remaining -= 1
				_spawn_double_jump_effect()
				print("DOUBLE JUMP! Jumps remaining: ", jumps_remaining)
			else:
				velocity.y = jump_force
				jumps_remaining -= 1
				print("GROUND JUMP! Jumps remaining: ", jumps_remaining)
			
			# Clear timers and states
			jump_buffer_timer = 0
			coyote_timer = 0
			is_wall_sliding = false
	
	# Variable jump height - cut short if release jump early
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func _handle_dash_jump() -> void:
	# Special jump handling during dash for superdash/hyperdash techs
	if jump_buffer_timer > 0 or Input.is_action_just_pressed("jump"):
		# Check if we can jump (don't consume double jump during dash techs)
		if jumps_remaining > 0:
			var horizontal_speed = abs(velocity.x)
			var was_diagonal_down = velocity.y > 0 and horizontal_speed > 0
			
			# End the dash
			is_dashing = false
			
			if was_diagonal_down:
				# HYPERDASH: Down-diagonal dash + jump
				# Higher speed (325), half height
				velocity.y = jump_force * 0.5  # Half height
				velocity.x = velocity.x * 1.3 if horizontal_speed > 0 else velocity.x  # Boost horizontal to ~325 speed
				print("HYPERDASH executed! Speed: ", velocity.x, " Height: ", velocity.y)
			else:
				# SUPERDASH: Horizontal dash + jump  
				# Medium speed (260), full height
				velocity.y = jump_force  # Full height
				velocity.x = velocity.x * 1.04 if horizontal_speed > 0 else velocity.x  # Boost to ~260 speed
				print("SUPERDASH executed! Speed: ", velocity.x, " Height: ", velocity.y)
			
			# Consume a jump for the tech
			jumps_remaining -= 1
			jump_buffer_timer = 0
			coyote_timer = 0
			print("Dash-jump tech used. Jumps remaining: ", jumps_remaining)

func _handle_wall_mechanics(_delta: float) -> void:
	if is_on_wall_only() and not is_on_floor() and velocity.y > 0:
		is_wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)
		
		# Wall jump - resets double jump
		if Input.is_action_just_pressed("jump"):
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * wall_jump_force_x
			velocity.y = wall_jump_force_y
			is_wall_sliding = false
			facing = 1 if wall_normal.x > 0 else -1
			
			# Wall jump resets your air mobility
			jumps_remaining = max_jumps - 1  # You used the wall jump, so 1 jump left
			double_jump_consumed = false     # But double jump is available again
			print("WALL JUMP! Jumps reset. Jumps remaining: ", jumps_remaining)
	else:
		is_wall_sliding = false

func _handle_dash(_input_dir: float, delta: float) -> void:
	# Update smoke timer during dash
	if is_dashing:
		dash_smoke_timer -= delta
		if dash_smoke_timer <= 0:
			_spawn_dash_smoke()
			dash_smoke_timer = dash_smoke_interval
	
	# Dash trigger - simple system
	if Input.is_action_just_pressed("dash"):
		print("Dash button pressed! can_dash: ", can_dash, " is_dashing: ", is_dashing, " on_floor: ", is_on_floor())
		
		if can_dash and not is_dashing:
			var dash_dir = Vector2.ZERO
			
			if Input.is_action_pressed("right"): dash_dir.x += 1
			if Input.is_action_pressed("left"): dash_dir.x -= 1
			if Input.is_action_pressed("up"): dash_dir.y -= 1
			if Input.is_action_pressed("down"): dash_dir.y += 1  # Now allow down dash
			
			# Default: dash forward
			if dash_dir == Vector2.ZERO:
				dash_dir = Vector2.RIGHT if facing > 0 else Vector2.LEFT
			
			# Normalize so diagonals aren't faster
			dash_dir = dash_dir.normalized()
			
			# Apply dash
			is_dashing = true
			can_dash = false  # No more dashing until landing
			dash_timer = dash_duration
			velocity = dash_dir * dash_speed
			is_wall_sliding = false
			
			# FX
			dash_flash_timer = dash_flash_duration
			dash_smoke_timer = 0.0  # Start smoke immediately
			print("EXECUTED DASH! Direction: ", dash_dir, " can_dash now: ", can_dash)
		else:
			print("DASH BLOCKED - can_dash: ", can_dash, " is_dashing: ", is_dashing)
	
	# Handle dash duration and collision detection
	if is_dashing:
		# Check for collisions during dash for crossbounce
		_check_dash_collision()
		
		dash_timer -= delta
		if dash_timer <= 0:
			# Dash ended - preserve momentum instead of stopping
			var preserved_speed = velocity.length() * 0.7  # Keep 70% of dash momentum
			var preserved_direction = velocity.normalized()
			
			is_dashing = false
			
			# Apply preserved momentum (this creates the "bouncy" feeling)
			if preserved_speed > run_speed:
				velocity = preserved_direction * preserved_speed
				print("Dash ended with preserved momentum: ", velocity)
			else:
				# Fall back to normal speed if too slow
				velocity.x = preserved_direction.x * run_speed
			
			print("Dash timer ended, is_dashing now: ", is_dashing)

func _update_timers(delta: float) -> void:
	# Roman Cancel cooldown
	if roman_cancel_cooldown_timer > 0:
		roman_cancel_cooldown_timer -= delta
		if roman_cancel_cooldown_timer <= 0:
			roman_cancel_available = true
	
	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	# Invincibility
	if invincibility_timer > 0:
		invincibility_timer -= delta
	
	# Visual effects timers
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
	
	if dash_flash_timer > 0:
		dash_flash_timer -= delta

func _update_life_system(delta: float) -> void:
	if hidden_lives < max_hidden_lives:
		life_regen_timer += delta
		if life_regen_timer >= life_regen_interval:
			hidden_lives += 1
			life_regen_timer = 0.0
			print("Life regenerated! Lives: ", hidden_lives)

func _activate_roman_cancel() -> void:
	roman_cancel_active = true
	roman_cancel_timer = roman_cancel_duration
	roman_cancel_available = false
	roman_cancel_cooldown_timer = roman_cancel_cooldown
	
	# Reset dash ability and jumps
	can_dash = true
	dash_cooldown_timer = 0.0
	is_dashing = false
	coyote_timer = coyote_time
	
	# Reset jump system
	jumps_remaining = max_jumps
	double_jump_consumed = false
	
	# Stop all movement and freeze in air
	velocity = Vector2.ZERO
	
	# Freeze animation and add dramatic visual effect
	if anim:
		anim.pause()  # Stop the animation
		anim.modulate = Color(2.0, 2.0, 0.5, 1.0)  # Bright yellow flash
	
	print("ROMAN CANCEL ACTIVATED! Jumps reset: ", jumps_remaining)

func _update_roman_cancel(delta: float) -> void:
	roman_cancel_timer -= delta
	
	# Keep player frozen in air during Roman Cancel
	velocity = Vector2.ZERO
	
	# Flash effect - alternate between bright and normal (animation still frozen)
	if anim:
		var flash_cycle = sin(roman_cancel_timer * 20.0) * 0.5 + 0.5
		anim.modulate = Color(1.0 + flash_cycle, 1.0 + flash_cycle, 0.5 + flash_cycle * 0.5, 1.0)
	
	if roman_cancel_timer <= 0:
		roman_cancel_active = false
		if anim:
			anim.play()  # Resume animation
			anim.modulate = Color.WHITE  # Reset to normal
		print("Roman Cancel ended")

func _update_animation() -> void:
	if not anim or roman_cancel_active or is_dead:
		return
	
	# Apply visual effects first
	_apply_visual_effects()
	
	var new_anim = ""
	
	# Use proper directional animations
	if is_dashing:
		# Check dash direction for proper animation
		if velocity.y < -50:  # Dashing upward
			new_anim = "dash_up"
		else:  # Horizontal or down dashes use left/right animations
			new_anim = "dash_right" if facing > 0 else "dash_left"
	elif is_wall_sliding:
		# Use proper wall slide animations
		new_anim = "hold_terrain_left" if facing > 0 else "hold_terrain_right"
	elif not is_on_floor():
		new_anim = "jump_right" if facing > 0 else "jump_left"
	elif abs(velocity.x) > 10:
		new_anim = "walk_right" if facing > 0 else "walk_left"
	else:
		new_anim = "idle_right" if facing > 0 else "idle_left"
	
	# Don't flip - use directional animations
	anim.flip_h = false
	
	if anim.animation != new_anim:
		anim.play(new_anim)

func _apply_visual_effects() -> void:
	if not anim:
		return
	
	# Damage flash effect (red tint)
	if damage_flash_timer > 0:
		var flash_intensity = damage_flash_timer / damage_flash_duration
		anim.modulate = Color(1.0 + flash_intensity, 1.0 - flash_intensity * 0.5, 1.0 - flash_intensity * 0.5)
	# Dash flash effect (white flash)
	elif dash_flash_timer > 0:
		var flash_intensity = dash_flash_timer / dash_flash_duration
		anim.modulate = Color(1.0 + flash_intensity, 1.0 + flash_intensity, 1.0 + flash_intensity)
	else:
		anim.modulate = Color.WHITE

func _spawn_dash_smoke() -> void:
	# Create a simple circular particle effect using a ColorRect
	var smoke = ColorRect.new()
	smoke.size = Vector2(8, 8)  # Small circle
	smoke.color = Color(0.8, 0.8, 0.8, 0.6)  # Light gray, semi-transparent
	smoke.position = global_position - Vector2(4, 4)  # Center it
	
	# Add to scene tree
	get_parent().add_child(smoke)
	
	# Create a tween to fade out and shrink the smoke
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple tweens
	
	# Fade out
	tween.tween_property(smoke, "color:a", 0.0, 0.5)
	# Scale up slightly
	tween.tween_property(smoke, "scale", Vector2(1.5, 1.5), 0.5)
	
	# Remove when done
	tween.tween_callback(smoke.queue_free).set_delay(0.5)

func _spawn_double_jump_effect() -> void:
	# Create a special effect for double jump (different from dash smoke)
	for i in range(8):  # More particles for double jump
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(0.5, 0.8, 1.0, 0.8)  # Light blue for double jump
		
		# Create a circle around the player
		var angle = (PI * 2 / 8) * i
		var radius = 12
		var offset = Vector2(cos(angle), sin(angle)) * radius
		particle.position = global_position + offset - Vector2(2, 2)
		
		get_parent().add_child(particle)
		
		# Animate outward and fade
		var tween = create_tween()
		tween.set_parallel(true)
		
		var end_pos = particle.position + offset.normalized() * 20
		tween.tween_property(particle, "position", end_pos, 0.3)
		tween.tween_property(particle, "color:a", 0.0, 0.3)
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), 0.3)
		
		tween.tween_callback(particle.queue_free).set_delay(0.3)

func _check_dash_collision() -> void:
	# Check if we hit a wall during dash (crossbounce mechanic)
	if is_on_wall():
		var wall_normal = get_wall_normal()
		var dash_direction = velocity.normalized()
		
		# Calculate angle between dash direction and wall
		var angle = abs(dash_direction.angle_to(wall_normal))
		
		# Only crossbounce if we hit at a reasonable angle (not grazing)
		if angle > PI * 0.3:  # At least 54 degrees
			# Calculate bounce vector
			var bounce_direction = dash_direction.bounce(wall_normal)
			
			# Preserve most of the momentum but add slight upward bias
			var momentum_multiplier = 0.9  # Keep 90% of dash speed
			var bounce_velocity = bounce_direction * (dash_speed * momentum_multiplier)
			
			# Add slight upward boost to help with platforming
			if bounce_velocity.y > 0:  # If bouncing downward
				bounce_velocity.y *= 0.7  # Reduce downward momentum
			else:  # If bouncing upward
				bounce_velocity.y *= 1.1  # Boost upward momentum
			
			# Apply the bounce
			velocity = bounce_velocity
			
			# Give another dash opportunity and reset jumps (crossbounce mechanic)
			can_dash = true
			jumps_remaining = max_jumps
			double_jump_consumed = false
			is_dashing = false  # End current dash
			
			# Visual feedback
			_spawn_crossbounce_effect()
			
			print("CROSSBOUNCE! Angle: ", rad_to_deg(angle), "° Bounce: ", bounce_velocity, " dash & jumps recharged!")
		else:
			# Grazing hit - just stop the dash without bouncing
			is_dashing = false
			velocity *= 0.3  # Reduce speed significantly
			print("Grazing wall hit - dash stopped")
	
	# WAVEDASH: Check if we hit the ground during dash (especially diagonal down dashes)
	elif is_on_floor() and velocity.y > 0:  # Dashing downward into ground
		var dash_direction = velocity.normalized()
		
		# Only wavedash if we're dashing down at a decent angle
		if abs(dash_direction.y) > 0.3:  # At least 30% downward component
			# Create upward bounce with preserved horizontal momentum
			var horizontal_momentum = velocity.x * 1.2  # Boost horizontal speed
			var vertical_bounce = -abs(velocity.y) * 0.8  # Convert downward to upward
			
			velocity.x = horizontal_momentum
			velocity.y = vertical_bounce
			
			# Give another dash opportunity and reset jumps (wavedash mechanic)
			can_dash = true
			jumps_remaining = max_jumps
			double_jump_consumed = false
			is_dashing = false  # End current dash
			
			# Visual feedback
			_spawn_crossbounce_effect()
			
			print("WAVEDASH! Horizontal: ", horizontal_momentum, " Vertical bounce: ", vertical_bounce, " dash & jumps recharged!")

func _spawn_crossbounce_effect() -> void:
	# Create a more dramatic effect for crossbounce
	for i in range(6):  # Multiple particles
		var smoke = ColorRect.new()
		smoke.size = Vector2(6, 6)
		smoke.color = Color(1.0, 0.8, 0.2, 0.8)  # Orange-yellow for crossbounce
		
		# Randomize position slightly
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		smoke.position = global_position + offset - Vector2(3, 3)
		
		get_parent().add_child(smoke)
		
		# Animate with random direction
		var tween = create_tween()
		tween.set_parallel(true)
		
		var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var end_pos = smoke.position + random_dir * 20
		
		tween.tween_property(smoke, "position", end_pos, 0.4)
		tween.tween_property(smoke, "color:a", 0.0, 0.4)
		tween.tween_property(smoke, "scale", Vector2(0.5, 0.5), 0.4)
		
		tween.tween_callback(smoke.queue_free).set_delay(0.4)

func _apply_spring_force(force: Vector2) -> void:
	# Spring Cancel: If dashing when hitting spring, dash overrides spring
	if is_dashing:
		print("SPRING CANCELLED by dash!")
		return
	
	# Apply spring force
	spring_velocity = force
	spring_timer = spring_duration
	velocity += spring_velocity
	
	print("Spring force applied: ", force, " New velocity: ", velocity)

func take_damage() -> void:
	if invincibility_timer > 0:
		return  # Still invincible
	
	hidden_lives -= 1
	invincibility_timer = invincibility_duration
	damage_flash_timer = damage_flash_duration
	
	print("Player took damage! Lives remaining: ", hidden_lives)
	
	if hidden_lives <= 0:
		print("Player died!")
		# Reset lives for respawn
		hidden_lives = max_hidden_lives
