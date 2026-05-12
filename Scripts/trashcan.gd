extends Area2D

@onready var label: Label = $Label

var garbage_list = Array()
@export var maxGarbage = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_child_entered_tree(garbage: Area2D):
	garbage_list.append(garbage)
	trash_count()

func trash_count():
	label.text = String.num_int64(garbage_list.size()) + "/" + String.num_int64(maxGarbage)
