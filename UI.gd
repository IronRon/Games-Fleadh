extends Control

signal quit
signal retry

var orb_collected = 0
var terminals_restored = 0
var terminals : String = "0" : set = set_number_of_terminals
func set_number_of_terminals(val:String)->void:
	terminals = val

enum OrbType {
	STRENGTH,
	SPEED,
	JUMP,
	DENSITY,
	BLOCK,
	BLOCK_SPAM
}

# Called when the node enters the scene tree for the first time.
func _ready():
	text_update()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _orb_collected(orb_type):
	
	orb_collected += 1
	match orb_type:
		OrbType.STRENGTH:
			$OrbPickUpRect/PickUpText.text = "STRENGTH Orb Collected"
			
		OrbType.SPEED:
			$OrbPickUpRect/PickUpText.text = "SPEED Orb Collected"
			
		OrbType.JUMP:
			$OrbPickUpRect/PickUpText.text = "JUMP Orb Collected"
			
		OrbType.DENSITY:
			$OrbPickUpRect/PickUpText.text = "DENSITY Orb Collected"
			
		OrbType.BLOCK:
			$OrbPickUpRect/PickUpText.text = "BLOCK Orb Collected"
			
		OrbType.BLOCK_SPAM:
			$OrbPickUpRect/PickUpText.text = "BLOCK_SPAM Orb Collected"
	text_update()

func _terminal_restored():
	terminals_restored += 1
	text_update()
	
func _prompt_update(prompt: String):
	$Prompt.text = prompt

func text_update():
	$OrbCollectedLabel.text = "Orbs Collected: %s/6" % orb_collected
	$TerminalsRestoredLabel.text = "Terminals Restored: %s/%s" % [terminals_restored, terminals]
	
func died_rect():
	$Menu.color = Color.hex(0xff161753)
	$Menu/DeadText.visible = true
	_show_menu()

	
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


func _on_close_pressed():
	$Menu.hide()
	$Menu/DeadText.visible = false
	$Menu.color = Color.hex(0x0000002c)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false


func _on_start_pressed():
	$StartScreen.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
