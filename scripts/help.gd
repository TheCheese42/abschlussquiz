extends CanvasLayer
class_name HelpDialog


func _ready() -> void:
	GlobalFunctions.apply_theme_for_children(self)


func _on_back_button_pressed() -> void:
	queue_free()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		queue_free()
