extends StaticBody3D

signal terminal_restored

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("terminal")

func restore_terminal():
	terminal_restored.emit()
