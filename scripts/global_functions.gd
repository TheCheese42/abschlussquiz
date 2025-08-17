extends Node

var _quiz_saver_thread: Thread
var _quiz_saver_mutex: Mutex
var _quiz_saver_semaphore: Semaphore
var _quiz_saver_exit: bool = false

var _backup_thread: Thread
var _backup_mutex: Mutex
var _backup_semaphore: Semaphore
var _backup_exit: bool = false


func _ready() -> void:
	_quiz_saver_thread = Thread.new()
	_quiz_saver_mutex = Mutex.new()
	_quiz_saver_semaphore = Semaphore.new()
	_quiz_saver_thread.start(_quiz_saver, Thread.PRIORITY_LOW)
	_backup_thread = Thread.new()
	_backup_mutex = Mutex.new()
	_backup_semaphore = Semaphore.new()
	_backup_thread.start(_backup_saver, Thread.PRIORITY_LOW)

	if OS.get_name() == "Android":
		OS.request_permissions()


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


func _backup_saver() -> void:
	while true:
		_backup_semaphore.wait()
		_backup_mutex.lock()
		var should_exit: bool = _backup_exit
		_backup_mutex.unlock()
		if should_exit:
			break
		if GlobalVars.quiz_saves.quiz_saves and GlobalVars.options_save.backup_count != 0:
			var datetime_string: String = Time.get_datetime_string_from_system(false, true)
			DirAccess.make_dir_absolute("user://backup/")
			DirAccess.make_dir_absolute("user://backup/" + datetime_string.validate_filename())
			for quiz: QuizSave in GlobalVars.quiz_saves.quiz_saves:
				var quiz_standalone: QuizSaveStandalone = QuizSaveStandalone.new()
				quiz_standalone.from_quiz_save(quiz)
				ResourceSaver.save(
					quiz_standalone,
					"user://backup/" + datetime_string.validate_filename() + "/"
					+ quiz_standalone.name + "_" + str(randi_range(100000, 999999)) + ".tres"
				)
		# Remove old backups
		if GlobalVars.options_save.backup_count == -1:
			return
		var all_datetimes: PackedStringArray = DirAccess.get_directories_at("user://backup/")
		all_datetimes.reverse()
		var i: int = 0
		for dt_dir: String in all_datetimes:
			if i >= GlobalVars.options_save.backup_count:
				remove_recursive("user://backup/" + dt_dir)
			i += 1


func remove_recursive(directory: String) -> void:
	for dir_name: String in DirAccess.get_directories_at(directory):
		remove_recursive(directory.path_join(dir_name))
	for file_name: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	DirAccess.remove_absolute(directory)


func _exit_tree() -> void:
	_quiz_saver_mutex.lock()
	_quiz_saver_exit = true
	_quiz_saver_mutex.unlock()
	_quiz_saver_semaphore.post()
	_quiz_saver_thread.wait_to_finish()
	_backup_mutex.lock()
	_backup_exit = true
	_backup_mutex.unlock()
	_backup_semaphore.post()
	_backup_thread.wait_to_finish()

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


func make_backups() -> void:
	_backup_semaphore.post()


func reset_options() -> void:
	GlobalVars.options_save = OptionsSave.new()


func apply_options() -> void:
	DisplayServer.window_set_size(GlobalVars.options_save.window_size)
	DisplayServer.window_set_position(GlobalVars.options_save.window_pos)
	DisplayServer.window_set_mode(GlobalVars.options_save.window_mode)
	TranslationServer.set_locale(GlobalVars.options_save.language)
	ProjectSettings.set_setting("display/window/energy_saving/keep_screen_on", GlobalVars.options_save.keep_screen_on)
