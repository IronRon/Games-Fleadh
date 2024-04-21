extends StaticBody3D

signal collected

func pick_up():
	collected.emit()
	queue_free()
