extends Node


func load_options() -> OptionsSave:
	var options: OptionsSave = load("user://saves/options.tres")
	if options == null:
		options = OptionsSave.new()
	return options


func load_quiz_saves() -> QuizSaves:
	var quiz_saves: QuizSaves = load("user://saves/quiz_saves.tres")
	if quiz_saves == null:
		quiz_saves = QuizSaves.new()
	return quiz_saves


func save_options() -> void:
	DirAccess.make_dir_absolute("user://saves")
	ResourceSaver.save(GlobalVars.options_save, "user://saves/options.tres")


func save_quiz_saves() -> void:
	DirAccess.make_dir_absolute("user://saves")
	ResourceSaver.save(GlobalVars.quiz_saves, "user://saves/quiz_saves.tres")


func reset_options() -> void:
	GlobalVars.options_save = OptionsSave.new()


func apply_options() -> void:
	DisplayServer.window_set_size(GlobalVars.options_save.window_size)
	DisplayServer.window_set_mode(GlobalVars.options_save.window_mode)
	TranslationServer.set_locale(GlobalVars.options_save.language)
	ProjectSettings.set_setting("display/window/energy_saving/keep_screen_on", GlobalVars.options_save.keep_screen_on)
