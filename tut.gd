extends Node3D

const dir = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

var grid_size = 250
var grid_steps = 1000

func _ready():
	randomize()
	var current_pos = Vector3(0, 0, 0)
	
	var current_dir = Vector3.RIGHT
	var last_dir = current_dir * -1
	
	for i in range(0, grid_steps):
		var temp_dir = dir.duplicate()
		temp_dir.shuffle()
		var d =  temp_dir.pop_front()

		while(abs(current_pos.x + d.x) > grid_size or abs(current_pos.z + d.z) > grid_size or d == last_dir * -1):
			temp_dir.shuffle()
			d = temp_dir.pop_front()

		current_pos += d
		last_dir = d
		
		$GridMap.set_cell_item(current_pos, 0)
