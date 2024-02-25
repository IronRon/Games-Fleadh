extends Node

const dir = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

var grid_size = 250
var grid_steps = 1000

enum OrbType {
	STRENGTH,
	SPEED,
	JUMP,
	DENSITY
}

@onready var dead_rect = $UI/DiedRect
@onready var orb_rect = $UI/OrbPickUpRect
@onready var monster = $Monster
@onready var orb1 = $Orb
@onready var orb2 = $Orb2
@onready var orb3 = $Orb3
@onready var orb4 = $Orb4

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get all nodes in the "orbs" group
	var orbs = get_tree().get_nodes_in_group("orbs")
	 
	# Connect the collected signal from each orb to the _on_orb_collected function
	for orb in orbs:
		orb.collected.connect(_orb_type_collected)
		
	randomize()
	var monster_spawned = true
	var orb1_spawned = true
	var orb2_spawned = true
	var orb3_spawned = true
	var orb4_spawned = true
	var spawn_chance = grid_steps
	var current_pos = Vector3(0, 0, 0)
	
	var current_dir = Vector3.RIGHT
	var last_dir = current_dir * -1
	
	for i in range(0, grid_steps):
		var temp_dir = dir.duplicate()
		temp_dir.shuffle()
		var d = temp_dir.pop_front()

		while(abs(current_pos.x + d.x) > grid_size or abs(current_pos.z + d.z) > grid_size or d == last_dir * -1):
			temp_dir.shuffle()
			d = temp_dir.pop_front()

		current_pos += d
		last_dir = d
		
		$NavigationRegion3D/GridMap.set_cell_item(current_pos, 0)
		if (monster_spawned):
			if (rng.randi_range(0, spawn_chance) == 1):
				monster.position = current_pos + Vector3(0,1.5,0)
				monster_spawned = false
			if (spawn_chance > 0):
				spawn_chance -= 1
		if (orb1_spawned):
			if (rng.randi_range(0, spawn_chance) == 1):
				orb1.position = current_pos + Vector3(0,1.5,0)
				orb1_spawned = false
			if (spawn_chance > 0):
				spawn_chance -= 1
		if (orb2_spawned):
			if (rng.randi_range(0, spawn_chance) == 1):
				orb2.position = current_pos + Vector3(0,1.5,0)
				orb2_spawned = false
			if (spawn_chance > 0):
				spawn_chance -= 1
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,10,10), 0)
		if (orb3_spawned):
			if (rng.randi_range(0, spawn_chance) == 1):
				orb3.position = current_pos + Vector3(0,11.5,10)
				orb3_spawned = false
			if (spawn_chance > 0):
				spawn_chance -= 1
		if (orb4_spawned):
			if (rng.randi_range(0, spawn_chance) == 1):
				orb4.position = current_pos + Vector3(0,11.5,10)
				orb4_spawned = false
			if (spawn_chance > 0):
				spawn_chance -= 1

func _orb_type_collected(orb_type: int):
	match orb_type:
		OrbType.SPEED:
			$Player.increase_speed(5)
		OrbType.STRENGTH:
			$Player.increase_strength(5)
		OrbType.DENSITY:
			$Player.increase_density(5)
		OrbType.JUMP:
			$Player.increase_jump(5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $UI/DiedRect.visible:
		# This restarts the current scene.
		get_tree().reload_current_scene()
	
	
func _on_player_hit():
	dead_rect.visible = true


func _on_player_picked_up():
	orb_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	orb_rect.visible = false


func _on_orb_collected(orb_type):
	$UI/OrbCollectedLabel._orb_collected()
