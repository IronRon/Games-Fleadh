extends Control

signal quit
signal retry

var orb_collected = 0

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _orb_collected(orb_type):
	var label_text
	
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

func text_update():
	$OrbCollectedLabel.text = "Orbs Collected: %s/6" % orb_collected


func _on_quit_buuton_pressed():
	quit.emit()


func _on_retry_button_pressed():
	retry.emit()
