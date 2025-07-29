extends CenterContainer

@onready var language_button: OptionButton = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/LanguageButton
@onready var keep_screen_on_check: CheckBox = $PanelContainer/ColorRect/MarginContainer/VBoxContainer/KeepScreenOnCheck

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


func _on_close_pressed() -> void:
	visible = false


func _on_language_button_item_selected(index: int) -> void:
	GlobalVars.options_save.language = locales[index]
	TranslationServer.set_locale(locales[index])
	GlobalFunctions.save_options()


func _on_keep_screen_on_check_toggled(toggled_on: bool) -> void:
	GlobalVars.options_save.keep_screen_on = toggled_on
	GlobalFunctions.apply_options()
