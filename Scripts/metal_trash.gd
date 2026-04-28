extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func grab_item(player_position):
	position = player_position


func _on_area_entered(area: Area2D) -> void:
	area.position = position
	print("area entered")
