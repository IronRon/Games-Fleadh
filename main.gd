#@tool
extends Node

const dir = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]

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

var floors : Array = []
var floor_has_teleporter : Array = []
var teleporter_spawn_chances : Array = []

var floor_has_terminal : Array = []
var terminal_spawn_chances : Array = []

var rng = RandomNumberGenerator.new()

@onready var grid_map : GridMap = $GridMap
@onready var ui = $UI
@onready var dunmesh = $NavigationRegion3D/DunMesh

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	#if Engine.is_editor_hint():
		grid_map.clear()
		
		floors.resize(num_floors)
		floor_has_teleporter.resize(num_floors)
		teleporter_spawn_chances.resize(num_floors)
		floor_has_terminal.resize(num_floors)
		terminal_spawn_chances.resize(num_floors)
		
		for i in range(num_floors):
			floors[i] = {
				"room_tiles": Array(PackedVector3Array()),
				"room_positions": PackedVector3Array()
				}
			floor_has_teleporter[i] = false
			floor_has_terminal[i] = false
			teleporter_spawn_chances[i] = (1.0 / room_number) * 2  # Initial spawn chance
			terminal_spawn_chances[i] = (1.0 / room_number) * 2
			
		#print("Floors = ", floors)
		for floor in range(num_floors):
			await generate(floor)
		dunmesh.set_start(true)
		
		

@export_range(0,1) var survival_chance : float = 0.25
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	if Engine.is_editor_hint():
		visualize_border()

@export var room_number : int = 4
@export var room_margin : int = 1
@export var room_recursion : int = 15
@export var min_room_size : int = 3 
@export var max_room_size : int = 10

@export var num_floors : int = 1
@export var floor_gap : int = 5

@export_multiline var custom_seed : String = "" : set = set_seed 
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())


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
			initial_spawn_chance += (1.0 - initial_spawn_chance) * 0.05  # Increase spawn chance by 10% of the remaining probability
		
	# Now, add each Vector3 from the `room` to `floors[floor_index]["room_tiles"]`
	floors[floor_index]["room_tiles"].append(room)
	#print(floors[floor_index]["room_tiles"])
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var center_pos : Vector3 = Vector3(avg_x,y_level,avg_z)
	floors[floor_index]["room_positions"].append(center_pos)
	
	#teleporter spawn code
	if (floor_has_teleporter[floor_index] == false):
		if rng.randf() < teleporter_spawn_chances[floor_index]:
			var teleporter_instance = preload("res://teleporter.tscn").instantiate()
			add_child(teleporter_instance)  # Adding teleporter to the scene node
			teleporter_instance.position = center_pos + Vector3(0,0.1,0)
			teleporter_instance.set_floor_index(floor_index)  # Set the floor index
			teleporter_instance.teleport_player.connect(_on_teleport_player)
			teleporter_instance.update_prompt.connect(_update_prompt)
			floor_has_teleporter[floor_index] = true # Mark that this floor now has a teleporter
			#print("telepoter ", floor_index, " added")
		# Increase the chance of spawning a teleporter for this specific floor if teleporter has not spawned yet
		teleporter_spawn_chances[floor_index] += 1.0/room_number
	
	#terminal spawn code
	# Check if a terminal has not already been spawned on this floor
	if (floor_has_terminal[floor_index] == false):
		# Random chance to spawn a terminal based on current floor index
		if rng.randf() < terminal_spawn_chances[floor_index]:
			var safe_positions = []
			# Calculate safe positions within the room, avoiding walls
			for r in range(1, height - 1):
				for c in range(1, width - 1):
					safe_positions.append(start_pos + Vector3i(c, 0, r))
			
			safe_positions.erase(center_pos)
			# Only proceed if there are safe positions available
			if safe_positions.size() > 0:
				var random_index = rng.randi() % safe_positions.size()
				var terminal_instance = preload("res://terminal.tscn").instantiate()
				add_child(terminal_instance)
				terminal_instance.position = Vector3(safe_positions[random_index])
				terminal_instance.look_at(center_pos)
				terminal_instance.terminal_restored.connect(_on_terminal_restored)
				terminal_instance.update_prompt.connect(_update_prompt)
				floor_has_terminal[floor_index] = true
		# Increase the chance of spawning a terminal next time
		terminal_spawn_chances[floor_index] += 1.0/room_number
	
	if rng.randf() < 0.3:
			var safe_positions = []
			# Calculate safe positions within the room, avoiding walls
			for r in range(1, height - 1):
				for c in range(1, width - 1):
					safe_positions.append(start_pos + Vector3i(c, 0, r))
			
			safe_positions.erase(center_pos)
			# Only proceed if there are safe positions available
			if safe_positions.size() > 0:
				var random_index = rng.randi() % safe_positions.size()
				var enemy_instance = preload("res://virus_enemy.tscn").instantiate()
				enemy_instance.initialize(Vector3(safe_positions[random_index]), $Player.position,"../Player")
				add_child(enemy_instance)
	
func _ready():
	#if not InputMap.has_action("Pause"):
		#print("Pause action does not exist.")
	#else:
		#print("Pause action exists.")
	$CamRig/Camera3D.set_current(true)

	# Connect the collected signal from each orb to the _on_orb_collected function
	for orb in orbs:
		orb.collected.connect(_orb_type_collected)


func _on_dun_mesh_complete():
	grid_map.clear()
	grid_map.visible = true
	$NavigationRegion3D.bake_navigation_mesh()
	$Player.position = floors[0]["room_positions"][0] + Vector3(0,1,0) # Adjust Y to prevent intersection with the floor
	#print(floor_has_teleporter)
	#print(teleporter_spawn_chances)
	

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
	
	ui.orb_rect()
	
func spawn_monster(current_pos, level_vector):
	var mobster = mob_scene.instantiate()
	mobster.initialize(current_pos + level_vector, $Player.position,"../Player")
	add_child(mobster)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Pause"):
			ui._show_menu()

func _on_player_hit(damage):
	ui.player_hit(damage)

func _on_orb_collected(orb_type):
	ui._orb_collected(orb_type)
	
func _on_terminal_restored():
	ui._terminal_restored()
	
func _update_prompt(prompt: String):
	ui._prompt_update(prompt)
	
func _on_teleport_player(floor_index):
	#logic to change to the next floor
	floor_index = floor_index % num_floors # final teleporter teleports back to start
	$Player.position = floors[floor_index]["room_positions"][0] + Vector3(0,1,0)
	
func _quit_game():
	get_tree().quit()
	
func _retry_game():
	get_tree().reload_current_scene()

func _on_camera_3d_animation_complete():
	$CamRig/Camera3D.set_current(false)
	$Player.camera_set()
	get_tree().paused = false
	#ui.visible = true

func _on_player_dead():
	ui.died_rect()

func _on_ui_start(difficulty):
	set_difficulty(difficulty)
	$CamRig/AnimationPlayer.play("Start")
	set_start(true)
	ui.set_number_of_terminals(str(num_floors))
	ui.text_update()
	
func set_difficulty(difficulty):
	match difficulty:
		"easy":
			$CamRig/AnimationPlayer.speed_scale = 1.7
			room_number = 4
			border_size = 30
			survival_chance = 1
			num_floors = 4
		"normal":
			room_number = 5
			border_size = 40
			survival_chance = 0.6
			num_floors = 5
		"hard":
			$CamRig/AnimationPlayer.speed_scale = 0.7
			room_number = 6
			border_size = 45
			survival_chance = 0.5
			num_floors = 6
