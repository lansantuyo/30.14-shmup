class_name FormationManager extends Node2D

@export var move_delay = 2.0
@export var grid_size = 64
@export var speed = 200
@export var horizontal_steps = 2
@export var direction = 1  # 1 = right, -1 = left
@export var initial_descent_steps = 2

signal formation_destroyed

var enemies = []
var target_position = Vector2.ZERO
var is_moving = false
var move_timer = 0.0
var current_step = 0
var move_direction = Vector2.DOWN
var initial_descent_remaining = 0

var screen_size := Vector2.ZERO
var edge_margin := 40.0

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	initial_descent_remaining = initial_descent_steps
	move_direction = Vector2.DOWN
	target_position = global_position + move_direction * grid_size

func _process(delta: float) -> void:
	if enemies.is_empty():
		formation_destroyed.emit()
		queue_free()
		return
		
	if is_moving:
		var move_vector = (target_position - global_position).normalized() * speed * delta
		global_position += move_vector
		
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.follow_formation_movement(move_vector)
		
		if global_position.distance_to(target_position) < 5:
			global_position = target_position
			is_moving = false
			move_timer = 0.0
	else:
		move_timer += delta
		if move_timer >= move_delay:
			if initial_descent_remaining > 0:
				move_direction = Vector2.DOWN
				initial_descent_remaining -= 1
			else:
				current_step += 1
				if current_step >= horizontal_steps:
					direction *= -1
					current_step = 0
					move_direction = Vector2.DOWN
				else:
					move_direction = Vector2.RIGHT * direction
			
			target_position = global_position + move_direction * grid_size
			
			if would_exceed_bounds(target_position):
				if move_direction.y == 0:
					direction *= -1
					current_step = 0
					move_direction = Vector2.DOWN
					target_position = global_position + move_direction * grid_size
				else:
					move_direction = Vector2.RIGHT * direction
					target_position = global_position + move_direction * grid_size
			
			is_moving = true

func would_exceed_bounds(new_pos: Vector2) -> bool:
	for enemy in enemies:
		if !is_instance_valid(enemy):
			continue
			
		var enemy_new_pos = new_pos + enemy.formation_offset
		
		if enemy_new_pos.x < edge_margin or enemy_new_pos.x > screen_size.x - edge_margin:
			return true
		if enemy_new_pos.y > screen_size.y - edge_margin:
			return true
	
	return false

func add_enemy(enemy) -> void:
	enemies.append(enemy)
	enemy.formation_offset = enemy.global_position - global_position
	enemy.formation = self

func remove_enemy(enemy) -> void:
	enemies.erase(enemy)
