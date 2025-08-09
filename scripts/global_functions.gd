extends Node

var _quiz_saver_thread: Thread
var _quiz_saver_mutex: Mutex
var _quiz_saver_semaphore: Semaphore
var _quiz_saver_exit: bool = false

func _ready() -> void:
	_quiz_saver_thread = Thread.new()
	_quiz_saver_mutex = Mutex.new()
	_quiz_saver_semaphore = Semaphore.new()
	_quiz_saver_thread.start(_quiz_saver, Thread.PRIORITY_LOW)


func _quiz_saver() -> void:
	while true:
		_quiz_saver_semaphore.wait()
		_quiz_saver_mutex.lock()
		var should_exit: bool = _quiz_saver_exit
		_quiz_saver_mutex.unlock()
		if should_exit:
			break
		DirAccess.make_dir_absolute("user://saves")
		ResourceSaver.save(GlobalVars.quiz_saves, "user://saves/quiz_saves.tres")


func _exit_tree() -> void:
	_quiz_saver_mutex.lock()
	_quiz_saver_exit = true
	_quiz_saver_mutex.unlock()
	_quiz_saver_semaphore.post()
	_quiz_saver_thread.wait_to_finish()

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
	_quiz_saver_semaphore.post()


func reset_options() -> void:
	GlobalVars.options_save = OptionsSave.new()


func apply_options() -> void:
	DisplayServer.window_set_size(GlobalVars.options_save.window_size)
	DisplayServer.window_set_position(GlobalVars.options_save.window_pos)
	DisplayServer.window_set_mode(GlobalVars.options_save.window_mode)
	TranslationServer.set_locale(GlobalVars.options_save.language)
	ProjectSettings.set_setting("display/window/energy_saving/keep_screen_on", GlobalVars.options_save.keep_screen_on)
