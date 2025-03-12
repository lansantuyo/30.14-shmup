class_name pLaser extends Area2D

@export var speed = 600

func _process(delta: float) -> void:
	global_position.y += -speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func hit():
	queue_free()
