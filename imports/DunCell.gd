@tool
extends Node3D


func remove_wall_up():
	$wall_up.free()
func remove_wall_down():
	$wall_down.free()
func remove_wall_left():
	$wall_left.free()
func remove_wall_right():
	$wall_right.free()
func remove_door_up():
	$door_up.free()
func remove_door_down():
	$door_down.free()
func remove_door_left():
	$door_left.free()
func remove_door_right():
	$door_right.free()
func remove_ceiling():
	$ceiling.free()
	
func only_floor():
	remove_wall_up()
	remove_wall_down()
	remove_wall_left()
	remove_wall_right()
	remove_door_up()
	remove_door_down()
	remove_door_left()
	remove_door_right()
	remove_ceiling()
	
