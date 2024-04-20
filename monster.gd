extends CharacterBody3D

var player = null
var player_position = Vector3.ZERO
var state_machine

const SPEED = 4.0
const ATTACK_RANGE = 2.5

@export var player_path : NodePath

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree


# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector3.ZERO
	
	if player != null:
		player_position = player.global_transform.origin
	
	match state_machine.get_current_node():
		"Run":
			# Navigation
			nav_agent.set_target_position(player_position)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
			#look_at(Vector3(global_position.x + velocity.x, global_position.y, global_position.z + velocity.z), Vector3.UP)
		"Attack":
			look_at(Vector3(player_position.x, global_position.y, player_position.z), Vector3.UP)
	
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())

	move_and_slide()
	
func initialize(start_position, player_position, path_player):
	# We position the mob by placing it at start_position
	# and rotate it towards player_position, so it looks at the player.
	#look_at_from_position(start_position, player_position, Vector3.UP)
	global_position = start_position
	
	player_path = path_player

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 0.7:
		player.die()

		
func die():
	anim_tree.set("parameters/conditions/die", true)
	await get_tree().create_timer(5).timeout
	queue_free()

