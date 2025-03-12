extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	animated_sprite.play("hit")

func _on_animation_finished() -> void:
	queue_free()
