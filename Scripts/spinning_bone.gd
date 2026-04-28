extends Area2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

var speed = 60
var direction = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += speed * delta * direction

func set_direction(skeleton_direction):
	direction = skeleton_direction
	animation.flip_h = direction < 0

func _on_self_destruct_timer_timeout() -> void:
	queue_free()
	
func _on_area_entered(_area: Area2D) -> void:
	queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
