class_name Enemy1 extends Area2D

var formation = null
var formation_offset = Vector2.ZERO

@export var max_health := 3
var current_health : int

@export var can_shoot := true
@export var shoot_delay_min := 4.0
@export var shoot_delay_max := 8.0
var shoot_timer := 0.0
var next_shoot_time := 0.0
var initial_delay := 3.0
var laser_scene = preload("res://scenes/enemy_laser.tscn")

@onready var muzzle = $Muzzle

func _ready() -> void:
	current_health = max_health
	
	randomize()
	next_shoot_time = initial_delay + randf_range(shoot_delay_min, shoot_delay_max)

func _process(delta: float) -> void:
	if can_shoot:
		shoot_timer += delta
		if shoot_timer >= next_shoot_time:
			shoot()
			shoot_timer = 0
			next_shoot_time = randf_range(shoot_delay_min, shoot_delay_max)

func follow_formation_movement(move_vector: Vector2) -> void:
	global_position += move_vector

func shoot() -> void:
	var laser = laser_scene.instantiate()
	laser.global_position = muzzle.global_position
	
	var laser_container = get_node("/root/Game/laser_container")
	if laser_container:
		laser_container.add_child(laser)

func take_damage(amount := 1) -> void:
	current_health -= amount
	
	if current_health > 0:
		spawn_hit_effect()
	else:
		destroy()

func destroy():
	if formation:
		formation.remove_enemy(self)
	spawn_explosion()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	destroy()

var explosion_scene = preload("res://scenes/explosion.tscn")
var hit_effect_scene = preload("res://scenes/hit.tscn")

func _on_area_entered(area: Area2D) -> void:
	if area is pLaser:
		area.hit()
		take_damage(1)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage()
		destroy()
		
func spawn_explosion() -> void:
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
func spawn_hit_effect() -> void:
	var hit_effect = hit_effect_scene.instantiate()
	hit_effect.global_position = global_position
	get_tree().current_scene.add_child(hit_effect)
