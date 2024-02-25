extends Label

var orb_collected = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _orb_collected():
	orb_collected += 1
	text = "Orbs Collected: %s/4" % orb_collected
