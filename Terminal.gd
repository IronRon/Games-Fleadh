extends StaticBody3D

signal terminal_restored
signal update_prompt(prompt: String)

@export var highlight_material: StandardMaterial3D

@onready var terminal_meshinstance: MeshInstance3D = $MeshInstance3D/scifi_terminal/kiosk
@onready var terminal_material: StandardMaterial3D = terminal_meshinstance.mesh.surface_get_material(0)

var is_restored: bool = false
var prompt_text = "Press E to Restore Terminal"

func add_highlight() -> void:
	terminal_meshinstance.set_surface_override_material(0, terminal_material.duplicate())
	terminal_meshinstance.get_surface_override_material(0).next_pass = highlight_material

func remove_highlight() -> void:
	terminal_meshinstance.set_surface_override_material(0, null)


func _on_interactable_focused(interactor):
	if not is_restored:
		update_prompt.emit(prompt_text)
		add_highlight()

func _on_interactable_interacted(interactor):
	$Interactable.queue_free()
	#remove_from_group("terminal")
	terminal_restored.emit()


func _on_interactable_unfocused(interactor):
	update_prompt.emit("")
	remove_highlight()
