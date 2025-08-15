extends CanvasLayer

var credits_scene: PackedScene = preload("res://scenes/credits.tscn")

@onready var language_button: OptionButton = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LanguageButton
@onready var keep_screen_on_check: CheckBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/KeepScreenOnCheck
@onready var backup_spin: SpinBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/BackupSpin
@onready var window_mode_button: OptionButton = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/WindowModeButton

var locales: PackedStringArray = []


const WINDOW_MODE_INDEX: Dictionary[DisplayServer.WindowMode, int] = {
	DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN: 0,
	DisplayServer.WindowMode.WINDOW_MODE_WINDOWED: 1,
	DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED: 2,
}
const WINDOW_MODE_INDEX_REVERSE: Dictionary[int, DisplayServer.WindowMode] = {
	0: DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN,
	1: DisplayServer.WindowMode.WINDOW_MODE_WINDOWED,
	2: DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED,
}


func _ready() -> void:
	locales = TranslationServer.get_loaded_locales()
	var i: int = 0
	for locale: String in locales:
		language_button.add_item(TranslationServer.get_locale_name(locale))
		if TranslationServer.get_locale() == locale:
			language_button.selected = i
		i += 1
	keep_screen_on_check.button_pressed = GlobalVars.options_save.keep_screen_on
	backup_spin.value = GlobalVars.options_save.backup_count
	on_resize(DisplayServer.window_get_size())


func _on_close_pressed() -> void:
	visible = false


func _on_language_button_item_selected(index: int) -> void:
	GlobalVars.options_save.language = locales[index]
	TranslationServer.set_locale(locales[index])
	GlobalFunctions.save_options()


func _on_keep_screen_on_check_toggled(toggled_on: bool) -> void:
	GlobalVars.options_save.keep_screen_on = toggled_on
	GlobalFunctions.save_options()
	GlobalFunctions.apply_options()


func _on_backup_spin_value_changed(value: float) -> void:
	GlobalVars.options_save.backup_count = round(value)
	GlobalFunctions.save_options()


func _on_credits_pressed() -> void:
	var credits: CanvasLayer = credits_scene.instantiate()
	add_child(credits)


func _on_window_mode_button_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(WINDOW_MODE_INDEX_REVERSE[index])


func on_resize(_new_size: Vector2i) -> void:
	var window_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if window_mode not in WINDOW_MODE_INDEX:
		if window_mode == DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			window_mode = DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
		else:
			window_mode = DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
	window_mode_button.selected = WINDOW_MODE_INDEX[window_mode]


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		visible = false
