extends Area3D

class_name Interactable

var enemy = false

# Emitted when an Interactor starts looking at me.
signal focused(interactor: Interactor)
# Emitted when an Interactor stops looking at me.
signal unfocused(interactor: Interactor)
# Emitted when an Interactor interacts with me.
signal interacted(interactor: Interactor)

func is_enemy() -> bool:
	return enemy  # Default implementation for non-enemies
