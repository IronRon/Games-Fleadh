extends Control

var difficulty = ""

signal quit
signal retry
signal start(difficulty)
signal game_over

@onready var timer = $PlayerHUD/HealthBar/Timer
@onready var damage_bar = $PlayerHUD/HealthBar/DamageBar
@onready var health_bar = $PlayerHUD/HealthBar
@onready var timerlabel = $PlayerHUD/TimerLabel
@onready var LevelTimer = $PlayerHUD/LevelTimer

var level_time = 120
var terminal_fix_time = 20

var health = 0 : set = _set_health
func _set_health(new_health):
	var prev_health = health
	health = min(health_bar.max_value, new_health)
	health_bar.value = health
	
	if health <=0:
		health_bar.queue_free()
		
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

var orb_collected = 0
var terminals_restored = 0
var terminals : String = "0" : set = set_number_of_terminals
func set_number_of_terminals(val:String)->void:
	terminals = val

enum OrbType {
	STRENGTH,
	SPEED,
	JUMP,
	TELEPORT,
	BLOCK,
	BLOCK_SPAM
}

# Called when the node enters the scene tree for the first time.
func _ready():
	text_update()
	init_health(100)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _process(delta):
	timerlabel.text = "%02d:%02d" % time_left()

func init_health(_health):
	health = _health
	health_bar.max_value = health
	health_bar.value = health
	damage_bar.max_value = health
	damage_bar.value = health


func _orb_collected(orb_type):
	
	orb_collected += 1
	match orb_type:
		OrbType.STRENGTH:
			$OrbPickUpRect/PickUpText.text = "STRENGTH Orb Collected"
			$PlayerHUD/StrengthOrb.visible = true
			$Menu/StrengthOrb.visible = true
		OrbType.SPEED:
			$OrbPickUpRect/PickUpText.text = "SPEED Orb Collected"
			$PlayerHUD/SpeedOrb.visible = true
			$Menu/SpeedOrb.visible = true
		OrbType.JUMP:
			$OrbPickUpRect/PickUpText.text = "JUMP Orb Collected"
			$PlayerHUD/JumpOrb.visible = true
			$Menu/JumpOrb.visible = true
		OrbType.TELEPORT:
			$OrbPickUpRect/PickUpText.text = "TELEPORT Orb Collected"
			$PlayerHUD/TeleportOrb.visible = true
			$Menu/TeleportOrb.visible = true
		OrbType.BLOCK:
			$OrbPickUpRect/PickUpText.text = "BLOCK Orb Collected"
			$PlayerHUD/BlockOrb.visible = true
			$Menu/BlockOrb.visible = true
		OrbType.BLOCK_SPAM:
			$OrbPickUpRect/PickUpText.text = "BLOCK_SPAM Orb Collected"
			$PlayerHUD/Block_SpamOrb.visible = true
			$Menu/Block_SpamOrb.visible = true
	text_update()

func _terminal_restored():
	terminals_restored += 1
	LevelTimer.wait_time = LevelTimer.time_left + terminal_fix_time
	LevelTimer.start()
	text_update()
	
func _prompt_update(prompt: String):
	$PlayerHUD/Prompt.text = prompt

func text_update():
	$PlayerHUD/OrbCollectedLabel.text = "Orbs Collected: %s/6" % orb_collected
	$PlayerHUD/TerminalsRestoredLabel.text = "Terminals Restored: %s/%s" % [terminals_restored, terminals]
	
func died_rect():
	$Menu.color = Color.hex(0xff161753)
	$Menu/DeadText.visible = true
	_show_menu()
	
func player_hit(damage):
	health -= damage
	$PlayerHUD/HitRect.visible = true
	await get_tree().create_timer(0.2).timeout
	$PlayerHUD/HitRect.visible = false

	
func orb_rect():
	$OrbPickUpRect.visible = true
	await get_tree().create_timer(0.2).timeout
	$OrbPickUpRect.visible = false


func _on_quit_buuton_pressed():
	quit.emit()

func _on_retry_button_pressed():
	_on_close_pressed()
	retry.emit()

func _show_menu():
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Menu.show()
	
func show_HUD():
	$PlayerHUD.visible = true
	start_level_timer()
	
func start_level_timer():
	LevelTimer.wait_time = level_time
	LevelTimer.start()

func time_left():
	var time_left = LevelTimer.time_left
	var minute = floor(time_left/60)
	var second = int(time_left) % 60
	return [minute, second]

func _on_close_pressed():
	$Menu.hide()
	$Menu/DeadText.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

func _on_start_pressed():
	$StartScreen.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	start.emit(difficulty)
	

func _on_timer_timeout():
	damage_bar.value = health

func _on_hard_pressed():
	difficulty = "hard"
	level_time = 300
	terminal_fix_time = 10
	_on_start_pressed()

func _on_easy_pressed():
	difficulty = "easy"
	level_time = 180
	terminal_fix_time = 20
	_on_start_pressed()

func _on_normal_pressed():
	difficulty = "normal"
	level_time = 240
	terminal_fix_time = 15
	_on_start_pressed()


func _on_level_timer_timeout():
	game_over.emit()
