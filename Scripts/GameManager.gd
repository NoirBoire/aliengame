extends Node

func _ready():
	Engine.set_max_fps(60)

func _process(_delta):
	if Input.is_action_pressed("ui_alt") && Input.is_action_just_pressed("ui_enter") && $FullScreenTimer.is_stopped():
		if get_window().mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			$FullScreenTimer.start()
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			$FullScreenTimer.start()
