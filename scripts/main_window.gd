extends CanvasLayer

@onready var options: CenterContainer = $MarginContainer/Options


func _on_options_pressed() -> void:
	options.visible = not options.visible


func _on_create_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/create_quiz.tscn")
