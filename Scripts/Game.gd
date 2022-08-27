extends Node

func _ready():
	Global.viewport_container = get_node("ViewportContainer")
	Global.viewport = $ViewportContainer/Viewport
