extends Node

const dir = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

var grid_size = 250
var grid_steps = 1000

enum OrbType {
	STRENGTH,
	SPEED,
	JUMP,
	DENSITY,
	BLOCK,
	BLOCK_SPAM
}

@export var mob_scene: PackedScene

@onready var orb1 = $Orb
@onready var orb2 = $Orb2
@onready var orb3 = $Orb3
@onready var orb4 = $Orb4
@onready var orb5 = $Orb5
@onready var orb6 = $Orb6

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get all nodes in the "orbs" group
	var orbs = get_tree().get_nodes_in_group("orbs")
	 
	# Connect the collected signal from each orb to the _on_orb_collected function
	for orb in orbs:
		orb.collected.connect(_orb_type_collected)
		
	randomize()
	var monster_spawned = [true, true, true, true]
	var orb_spawned = [true, true, true, true, true, true]
	
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
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,-1,1), 0)
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(1,-2,0), 0)
		
		if (monster_spawned[0]):
			if (rng.randi_range(0, spawn_chance) == 0):
				# Create a new instance of the Mob scene.
				spawn_monster(current_pos, Vector3(0,1.5,0))
				#monster.position = current_pos + Vector3(0,1.5,0)
				monster_spawned[0] = false
			
				
		if (orb_spawned[1]):
			if (rng.randi_range(0, spawn_chance) == 0):
				#print("orb2")
				orb2.position = current_pos + Vector3(0,1.5,0)
				orb_spawned[1] = false
			
				
		if (orb_spawned[4]):
			if (rng.randi_range(0, spawn_chance) == 0):
				#print("orb5")
				orb5.position = current_pos + Vector3(0,1.5,0)
				orb_spawned[4] = false
			
				
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,10,10), 0)
		if (monster_spawned[1]):
			if (rng.randi_range(0, spawn_chance) == 0):
				# Create a new instance of the Mob scene.
				spawn_monster(current_pos, Vector3(0,11.5,10))
				#monster.position = current_pos + Vector3(0,1.5,0)
				monster_spawned[1] = false
			
		if (orb_spawned[2]):
			if (rng.randi_range(0, spawn_chance) == 0):
				#print("orb3")
				orb3.position = current_pos + Vector3(0,11.5,10)
				orb_spawned[2] = false
			
				
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,15,-20), 0)
		
		if (monster_spawned[2]):
			if (rng.randi_range(0, spawn_chance) == 0):
				# Create a new instance of the Mob scene.
				spawn_monster(current_pos, Vector3(0,16.5,-20))
				#monster.position = current_pos + Vector3(0,1.5,0)
				monster_spawned[2] = false
				
		if (orb_spawned[3]):
			if (rng.randi_range(0, spawn_chance) == 0):
				#print("orb4")
				orb4.position = current_pos + Vector3(0,16.5,-20)
				orb_spawned[3] = false
			
				
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(8,27,-16), 0)
		$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(8,26,-15), 0)
		
		if (monster_spawned[3]):
			if (rng.randi_range(0, spawn_chance) == 0):
				# Create a new instance of the Mob scene.
				spawn_monster(current_pos, Vector3(8,28.5,-16))
				#monster.position = current_pos + Vector3(0,1.5,0)
				monster_spawned[3] = false
				
		if (orb_spawned[0]):
			if (rng.randi_range(0, spawn_chance) == 0):
				#print("orb1")
				orb1.position = current_pos + Vector3(8,28.5,-16)
				orb_spawned[0] = false
			
		if (orb_spawned[5]):
			if (rng.randi_range(0, spawn_chance) == 0):
				#print("orb6")
				orb6.position = current_pos + Vector3(0,1.5,0)
				orb_spawned[5] = false
			
		if (spawn_chance > 0):
				spawn_chance -= 1
				
	#print(spawn_chance)
	$NavigationRegion3D.bake_navigation_mesh()

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
		OrbType.BLOCK:
			$Player.spawn_blocks()
		OrbType.BLOCK_SPAM:
			$Player.spawn_blocks_spam()
	
	$UI.orb_rect()
	
func spawn_monster(current_pos, level_vector):
	var mobster = mob_scene.instantiate()
	mobster.initialize(current_pos + level_vector, $Player.position,"../Player")
	add_child(mobster)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Pause"):
			$UI._show_menu()
	
func _unhandled_input(event):
	pass
	
func _on_player_hit():
	$UI.died_rect()

func _on_orb_collected(orb_type):
	$UI._orb_collected(orb_type)
	
func _quit_game():
	get_tree().quit()
	
func _retry_game():
	get_tree().reload_current_scene()
