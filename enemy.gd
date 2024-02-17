extends CharacterBody3D

var player = null

const SPEED = 4.0

@export var player_path : NodePath

@onready var nav_agent = $NavigationAgent3D


# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node(player_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector3.ZERO
	
	# Navigation
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized() * SPEED

	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	move_and_slide()
