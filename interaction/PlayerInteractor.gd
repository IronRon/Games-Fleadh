extends Interactor

@export var player: CharacterBody3D

var cached_closest: Interactable
var damage = 5

func _ready() -> void:
	controller = player

func _physics_process(_delta: float) -> void:
	var new_closest: Interactable = get_closest_interactable()
	if new_closest != cached_closest:
		if is_instance_valid(cached_closest):
			unfocus(cached_closest)
		if new_closest:
			focus(new_closest)

		cached_closest = new_closest

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if is_instance_valid(cached_closest) and !cached_closest.is_enemy():
			interact(cached_closest)
	elif event.is_action_pressed("Punch"):
		if is_instance_valid(cached_closest) and cached_closest.is_enemy():
			interact(cached_closest, damage)

func _on_area_exited(area: Interactable) -> void:
	if cached_closest == area:
		unfocus(area)
		

func _on_player_attack_up(strength):
	damage = strength
