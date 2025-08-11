extends CanvasLayer

var credits_scene: PackedScene = preload("res://scenes/credits.tscn")

@onready var language_button: OptionButton = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LanguageButton
@onready var keep_screen_on_check: CheckBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/KeepScreenOnCheck
@onready var backup_spin: SpinBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/BackupSpin

var locales: PackedStringArray = []


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
