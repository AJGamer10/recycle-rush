extends Area2D

var parent: Node

func _process(_delta: float) -> void:
	parent = get_parent()
	if parent.is_in_group("Player"):
		visible = true
	elif parent.is_in_group("Trashcan"):
		visible = false
