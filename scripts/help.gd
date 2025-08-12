extends CanvasLayer
class_name HelpDialog


func _on_back_button_pressed() -> void:
	queue_free()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		queue_free()
