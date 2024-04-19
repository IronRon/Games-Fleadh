extends StaticBody3D

signal teleport_player(floor_index)

var floor_index : int = 0 : set = set_floor_index
func set_floor_index(val:int)->void:
	floor_index = val

func _ready():
	add_to_group("teleporter")
	
func teleport():
	emit_signal("teleport_player", floor_index + 1)
