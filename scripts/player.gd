class_name Player extends CharacterBody2D

@export var speed = 300
@export var max_health := 3
var current_health: int

@onready var muzzle = $Muzzle
@onready var animated_sprite = $AnimatedSprite2D

var laser_scene = preload("res://scenes/laser.tscn")
var explosion_scene = preload("res://scenes/explosion.tscn")
var hit_effect_scene = preload("res://scenes/hit.tscn")
signal pew_pew(laser_scene, location)

var reload := false
@export var reload_speed := 0.2

var screen_size := Vector2.ZERO
var player_size := Vector2.ZERO

var was_moving := false
var is_invulnerable := false

func _ready() -> void:
	current_health = max_health
	
	screen_size = get_viewport_rect().size
	
	player_size = Vector2(88, 88)
	animated_sprite.play("idle")

func _process(delta):
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
	
	var half_screen_height = screen_size.y / 2
	global_position.x = clamp(global_position.x, player_size.x/2, screen_size.x - player_size.x/2)
	global_position.y = clamp(global_position.y, half_screen_height, screen_size.y - player_size.y/2)
	
	var is_moving = velocity.length() > 0.1
	
	if is_moving != was_moving:
		if is_moving:
			animated_sprite.play("move")
		else:
			animated_sprite.play("idle")
		
		was_moving = is_moving
	
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0

func shoot():
	pew_pew.emit(laser_scene, muzzle.global_position)

func collide():
	pass

func take_damage() -> void:
	if is_invulnerable:
		return
		
	current_health -= 1
	
	if current_health > 0:
		spawn_hit_effect()
		
		is_invulnerable = true
		for i in range(5):
			animated_sprite.modulate.a = 0.3
			await get_tree().create_timer(0.1).timeout
			animated_sprite.modulate.a = 1.0
			await get_tree().create_timer(0.1).timeout
		is_invulnerable = false
	else:
		die()

func spawn_hit_effect() -> void:
	var hit_effect = hit_effect_scene.instantiate()
	hit_effect.global_position = global_position
	get_tree().current_scene.add_child(hit_effect)

func die() -> void:
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
	visible = false
	
	await get_tree().create_timer(0.5).timeout
	
	var game = get_tree().get_first_node_in_group("game")
	game.game_over()
