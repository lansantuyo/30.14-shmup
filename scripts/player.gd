class_name Player extends CharacterBody2D

@export var speed = 300

@onready var muzzle = $Muzzle

var lazer_scene = preload("res://scenes/lazer.tscn")
signal pew_pew(lazer_scene, location)

var reload := false
@export var reload_speed := 0.2

func _process(delata):
	if Input.is_action_pressed("shoot"):
		if !reload:
			reload = true
			shoot()
			await get_tree().create_timer(reload_speed).timeout
			reload = false

func _physics_process(delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	velocity = direction * speed
	
	move_and_slide()

func shoot():
	pew_pew.emit(lazer_scene, muzzle.global_position)

func collide():
	pass
