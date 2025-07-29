@tool
extends Resource
class_name OptionsSave


func _init() -> void:
	version = FileAccess.get_file_as_string("res://version.txt")

var version: String = FileAccess.get_file_as_string("res://version.txt")

@export var language: String = OS.get_locale_language()
@export var keep_screen_on: bool = true
@export var window_mode: DisplayServer.WindowMode = DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED
@export var window_size: Vector2i = Vector2i(800, 600)
