extends Node

@onready var dead_rect = $UI/DiedRect
@onready var orb_rect = $UI/OrbPickUpRect

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _on_player_hit():
	dead_rect.visible = true


func _on_player_picked_up():
	orb_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	orb_rect.visible = false
