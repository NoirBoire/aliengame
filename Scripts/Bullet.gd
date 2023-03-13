extends CharacterBody2D

var motion = Vector2()
var motion_x = 0
var motion_y = 0
@onready var particle = preload("res://Scenes/Nodes/BulletParticle.tscn")
@onready var particol = particle.instantiate()

func _ready():
	$LifeTimer.wait_time = 3
	$LifeTimer.start()
	$Hit.transform.rotated(90*(randf_range(0, 4)))

func _physics_process(_delta):
	set_velocity(motion)
	move_and_slide()
	motion.x = motion_x
	motion.y = motion_y
	if $Area2D.overlaps_area(Global.player.get_node("Hurtbox")):
		if $StartTimer.is_stopped():
			Global.player.take_damage()
			die()
	for body in $Area2D.get_overlapping_bodies():
		if body is TileMap:
			die()


func _on_LifeTimer_timeout() -> void:
	die()

func die():
	get_parent().add_child(particol)
	if motion.x > 0:
		particol.get_node("SubViewportContainer").get_node("SubViewport").get_node("GPUParticles2D").process_material.set_direction(Vector3(-1, 0, 0))
	else:
		particol.get_node("SubViewportContainer").get_node("SubViewport").get_node("GPUParticles2D").process_material.set_direction(Vector3(1, 0, 0))
	particol.get_node("SubViewportContainer").get_node("SubViewport").get_node("GPUParticles2D").emitting = true
	particol.position = position
	queue_free()
