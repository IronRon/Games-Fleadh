@tool
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

@onready var orbs = [$Orb, $Orb2, $Orb3, $Orb4, $Orb5, $Orb6]
var orb_spawned = [true, true, true, true, true, true]
var initial_spawn_chance = 0.3  # Start with a 30% chance to spawn an orb
var orbs_placed = 0  # Counter for how many orbs have been placed

var rng = RandomNumberGenerator.new()

@onready var grid_map : GridMap = $GridMap

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	#if Engine.is_editor_hint():
		grid_map.clear()
		floors.resize(num_floors)
		for i in range(num_floors):
			floors[i] = {
				"room_tiles": Array(PackedVector3Array()),
				"room_positions": PackedVector3Array()
				}
		#print("Floors = ", floors)
		for floor in range(num_floors):
			await generate(floor)
		$DunMesh.set_start(true)
		
		

@export_range(0,1) var survival_chance : float = 0.25
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	if Engine.is_editor_hint():
		visualize_border()

@export var room_number : int = 4
@export var room_margin : int = 1
@export var room_recursion : int = 15
@export var min_room_size : int = 2 
@export var max_room_size : int = 8

@export var num_floors : int = 1
@export var floor_gap : int = 5

@export_multiline var custom_seed : String = "" : set = set_seed 
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())

var floors : Array = []


func visualize_border():
	for floor in range(num_floors):
		var y = floor * floor_gap
		for i in range(-1,border_size+1):
			grid_map.set_cell_item( Vector3i(i,y,-1),3)
			grid_map.set_cell_item( Vector3i(i,y,border_size),3)
			grid_map.set_cell_item( Vector3i(border_size,y,i),3)
			grid_map.set_cell_item( Vector3i(-1,y,i),3)

func generate(floor_index: int):
	var y_level = floor_index * floor_gap  # Calculate y_level based on floor index
	#print(floor_index)
	#print(floors)
	
	var t : int = 0
	if custom_seed : set_seed(custom_seed)
	visualize_border()
	for i in range(room_number):
		t+=1
		make_room(room_recursion, floor_index)
		if t%17 == 16: await get_tree().create_timer(0).timeout
	
	var rpv2 : PackedVector2Array = []
	var del_graph : AStar2D = AStar2D.new()
	var mst_graph : AStar2D = AStar2D.new()
	
	for p in floors[floor_index]["room_positions"]:
		rpv2.append(Vector2(p.x,p.z))
		del_graph.add_point(del_graph.get_available_point_id(),Vector2(p.x,p.z))
		mst_graph.add_point(mst_graph.get_available_point_id(),Vector2(p.x,p.z))
	
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(rpv2))
	
	for i in delaunay.size()/3:
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		del_graph.connect_points(p1,p2)
		del_graph.connect_points(p2,p3)
		del_graph.connect_points(p1,p3)
	
	var visited_points : PackedInt32Array = []
	visited_points.append(randi() % floors[floor_index]["room_positions"].size())
	while visited_points.size() != mst_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points:
			for c in del_graph.get_point_connections(vp):
				if !visited_points.has(c):
					var con : PackedInt32Array = [vp,c]
					possible_connections.append(con)
					
		var connection : PackedInt32Array = possible_connections.pick_random()
		for pc in possible_connections:
			if rpv2[pc[0]].distance_squared_to(rpv2[pc[1]]) <\
			rpv2[connection[0]].distance_squared_to(rpv2[connection[1]]):
				connection = pc
		
		visited_points.append(connection[1])
		mst_graph.connect_points(connection[0],connection[1])
		del_graph.disconnect_points(connection[0],connection[1])
	
	var hallway_graph : AStar2D = mst_graph
	
	for p in del_graph.get_point_ids():
		for c in del_graph.get_point_connections(p):
			if c>p:
				var kill : float = randf()
				if survival_chance > kill :
					hallway_graph.connect_points(p,c)
					
	create_hallways(hallway_graph, floor_index)
	
	
func create_hallways(hallway_graph:AStar2D, floor_index:int):
	var y_level = floor_index * floor_gap  # Calculate y_level based on floor index
	var hallways : Array[PackedVector3Array] = []
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c>p:
				var room_from : PackedVector3Array = floors[floor_index]["room_tiles"][p]
				var room_to : PackedVector3Array = floors[floor_index]["room_tiles"][c]
				var tile_from : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				# Choose the closest tiles for hallway connection
				for t in room_from:
					if t.distance_squared_to(floors[floor_index]["room_positions"][c])<\
					tile_from.distance_squared_to(floors[floor_index]["room_positions"][c]):
						tile_from = t
						tile_from.y = y_level
				for t in room_to:
					if t.distance_squared_to(floors[floor_index]["room_positions"][p])<\
					tile_to.distance_squared_to(floors[floor_index]["room_positions"][p]):
						tile_to = t
						tile_to.y = y_level
				var hallway : PackedVector3Array = [tile_from,tile_to]
				hallways.append(hallway)
				grid_map.set_cell_item(tile_from,2)
				grid_map.set_cell_item(tile_to,2)
				
	# Using AStar for pathfinding on GridMap
	var astar : AStarGrid2D = AStarGrid2D.new()
	astar.size = Vector2i.ONE * border_size
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	for t in grid_map.get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x,t.z))
	var _t : int = 0
	for h in hallways:
		_t +=1
		var pos_from : Vector2i = Vector2i(h[0].x,h[0].z)
		var pos_to : Vector2i = Vector2i(h[1].x,h[1].z)
		var hall : PackedVector2Array = astar.get_point_path(pos_from,pos_to)
		
		for t in hall:
			var pos : Vector3i = Vector3i(t.x, y_level ,t.y)
			if grid_map.get_cell_item(pos) <0:
				grid_map.set_cell_item(pos,1)
		if _t%16 == 15: await  get_tree().create_timer(0).timeout
	

func make_room(rec:int, floor_index: int):
	var y_level = floor_index * floor_gap  # Calculate y_level based on floor index
	if rec <= 0:
		return
	
	var width : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	var height : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	
	var start_pos : Vector3i 
	start_pos.x = randi() % (border_size - width + 1)
	start_pos.z = randi() % (border_size - height + 1)
	start_pos.y = y_level
	
	# Check for room overlap
	for r in range(-room_margin,height+room_margin):
		for c in range(-room_margin,width+room_margin):
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			if grid_map.get_cell_item(pos) == 0:
				make_room(rec-1,floor_index)
				return
	
	var room : PackedVector3Array = []
	for r in height:
		for c in width:
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			grid_map.set_cell_item(pos,0)
			room.append(pos)
			
			
	# Randomly decide to place an orb
	if orbs_placed < orb_spawned.size():
		for i in range(orb_spawned.size()):
			if rng.randf() < initial_spawn_chance :  # 10% chance to place an orb
				if (orb_spawned[i]):
					var safe_positions = []
					# Calculate safe positions within the room, avoiding walls
					for r in range(1, height - 1):
						for c in range(1, width - 1):
							safe_positions.append(start_pos + Vector3i(c, 0, r))
					
					# Only proceed if there are safe positions available
					if safe_positions.size() > 0:
						var random_index = rng.randi() % safe_positions.size()
						orbs[i].position = Vector3(safe_positions[random_index]) + Vector3(0,1.5,0) # Adjust Y to prevent intersection with the floor
						orb_spawned[i] = false
						orbs_placed += 1
					break  # Exit the loop after placing an orb
					
			# Increase spawn chance by a calculated factor to ensure it approaches 100%
			initial_spawn_chance += (1.0 - initial_spawn_chance) * 0.1  # Increase spawn chance by 10% of the remaining probability
		
	# Now, add each Vector3 from the `room` to `floors[floor_index]["room_tiles"]`
	floors[floor_index]["room_tiles"].append(room)
	print(floors[floor_index]["room_tiles"])
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var center_pos : Vector3 = Vector3(avg_x,y_level,avg_z)
	floors[floor_index]["room_positions"].append(center_pos)
	
func _ready():
	set_start(true)
	# Get all nodes in the "orbs" group
	#var orbs = get_tree().get_nodes_in_group("orbs")
	 
	# Connect the collected signal from each orb to the _on_orb_collected function
	for orb in orbs:
		orb.collected.connect(_orb_type_collected)


func _on_dun_mesh_complete():
	grid_map.clear()


# Called when the node enters the scene tree for the first time.
#func _ready():
	## Get all nodes in the "orbs" group
	#var orbs = get_tree().get_nodes_in_group("orbs")
	 #
	## Connect the collected signal from each orb to the _on_orb_collected function
	#for orb in orbs:
		#orb.collected.connect(_orb_type_collected)
		#
	#randomize()
	#var monster_spawned = [true, true, true, true]
	#var orb_spawned = [true, true, true, true, true, true]
	#
	#var spawn_chance = grid_steps
	#var current_pos = Vector3(0, 0, 0)
	#
	#var current_dir = Vector3.RIGHT
	#var last_dir = current_dir * -1
	#
	#var layer_height = 1  # Height difference between layers
	#var orientation
	#
	## Main loop for grid steps
	#for i in range(0, grid_steps):
		#var temp_dir = dir.duplicate()
		#temp_dir.shuffle()
		#var d = temp_dir.pop_front()
		#
		## Ensure the new direction is valid
		#while(abs(current_pos.x + d.x) > grid_size or abs(current_pos.z + d.z) > grid_size or d == last_dir * -1):
			#temp_dir.shuffle()
			#d = temp_dir.pop_front()
#
		#current_pos += d
		#last_dir = d
		#
		## Occasionally change layers
		#if randf() < 0.0025:  # 15% chance to change layer
			#orientation = get_orientation_index_from_direction(d, 1)
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 0)
			#current_pos.y += layer_height
			#current_pos += d
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 3, orientation)
			#current_pos.y += layer_height
			#current_pos += d
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 3, orientation)
			#current_pos.y += layer_height
			#current_pos += d
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 3, orientation)
			#current_pos += d
		#elif randf() < 0.005:  # 15% chance to change layer
			#orientation = get_orientation_index_from_direction(d, -1)
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 3, orientation)
			#current_pos.y -= layer_height
			#current_pos += d
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 3, orientation)
			#current_pos.y -= layer_height
			#current_pos += d
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 3, orientation)
			#current_pos.y -= layer_height
			#current_pos += d
			#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 0)
			#current_pos += d
		#
		#$NavigationRegion3D/GridMap.set_cell_item(current_pos, 0)
		##$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,-1,1), 0)
		##$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(1,-2,0), 0)
		#
		#if (monster_spawned[0]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				## Create a new instance of the Mob scene.
				#spawn_monster(current_pos, Vector3(0,1.5,0))
				##monster.position = current_pos + Vector3(0,1.5,0)
				#monster_spawned[0] = false
			#
				#
		#if (orb_spawned[1]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				##print("orb2")
				#orb2.position = current_pos + Vector3(0,1.5,0)
				#orb_spawned[1] = false
			#
				#
		#if (orb_spawned[4]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				##print("orb5")
				#orb5.position = current_pos + Vector3(0,1.5,0)
				#orb_spawned[4] = false
			#
				#
		#$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,10,10), 0)
		#if (monster_spawned[1]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				## Create a new instance of the Mob scene.
				#spawn_monster(current_pos, Vector3(0,11.5,10))
				##monster.position = current_pos + Vector3(0,1.5,0)
				#monster_spawned[1] = false
			#
		#if (orb_spawned[2]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				##print("orb3")
				#orb3.position = current_pos + Vector3(0,11.5,10)
				#orb_spawned[2] = false
			#
				#
		#$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(0,15,-20), 0)
		#
		#if (monster_spawned[2]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				## Create a new instance of the Mob scene.
				#spawn_monster(current_pos, Vector3(0,16.5,-20))
				##monster.position = current_pos + Vector3(0,1.5,0)
				#monster_spawned[2] = false
				#
		#if (orb_spawned[3]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				##print("orb4")
				#orb4.position = current_pos + Vector3(0,16.5,-20)
				#orb_spawned[3] = false
			#
				#
		#$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(8,27,-16), 0)
		#$NavigationRegion3D/GridMap.set_cell_item(current_pos + Vector3(8,26,-15), 0)
		#
		#if (monster_spawned[3]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				## Create a new instance of the Mob scene.
				#spawn_monster(current_pos, Vector3(8,28.5,-16))
				##monster.position = current_pos + Vector3(0,1.5,0)
				#monster_spawned[3] = false
				#
		#if (orb_spawned[0]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				##print("orb1")
				#orb1.position = current_pos + Vector3(8,28.5,-16)
				#orb_spawned[0] = false
			#
		#if (orb_spawned[5]):
			#if (rng.randi_range(0, spawn_chance) == 0):
				##print("orb6")
				#orb6.position = current_pos + Vector3(0,1.5,0)
				#orb_spawned[5] = false
			#
		#if (spawn_chance > 0):
				#spawn_chance -= 1
				#
	##print(spawn_chance)
	#$NavigationRegion3D.bake_navigation_mesh()

# This function returns an orientation index based on the direction vector.
func get_orientation_index_from_direction(direction: Vector3, up: int) -> int:
	if up == 1:
		if direction == Vector3.RIGHT:
			return 0
		elif direction == Vector3.LEFT:
			return 3
		elif direction == Vector3.FORWARD:
			return 7
		elif direction == Vector3.BACK:
			return 15
	elif up == -1:
		if direction == Vector3.RIGHT:
			return 3
		elif direction == Vector3.LEFT:
			return 0
		elif direction == Vector3.FORWARD:
			return 15
		elif direction == Vector3.BACK:
			return 7
	return 0  # Default orientation

func can_spawn_at(pos):
	# Check if the position is not already occupied by another grid element
	return $NavigationRegion3D/GridMap.get_cell_item(pos) == -1

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
	#if Input.is_action_just_pressed("Pause"):
	#		$UI._show_menu()
	pass
	
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
