extends CharacterBody3D

# Emitted when the player was hit by a mob.
signal hit
# Emitted when the player hits an orb.
signal picked_up

var speed = 5.0
var jump = 5
var strength = 5.0
var density = 5.0
var block = false
var block_spam = false

var alive = true
@onready var pivot = $CameraOrigin
@onready var anim_tree = $AnimationTree

@export var sensitivity = 0.5
# Get the gravity from the project settings to be synced with RigidBody nodes.
@export var gravity = 9.8

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	#pass

func _input(event):
	if (event is InputEventMouseMotion) and alive:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		pivot.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))

func _physics_process(delta):
	if Input.is_action_just_pressed("Quit"):
			get_tree().quit()
			
	if (self.position.y < -20):
		die()
		
	if alive:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump
			anim_tree.set("parameters/conditions/jump", true)
		else :
			anim_tree.set("parameters/conditions/jump", false)
		
		if Input.is_action_just_pressed("Create") and block and !block_spam:
			place_block()
		
		if (Input.is_action_pressed("Create")) and block_spam:
			#print ("Create")
			place_block()
			
		if (Input.is_action_pressed("Punch")):
			anim_tree.set("parameters/conditions/punch", true)
		else:
			anim_tree.set("parameters/conditions/punch", false)
			

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
		anim_tree.set("parameters/conditions/running", _running())

		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			
		# Iterate through all collisions that occurred this frame
		for index in range(get_slide_collision_count()):
			# We get one of the collisions with the player
			var collision = get_slide_collision(index)

			# If the collision is with ground
			if collision.get_collider() == null:
				continue

			# If the collider is with a mob
			if collision.get_collider().is_in_group("monster"):
				var mob = collision.get_collider()
				break
				
			# If the collider is with an orb
			if collision.get_collider().is_in_group("orbs"):
				var orb = collision.get_collider()
				picked_up.emit()
				#orb.collected.connect($UI/OrbCollectedLabel._on_orb_collected.bind())
				orb.pick_up()
				break

		move_and_slide()

func _running():
	return Input.is_action_pressed("Up") or Input.is_action_pressed("Down") or Input.is_action_pressed("Left") or Input.is_action_pressed("Right")
	
func increase_speed(amount: float):
	speed += amount
	
func increase_strength(amount: float):
	strength += amount
	
func increase_density(amount: float):
	density += amount
	
func increase_jump(amount: float):
	jump += amount
	
func spawn_blocks():
	block = true
	
func spawn_blocks_spam():
	block_spam = true
	
func place_block():
	var player_position = $"../NavigationRegion3D/GridMap".local_to_map($CollisionShape3D.global_transform.origin - Vector3(0,2,0))
	var player_position_int = Vector3i(round(player_position.x), round(player_position.y), round(player_position.z))
	if ($"../NavigationRegion3D/GridMap".get_cell_item(player_position_int) == -1):
		#print($"../GridMap".local_to_map($PlayerMesh.global_transform.origin - Vector3(0,2,0)))
		#print($PlayerMesh.global_transform.origin - Vector3(0, 2, 0))
		$"../NavigationRegion3D/GridMap".set_cell_item(player_position_int, 2)
	
# And this function at the bottom.
func die():
	hit.emit()
	visible = false
	alive = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_mob_detector_body_entered(body):
	#die()
	pass
