extends Node2D

export var wait_time := 0.0
export var one_shot := true
export var autostart := false

var time_left := 0.0

signal is_done

func _process(delta):
	
	if time_left > 0.0:
		time_left -= delta*(1/Engine.time_scale)
	
	elif time_left < 0.0:
		time_left = 0.0

	if time_left <= 0.0:
		emit_signal("is_done")

func stop():
	time_left = 0.0

func start():
	time_left = wait_time

func is_stopped():
	if time_left <= 0:
		return true
