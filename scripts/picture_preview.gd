extends CanvasLayer
class_name PicturePreview

var texture: Texture = null
@onready var texture_rect: TextureRect = $ColorRect/PanelContainer/HBoxContainer/MarginContainer/TextureRect


func _ready() -> void:
	set_picture(texture)


func set_picture(new_texture: Texture) -> void:
	texture_rect.texture = new_texture


func _on_close_button_pressed() -> void:
	queue_free()
