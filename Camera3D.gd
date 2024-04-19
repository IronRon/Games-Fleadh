extends Camera3D

signal animation_complete

func animation_done():
	animation_complete.emit()
