@tool
extends Resource
class_name OptionsSave

@export var first_launch: bool = true
@export var language: String = OS.get_locale_language()
@export var keep_screen_on: bool = true
@export var window_mode: DisplayServer.WindowMode = DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED
@export var window_size: Vector2i = Vector2i(800, 840)
@export var window_pos: Vector2i = DisplayServer.screen_get_size() / Vector2i(2, 2)
@export var backup_count: int = 20

var version: String


func _init() -> void:
	version = ProjectSettings.get_setting("application/config/version")
