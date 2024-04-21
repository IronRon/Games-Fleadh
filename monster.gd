extends CharacterBody3D

signal died(position:Vector3)

var player = null
var player_position = Vector3.ZERO
var state_machine
var health = 0

const SPEED = 4.0
const ATTACK_RANGE = 2.5

@export var player_path : NodePath
@export var highlight_material: StandardMaterial3D

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var enemy_meshinstance: MeshInstance3D = $Armature/Skeleton3D/Alpha_Surface
@onready var enemy_material: StandardMaterial3D = enemy_meshinstance.mesh.surface_get_material(0)
@onready var healthbar = $SubViewport/HealthBar
@onready var interact = $Interactable


# Called when the node enters the scene tree for the first time.
func _ready():
	interact.enemy = true
	health = 50
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	healthbar.init_health(health)

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
	global_position = start_position
	player_path = path_player

func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 0.7:
		player.damage_taken()

func die():
	died.emit(position)
	anim_tree.set("parameters/conditions/hit", true)
	await get_tree().create_timer(5).timeout
	queue_free()
	
func add_highlight() -> void:
	enemy_meshinstance.set_surface_override_material(0, enemy_material.duplicate())
	enemy_meshinstance.get_surface_override_material(0).next_pass = highlight_material

func remove_highlight() -> void:
	enemy_meshinstance.set_surface_override_material(0, null)

func _on_interactable_focused(interactor):
	add_highlight()

func _on_interactable_interacted(interactor, damage):
	health -= damage
	healthbar.health = health
	if (health <= 0):
		interact.queue_free()
		die()
	#$AudioStreamPlayer3D.play()

func _on_interactable_unfocused(interactor):
	remove_highlight()
	
