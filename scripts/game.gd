extends Node2D

@onready var spawnpoint = $Spawnpoint
@onready var lazer_container = $lazer_container

var player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	assert(player!=null)
	player.global_position = spawnpoint.global_position
	player.pew_pew.connect(_on_player_pew_pew)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()


func _on_player_pew_pew(lazer_scene, location):
	var lazer = lazer_scene.instantiate()
	lazer.global_position = location
	lazer_container.add_child(lazer)
