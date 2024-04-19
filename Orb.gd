extends StaticBody3D

enum OrbType {
	STRENGTH,
	SPEED,
	JUMP,
	DENSITY,
	BLOCK,
	BLOCK_SPAM
}

signal collected(orb_type: int)

@export var orbType: OrbType = OrbType.SPEED

@export var colour = Color(1,1,1,1)

# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh_instance = $MeshInstance3D
	var new_material = StandardMaterial3D.new()
	new_material.metallic = 1
	new_material.roughness = 0.5
	new_material.albedo_color = colour
	mesh_instance.material_override = new_material


# And this function at the bottom.
func pick_up():
	collected.emit(orbType)
	queue_free()
