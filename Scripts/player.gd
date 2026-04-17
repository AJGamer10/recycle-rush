extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck
}

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const SPEED = 80.0
const JUMP_VELOCITY = -300.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.fall:
			fall_state()
		PlayerState.duck:
			duck_state()
	
	move_and_slide()

func go_to_idle_state():
	status = PlayerState.idle
	animation.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	animation.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	animation.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	
func go_to_fall_state():
	status = PlayerState.fall
	animation.play("fall")

func go_to_duck_state():
	status = PlayerState.duck
	animation.play("duck")
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3

func exit_from_duck_state():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0

func idle_state():
	move()
	if velocity.x != 0:
		go_to_walk_state()
		return
		
	if Input.is_action_just_pressed("pular"):
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("agachar"):
		go_to_duck_state()
		return

func walk_state():
	move()
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("pular"):
		go_to_jump_state()
		return

func jump_state():
	move()
	
	if Input.is_action_just_pressed("pular") && can_jump():
		go_to_jump_state()
		return
		
	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state():
	move()
	
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

func duck_state():
	update_direction()
	if Input.is_action_just_released("agachar"):
		exit_from_duck_state()
		go_to_idle_state()
		return


func move():
	update_direction()
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
func update_direction():
	direction = Input.get_axis("andarEsquerda", "andarDireita")
	
	if direction < 0:
		animation.flip_h = true
	elif direction > 0:
		animation.flip_h = false

func can_jump() -> bool:
	return jump_count < max_jump_count
