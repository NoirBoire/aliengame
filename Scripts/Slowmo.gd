extends Node

var is_slowmo := false

export var normal_time_scale := 1
export var slowmo_time_scale := 0.075

onready var tween := $Tween

func enter_slowmo():
	tween.stop_all()
	tween.interpolate_property(Engine, "time_scale", Engine.time_scale, slowmo_time_scale, 
		0.05, Tween.TRANS_EXPO, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	
	#start_slowmo()
	
func start_slowmo():
	
	Engine.time_scale = slowmo_time_scale

func end_slowmo():
	tween.stop_all()
	Engine.time_scale = normal_time_scale
