extends CharacterBody3D

# Emitted when the player was hit by a mob.
signal hit

const ATTACK_RANGE = 2.5

var speed = 5.0
var jump = 5
var strength = 5.0
var density = 5.0
var block = true
var block_spam = true

var alive = true
var mob = null
@onready var pivot = $CameraOrigin
@onready var anim_tree = $AnimationTree
@onready var armature = $Visuals
@onready var prompt = $Prompt

@export var sensitivity = 0.5
# Get the gravity from the project settings to be synced with RigidBody nodes.
@export var gravity = 9.8

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	#pass

func _input(event):
	if (event is InputEventMouseMotion) and alive:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		armature.rotate_y(deg_to_rad(event.relative.x * sensitivity))
		pivot.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))

func _physics_process(delta):
	prompt.text = ""
	
	if (self.position.y < -20):
		die()
		
	if alive:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle jump.
		if jumping():
			velocity.y = jump
		
		if Input.is_action_just_pressed("Create") and block and !block_spam:
			place_block()
		
		if (Input.is_action_pressed("Create")) and block_spam:
			#print ("Create")
			place_block()
			
		#if (Input.is_action_pressed("Punch")):
		#	anim_tree.set("parameters/conditions/punch", true)
		#else:
		#	anim_tree.set("parameters/conditions/punch", false)
			

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
		anim_tree.set("parameters/conditions/running", _running())
		anim_tree.set("parameters/conditions/run_to_idle", !_running())
		anim_tree.set("parameters/conditions/jump", jumping())
		anim_tree.set("parameters/conditions/jump_to_idle", is_on_floor())
		anim_tree.set("parameters/conditions/punch", punching())

		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			armature.look_at(position + direction)
			#print("position:", position)
			#print("direction:", direction)
			#print("position - direction:", (position - direction))
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
		#rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
			
		# Iterate through all collisions that occurred this frame
		for index in range(get_slide_collision_count()):
			# We get one of the collisions with the player
			var collision = get_slide_collision(index)
			
			
			# If the collision is with ground
			if collision.get_collider() == null:
				continue
			
			#if collision.get_collider() != null:
				#print("Collided with:", collision.get_collider().name)
				
			if collision.get_collider().is_in_group("terminal"):
				prompt.text = "Press E restore"
				if (Input.is_action_pressed("Interact")):
					var terminal = collision.get_collider()
					terminal.restore_terminal()
				break
			
			if collision.get_collider().is_in_group("teleporter"):
				prompt.text = "Press E to Teleport"
				if (Input.is_action_pressed("Interact")):
					var teleporter = collision.get_collider()
					teleporter.teleport()
				break
			
			# If the collider is with a mob
			if collision.get_collider().is_in_group("monster"):
				mob = collision.get_collider()
				break
				
			# If the collider is with an orb
			if collision.get_collider().is_in_group("orbs"):
				var orb = collision.get_collider()
				orb.pick_up()
				break

		move_and_slide()

func _running():
	return Input.is_action_pressed("Up") or Input.is_action_pressed("Down") or Input.is_action_pressed("Left") or Input.is_action_pressed("Right")

func punching():
	return Input.is_action_pressed("Punch")
	
func jumping():
	return Input.is_action_pressed("ui_accept") and is_on_floor()
	
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

func _hit_finished():
	if mob != null:
		if global_position.distance_to(mob.global_position) < ATTACK_RANGE + 0.7:
			mob.die()
	
	
func place_block():
	var player_position = $"../GridMap".local_to_map($CollisionShape3D.global_transform.origin - Vector3(0,1,0))
	var player_position_int = Vector3i(round(player_position.x), round(player_position.y), round(player_position.z))
	if ($"../GridMap".get_cell_item(player_position_int) == -1):
		#print($"../GridMap".local_to_map($PlayerMesh.global_transform.origin - Vector3(0,2,0)))
		#print($PlayerMesh.global_transform.origin - Vector3(0, 2, 0))
		$"../GridMap".set_cell_item(player_position_int, 4)
	
# And this function at the bottom.
func die():
	hit.emit()
	visible = false
	alive = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_mob_detector_body_entered(body):
	#die()
	pass

func camera_set():
	$CameraOrigin/SpringArm3D/Camera3D.set_current(true)
