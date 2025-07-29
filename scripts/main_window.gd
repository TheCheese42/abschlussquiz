extends CanvasLayer

@onready var options: CenterContainer = $MarginContainer/Options


func _on_options_pressed() -> void:
	options.visible = not options.visible
