extends Control

@onready var base_pos: Vector2 = position


func _process(_delta: float) -> void:
	position = base_pos + Vector2(randf() * 10 - 5, randf() * 10 - 5)
