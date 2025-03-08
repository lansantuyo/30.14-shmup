class_name Enemy1 extends Area2D

@export var speed = 200

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.y += speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func hit():
	queue_free()
	
func die():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is pLazer:
		area.hit()
		hit()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collide()
		queue_free()
		
