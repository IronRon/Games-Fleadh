extends StaticBody3D

signal teleport_player(floor_index)
signal update_prompt(prompt: String)

@export var highlight_material: StandardMaterial3D

@onready var teleporter_meshinstance: MeshInstance3D = $"MeshInstance3D/scifi_teleporter/14021_Teleportation_Pad_v1_l2"
@onready var teleporter_material: StandardMaterial3D = teleporter_meshinstance.mesh.surface_get_material(0)

var prompt_text = "Press E to Teleport"

var floor_index : int = 0 : set = set_floor_index
func set_floor_index(val:int)->void:
	floor_index = val + 1

func add_highlight() -> void:
	teleporter_meshinstance.set_surface_override_material(0, teleporter_material.duplicate())
	teleporter_meshinstance.get_surface_override_material(0).next_pass = highlight_material

func remove_highlight() -> void:
	teleporter_meshinstance.set_surface_override_material(0, null)

func _on_interactable_focused(interactor):
	update_prompt.emit(prompt_text)
	add_highlight()

func _on_interactable_interacted(interactor):
	teleport_player.emit(floor_index)

func _on_interactable_unfocused(interactor):
	update_prompt.emit("")
	remove_highlight()
