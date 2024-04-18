extends Area3D

signal teleport_player(floor_index)
var floor_index : int = 0 : set = set_floor_index
func set_floor_index(val:int)->void:
	floor_index = val
	
func _on_body_entered(body):
	print("function called")
	if body.is_in_group("player"):
		print("body enetred")
		emit_signal("teleport_player", floor_index + 1)
