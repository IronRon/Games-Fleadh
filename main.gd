extends Node

enum OrbType {
	STRENGTH,
	SPEED,
	JUMP,
	DENSITY
}

@onready var dead_rect = $UI/DiedRect
@onready var orb_rect = $UI/OrbPickUpRect

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get all nodes in the "orbs" group
	var orbs = get_tree().get_nodes_in_group("orbs")
	 
	# Connect the collected signal from each orb to the _on_orb_collected function
	for orb in orbs:
		orb.collected.connect(_on_orb_collected)

func _on_orb_collected(orb_type: int):
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
	
	
func _on_player_hit():
	dead_rect.visible = true


func _on_player_picked_up():
	orb_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	orb_rect.visible = false
