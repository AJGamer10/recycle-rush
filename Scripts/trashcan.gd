extends Area2D

@onready var label: Label = $Label

var garbage_list = Array()
@export var maxGarbage = 0
var regex = RegEx.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	
	regex.compile("^([^A-Z]*[A-Z][^A-Z]*)")
	var search = regex.search(name)
	
	if search == null:
		push_error("Nome do node '%s' não bate com o padrão esperado." % name)
		return
	
	var prefixo = search.get_string(1)
	var master_node = get_parent().get_parent()
	
	# Procura lixos correspondentes na cena
	for node in master_node.get_children():
		if node.name == "Garbages":
			for garbage in node.get_children():
				if garbage.name == prefixo:
					maxGarbage += 1
	
	trash_count()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_child_entered_tree(garbage: Area2D):
	garbage_list.append(garbage)
	trash_count()

func trash_count():
	label.text = "%d/%d" % [garbage_list.size(), maxGarbage]
