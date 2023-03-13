extends Node

func _ready():
	Global.viewport_container = get_node("SubViewportContainer")
	Global.viewport = $SubViewportContainer/SubViewport
