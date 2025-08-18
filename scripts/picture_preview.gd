extends CanvasLayer
class_name PicturePreview

@export var margin_sides: int = 100
@export var margin_top_bottom: int = 80

@onready var texture_rect: TextureRect = $ColorRect/MarginContainer/PanelContainer/HBoxContainer/MarginContainer/TextureRect
@onready var margin_container: MarginContainer = $ColorRect/MarginContainer

var texture: Texture = null


func _ready() -> void:
	set_picture(texture)
	margin_container.add_theme_constant_override("margin_bottom", margin_top_bottom)
	margin_container.add_theme_constant_override("margin_top", margin_top_bottom)
	margin_container.add_theme_constant_override("margin_left", margin_sides)
	margin_container.add_theme_constant_override("margin_right", margin_sides)


func set_picture(new_texture: Texture) -> void:
	texture_rect.texture = new_texture


func _on_close_button_pressed() -> void:
	queue_free()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		queue_free()
