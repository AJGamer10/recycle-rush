extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	wall,
	hurt,
	grab
}
var trash_response = {
	"MetalTrashcan": "Metal",
	"PaperTrashcan": "Paper",
	"GlassTrashcan": "Glass",
	"PlasticTrashcan": "Plastic",
	"OrganicTrashcan": "Organic"
}
var regex = RegEx.new()

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector
@onready var walk_audio: AudioStreamPlayer2D = $SoundEfects/WalkAudio
@onready var grab_garbage_audio: AudioStreamPlayer2D = $SoundEfects/GrabGarbageAudio
@onready var jump_audio: AudioStreamPlayer2D = $SoundEfects/JumpAudio

@onready var reload_timer: Timer = $ReloadTimer

@export var max_speed = 140.0
@export var acceleration = 250
@export var deceleration = 500
@export var slide_deceleration = 100
@export var wall_acceleration = 40
@export var wall_jump_velocity = 240

const JUMP_VELOCITY = -300.0

var jump_count = 0
@export var max_jump_count = 1
var direction = 0
var status: PlayerState
var item: Area2D
var sprite_item: AnimatedSprite2D
var trashcan: Area2D
var coyote_time = 0.12
var coyote_timer = 0.0
var jump_buffer_time = 0.12
var jump_buffer_timer = 0.0

func _ready() -> void:
	animation.frame_changed.connect(_on_animation_frame_changed)
	$Hitbox.area_exited.connect(_on_hitbox_area_exited)
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	# Fisica Coyote
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	if Input.is_action_just_pressed("pular"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	apply_gravity(delta)

	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.grab:
			grab_state(delta)
	
	if status != PlayerState.grab:
		_buscar_item_na_area()
	
	move_and_slide()

func go_to_idle_state():
	status = PlayerState.idle
	animation.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	animation.play("walk")

func exit_from_walk_state():
	walk_audio.stop()

func go_to_jump_state():
	status = PlayerState.jump
	animation.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	jump_audio.play()

func go_to_fall_state():
	status = PlayerState.fall
	animation.play("fall")

func go_to_duck_state():
	status = PlayerState.duck
	animation.play("duck")
	set_small_collider()

func exit_from_duck_state():
	set_large_collider()

func go_to_slide_state():
	status = PlayerState.slide
	animation.play("slide")
	set_small_collider()

func exit_from_slide_state():
	set_large_collider()

func go_to_wall_state():
	status = PlayerState.wall
	animation.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0

func go_to_hurt_state():
	if status == PlayerState.hurt:
		return
	
	status = PlayerState.hurt
	animation.play("hurt")
	velocity.x = 0
	reload_timer.start()

func go_to_grab_state():
	status = PlayerState.grab
	item.reparent(self)
	set_collision_mask_value(6, false)
	item.z_index = 10
	item.position = Vector2(-1 if animation.flip_h else 1, -12)

func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if jump_buffer_timer > 0 and is_on_floor():
		jump_buffer_timer = 0.0
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("agachar"):
		go_to_duck_state()
		return
	
	if Input.is_action_just_pressed("agarrar"):
		if is_instance_valid(item) && item.get_parent() != trashcan:
			go_to_grab_state()
			return

func walk_state(delta):
	move(delta)
	
	if velocity.x == 0:
		exit_from_walk_state()
		go_to_idle_state()
		return
	
	
	if jump_buffer_timer > 0 and is_on_floor():
		jump_buffer_timer = 0.0
		exit_from_walk_state()
		go_to_jump_state()
		return
		
	if Input.is_action_just_pressed("agachar"):
		exit_from_walk_state()
		go_to_slide_state()
		return
		
	if not is_on_floor():
		jump_count += 1
		exit_from_walk_state()
		go_to_fall_state()
		return
	
	if Input.is_action_just_pressed("agarrar"):
		if is_instance_valid(item) && item.get_parent() != trashcan:
			go_to_grab_state()
			return

func jump_state(delta):
	move(delta)

	if Input.is_action_just_released("pular") and velocity.y < 0:
		velocity.y *= 0.5
	
	if Input.is_action_just_pressed("pular") && can_jump():
		go_to_jump_state()
		return
		
	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("pular") && can_jump():
		go_to_jump_state()
		return
	
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
	
	if left_wall_detector.is_colliding() or right_wall_detector.is_colliding():
		go_to_wall_state()
		return

func duck_state(_delta):
	update_direction()
	if Input.is_action_just_released("agachar"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func slide_state(delta):
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	
	if Input.is_action_just_released("agachar"):
		exit_from_slide_state()
		go_to_walk_state()
		return
		
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return

func wall_state(delta):
	
	velocity.y += wall_acceleration * delta
	
	if left_wall_detector.is_colliding():
		animation.flip_h = false
		direction = 1
	elif right_wall_detector.is_colliding():
		animation.flip_h = true
		direction = -1
	else:
		go_to_fall_state()
		return
		
	if is_on_floor():
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("pular"):
		velocity.x = wall_jump_velocity * direction
		go_to_jump_state()
		return

func hurt_state(_delta):
	pass

func grab_state(delta):
	move(delta)
	
	if (velocity.x != 0):
		animation.play("grab_walk")
	else:
		exit_from_walk_state()
		animation.play("grab_idle")
	
	if Input.is_action_just_released("pular") and velocity.y < 0:
		velocity.y *= 0.5
	
	if Input.is_action_just_pressed("pular") and can_jump():
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		jump_audio.play()
			
	if is_on_floor():
		jump_count = 0
	elif not is_on_floor() and jump_count == 0:
		jump_count = 1
		
	if Input.is_action_just_pressed("agarrar") && trashcan:
		regex.compile("\\d+")
		if trash_response[trashcan.name] == regex.sub(item.name, "", true):
			item.reparent(trashcan)
			item = null
			set_collision_mask_value(6, true)
			await get_tree().physics_frame
			_buscar_item_na_area()
			go_to_idle_state()
			return

func move(delta):
	update_direction()
	
	if direction:
		var mudando_direcao = sign(velocity.x) != 0 and sign(velocity.x) != sign(direction)
		var forca = deceleration if mudando_direcao else acceleration
		velocity.x = move_toward(velocity.x, direction * max_speed, forca * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func apply_gravity(delta):
	if status != PlayerState.wall:
		if not is_on_floor():
			velocity += get_gravity() * delta

func update_direction():
	direction = Input.get_axis("andarEsquerda", "andarDireita")
	
	if direction < 0:
		animation.flip_h = true
	elif direction > 0:
		animation.flip_h = false

func can_jump() -> bool:
	var coyote_valido = coyote_timer > 0.0 and jump_count == 0
	return jump_count < max_jump_count or coyote_valido

func has_child_in_group(group: String) -> bool:
	for child in get_children():
		if child.is_in_group(group):
			return true
	return false

func set_small_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3
	
	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 3

func set_large_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0
	
	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 0.5

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()
	elif area.is_in_group("Trashcan"):
		trashcan = area

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.is_in_group("Trashcan"):
		trashcan = null

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_hurt_state()

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		# inimigo morre
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		# player morre
		go_to_hurt_state()

func hit_lethal_area():
	go_to_hurt_state()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()

func _on_animation_frame_changed():
	if (status == PlayerState.walk or (status == PlayerState.grab and velocity.x > 0)) and is_on_floor():
		# toca apenas nos frames de contato do pé com o chão
		# ajusta os números conforme os frames da sua animação
		if animation.frame in [1, 4]:
			walk_audio.play()

func _buscar_item_na_area() -> void:
	item = null
	print("overlapping: ", $Hitbox.get_overlapping_areas())
	for area in $Hitbox.get_overlapping_areas():
		print("  -> ", area.name, " | pai: ", area.get_parent().name, " | grupos: ", area.get_groups())
		if area.is_in_group("Garbage") and area.get_parent().get_parent() == get_parent():
			item = area
			return
