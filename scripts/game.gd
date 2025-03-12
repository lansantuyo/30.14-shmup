extends Node2D
@onready var spawnpoint = $Spawnpoint
@onready var laser_container = $laser_container
@onready var timer = $enemy_spawn_timer
@onready var enemy_container = $enemy_container

var player = null
@export var enemy_scenes : Array[PackedScene] = []
@export var formation_manager_scene : PackedScene

@export var formation_width = 5
@export var base_formation_gap = 70
@export var base_formation_rows = 2
@export var max_formation_rows = 6
@export var base_formation_row_offset = 70
@export var formation_pause = 80.0
@export var gap_variation_percent = 30.0
@export var grid_gap_chance = 0.1

@export var difficulty_increment := 0.2
@export var max_difficulty_multiplier := 3.0
var current_formation_level := 1
var current_difficulty_multiplier := 1.0

var spawn_position = Vector2(0, -50)
var is_pausing_between_formations = false
var current_formation = null
var should_spawn_next_formation = false

enum FormationType {
	GRID,
	ZIGZAG,
	DIAMOND,
	V_SHAPE,
	RANDOM,
	WAVE,
	TRIANGLE
}

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	assert(player!=null)
	player.global_position = spawnpoint.global_position
	player.pew_pew.connect(_on_player_laser_fired)
	
	randomize()
	
	spawn_formation()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		
	if should_spawn_next_formation:
		should_spawn_next_formation = false
		spawn_formation()

func _on_player_laser_fired(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)

func _on_enemy_spawn_timer_timeout() -> void:
	if is_pausing_between_formations:
		is_pausing_between_formations = false
		spawn_formation()

func randomize_spacing(base_value):
	var variation_amount = base_value * (gap_variation_percent / 100.0)
	return base_value + randf_range(0, variation_amount)

func spawn_formation():
	if current_formation_level > 1:
		current_difficulty_multiplier = min(
			1.0 + (current_formation_level - 1) * difficulty_increment,
			max_difficulty_multiplier
		)
	
	var current_rows = min(
		base_formation_rows + int((current_formation_level - 1) / 2),
		max_formation_rows
	)
	
	var current_formation_gap = randomize_spacing(base_formation_gap)
	var current_row_offset = randomize_spacing(base_formation_row_offset)
	
	var screen_width = get_viewport_rect().size.x
	var formation_width_pixels = (formation_width - 1) * current_formation_gap
	var min_x = current_formation_gap
	var max_x = screen_width - formation_width_pixels - current_formation_gap
	
	spawn_position.x = randf_range(min_x, max_x)
	spawn_position.y = -30
	
	current_formation = formation_manager_scene.instantiate()
	current_formation.global_position = spawn_position
	current_formation.initial_descent_steps = 3  
	
	current_formation.move_delay = max(3.0 / current_difficulty_multiplier, 0.5)
	current_formation.speed = min(400 * current_difficulty_multiplier, 800)
	
	current_formation.formation_destroyed.connect(_on_formation_destroyed)
	
	enemy_container.add_child(current_formation)
	
	var available_formations = []
	available_formations.append(FormationType.GRID)
	available_formations.append(FormationType.ZIGZAG)
	
	if current_formation_level >= 3:
		available_formations.append(FormationType.V_SHAPE)
	if current_formation_level >= 4:
		available_formations.append(FormationType.WAVE)
	if current_formation_level >= 5:
		available_formations.append(FormationType.TRIANGLE)
	if current_formation_level >= 6:
		available_formations.append(FormationType.DIAMOND)
	if current_formation_level >= 7:
		available_formations.append(FormationType.RANDOM)
	
	var formation_type = available_formations.pick_random()
	
	var max_enemies = current_rows * formation_width
	
	match formation_type:
		FormationType.GRID:
			spawn_grid_formation(current_rows, formation_width, current_formation_gap, current_row_offset)
		FormationType.ZIGZAG:
			spawn_zigzag_formation(current_rows, formation_width, current_formation_gap, current_row_offset)
		FormationType.DIAMOND:
			spawn_diamond_formation(current_rows, current_formation_gap, current_row_offset)
		FormationType.V_SHAPE:
			spawn_v_shape_formation(current_rows, current_formation_gap, current_row_offset)
		FormationType.RANDOM:
			spawn_random_formation(max_enemies, current_formation_gap, current_row_offset)
		FormationType.WAVE:
			spawn_wave_formation(current_rows, formation_width, current_formation_gap, current_row_offset)
		FormationType.TRIANGLE:
			spawn_triangle_formation(current_rows, current_formation_gap, current_row_offset)
	
	print("Formation Level: ", current_formation_level, 
		  " - Type: ", FormationType.keys()[formation_type],
		  " - Gap: ", current_formation_gap,
		  " - Row Offset: ", current_row_offset)
	
	current_formation_level += 1
	
	is_pausing_between_formations = false

func spawn_grid_formation(rows, width, gap, row_offset):
	for row in range(rows):
		for column in range(width):
			if randf() < grid_gap_chance:
				continue
				
			var pos = Vector2(
				spawn_position.x + column * gap,
				spawn_position.y - row * row_offset
			)
			spawn_enemy(pos)

func spawn_zigzag_formation(rows, width, gap, row_offset):
	for row in range(rows):
		var offset = 0
		if row % 2 == 1:
			offset = gap / 2
			
		for column in range(width):
			if randf() < grid_gap_chance * 0.75:
				continue
				
			var pos = Vector2(
				spawn_position.x + column * gap + offset,
				spawn_position.y - row * row_offset
			)
			spawn_enemy(pos)

func spawn_diamond_formation(rows, gap, row_offset):
	var center_x = spawn_position.x + (formation_width / 2) * gap
	var max_width = min(rows, formation_width)
	
	for row in range((max_width + 1) / 2):
		var enemies_in_row = 1 + (row * 2)
		var row_start_x = center_x - (row * gap)
		
		for i in range(enemies_in_row):
			if randf() < grid_gap_chance * 0.5:
				continue
				
			var pos = Vector2(
				row_start_x + (i * gap),
				spawn_position.y - (row * row_offset)
			)
			spawn_enemy(pos)
	
	for row in range(1, max_width / 2 + 1):
		var actual_row = (max_width + 1) / 2 + row - 1
		var enemies_in_row = max_width - (row * 2)
		if enemies_in_row <= 0:
			break
			
		var row_start_x = center_x - ((enemies_in_row - 1) / 2 * gap)
		
		for i in range(enemies_in_row):
			if randf() < grid_gap_chance * 0.5:
				continue
				
			var pos = Vector2(
				row_start_x + (i * gap),
				spawn_position.y - (actual_row * row_offset)
			)
			spawn_enemy(pos)

func spawn_v_shape_formation(rows, gap, row_offset):
	var center_x = spawn_position.x + (formation_width / 2) * gap
	var max_width = min(rows, formation_width)
	
	for row in range(max_width):
		if randf() < grid_gap_chance * 0.3:
			continue
			
		var left_pos = Vector2(
			center_x - (row * gap / 2),
			spawn_position.y - (row * row_offset)
		)
		spawn_enemy(left_pos)
		
		if row > 0:
			if randf() < grid_gap_chance * 0.3:
				continue
				
			var right_pos = Vector2(
				center_x + (row * gap / 2),
				spawn_position.y - (row * row_offset)
			)
			spawn_enemy(right_pos)

func spawn_wave_formation(rows, width, gap, row_offset):
	var amplitude = gap * 0.75
	var frequency = 0.6
	var phase_offset = randf_range(0, 2 * PI)
	
	for row in range(rows):
		for column in range(width):
			if randf() < grid_gap_chance:
				continue
				
			var wave_offset_y = sin((column * frequency) + phase_offset) * amplitude
			var wave_offset_x = cos((row * frequency) + phase_offset) * (amplitude * 0.5)
			
			var pos = Vector2(
				spawn_position.x + (column * gap) + wave_offset_x,
				spawn_position.y - (row * row_offset) + wave_offset_y
			)
			spawn_enemy(pos)

func spawn_triangle_formation(rows, gap, row_offset):
	var center_x = spawn_position.x + (formation_width / 2) * gap
	
	for row in range(rows):
		var enemies_in_row = row + 1
		var row_start_x = center_x - (row * gap / 2)
		
		for i in range(enemies_in_row):
			if randf() < grid_gap_chance * 0.7:
				continue
				
			var pos = Vector2(
				row_start_x + (i * gap),
				spawn_position.y - (row * row_offset)
			)
			spawn_enemy(pos)

func spawn_random_formation(max_enemies, gap, row_offset):
	var screen_width = get_viewport_rect().size.x
	
	var min_x = screen_width * 0.05
	var max_x = screen_width * 0.95
	var min_y = spawn_position.y
	var max_y = spawn_position.y - (max_formation_rows * row_offset * 1.2)
	
	var grid_cols = 8
	var grid_rows = 5
	var cell_width = (max_x - min_x) / grid_cols
	var cell_height = (min_y - max_y) / grid_rows
	
	var grid_cells = []
	for row in range(grid_rows):
		for col in range(grid_cols):
			grid_cells.append(Vector2(col, row))
	
	grid_cells.shuffle()
	
	for i in range(min(max_enemies, grid_cells.size())):
		var cell = grid_cells[i]
		var base_x = min_x + (cell.x * cell_width)
		var base_y = max_y + (cell.y * cell_height)
		
		var pos = Vector2(
			base_x + randf_range(0, cell_width),
			base_y + randf_range(0, cell_height)
		)
		spawn_enemy(pos)

func spawn_enemy(pos):
	var enemy_scene = enemy_scenes.pick_random()
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	
	enemy.can_shoot = true
	enemy.shoot_delay_min = max(2.0 / current_difficulty_multiplier, 0.5)
	enemy.shoot_delay_max = max(5.0 / current_difficulty_multiplier, 1.5)
	
	if current_formation_level > 3:
		enemy.max_health = min(3 + current_formation_level / 2, 8)
		enemy.current_health = enemy.max_health
	
	enemy_container.add_child(enemy)
	
	current_formation.add_enemy(enemy)

func _on_formation_destroyed() -> void:
	should_spawn_next_formation = true

func game_over():
	print("Game Over! You reached formation level: ", current_formation_level)
	get_tree().reload_current_scene()
