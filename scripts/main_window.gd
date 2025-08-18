extends CanvasLayer

@onready var options: CanvasLayer = $MarginContainer/OptionsCanvas
@onready var favorites_h_box: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/FavoritesScroll/FavoritesHBox
@onready var all_h_box: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/AllScroll/AllHBox
@onready var quiz_panel: PanelContainer = $QuizPanel
@onready var quiz_options_panel: PanelContainer = $QuizOptionsLayer/QuizOptionsPanel
@onready var quiz_options_layer: CanvasLayer = $QuizOptionsLayer

var create_quiz_scene: PackedScene = preload("res://scenes/create_quiz.tscn")
var confirmation_dialog_scene: PackedScene = preload("res://scenes/better_confirmation_dialog.tscn")
var accept_dialog_scene: PackedScene = preload("res://scenes/better_accept_dialog.tscn")
var play_menu_scene: PackedScene = preload("res://scenes/play_menu.tscn")
var help_scene: PackedScene = preload("res://scenes/help.tscn")

var options_panel_active_for: QuizSave = null


func _ready() -> void:
	if GlobalVars.options_save.first_launch:
		# Import demo quiz files. See res://assets/demo/info.txt
		GlobalVars.options_save.first_launch = false
		GlobalFunctions.save_options()
		if not GlobalVars.quiz_saves.quiz_saves:
			var demo: QuizSaves = load("res://assets/demo/demo.tres")
			if demo:
				GlobalVars.quiz_saves = demo
				GlobalFunctions.save_quiz_saves()
				DirAccess.make_dir_absolute("user://saves/images")
				for file: String in DirAccess.get_files_at("res://assets/demo/images"):
					if not file.ends_with(".import"):
						continue
					file = file.trim_suffix(".import")
					var image_texture: Texture2D = load("res://assets/demo/images/" + file)
					var image: Image = image_texture.get_image()
					if image:
						image.save_png("user://saves/images/" + file)
	backup_all()
	rebuild_ui()
	cleanup_images()


func cleanup_images() -> void:
	if DirAccess.dir_exists_absolute("user://saves/images"):
		var images: PackedStringArray = DirAccess.get_files_at("user://saves/images")
		for quiz: QuizSave in GlobalVars.quiz_saves.quiz_saves:
			for category: String in quiz.categories:
				for question: Question in quiz.questions[category]:
					for image: String in images:
						if image.begins_with(question.image_id):
							images.erase(image)
					for answer: Answer in question.answers:
						for image: String in  images:
							if image.begins_with(answer.image_id):
								images.erase(image)
		for image: String in images:
			DirAccess.remove_absolute("user://saves/images/" + image)


func backup_all() -> void:
	GlobalFunctions.make_backups()


func rebuild_ui() -> void:
	for child: Control in favorites_h_box.get_children():
		favorites_h_box.remove_child(child)
		child.queue_free()
	for child: Control in all_h_box.get_children():
		all_h_box.remove_child(child)
		child.queue_free()

	for quiz_save: QuizSave in GlobalVars.quiz_saves.quiz_saves:
		var save_panel: PanelContainer = quiz_panel.duplicate()
		save_panel.gui_input.connect(quiz_panel_input.bind(quiz_save))
		save_panel.visible = true
		var title: Label = save_panel.find_child("Title", true, false)
		title.text = quiz_save.name
		var questions: Label = save_panel.find_child("Questions", true, false)
		questions.text = tr("X_QUESTIONS").format([len(quiz_save.categories) * len(quiz_save.point_stages)])
		var categories: Label = save_panel.find_child("Categories", true, false)
		categories.text = tr("X_CATEGORIES").format([len(quiz_save.categories)])
		var button: TextureButton = save_panel.find_child("Button", true, false)
		button.connect("pressed", func() -> void: open_actions_panel(quiz_save, save_panel))
		if quiz_save.is_favorite:
			favorites_h_box.add_child(save_panel)
		else:
			all_h_box.add_child(save_panel)


func quiz_panel_input(event: InputEvent, quiz: QuizSave) -> void:
	if is_instance_of(event, InputEventMouseButton):
		var mouse_event: InputEventMouseButton = event
		if mouse_event.is_action("click") and mouse_event.double_click:
			play_quiz(quiz)


func open_actions_panel(quiz_save: QuizSave, save_panel: PanelContainer) -> void:
	if quiz_options_layer.visible:
		return
	var fav_btn: Button = quiz_options_panel.find_child("FavoriteButton", true, false)
	if quiz_save.is_favorite:
		fav_btn.text = tr("REMOVE_FAVORITE")
	else:
		fav_btn.text = tr("MAKE_FAVORITE")
	quiz_options_layer.visible = true
	quiz_options_panel.global_position = save_panel.get_global_rect().end - Vector2(
		0.0, save_panel.size.y / 2.0
	)
	quiz_options_panel.global_position.x = clampf(
		quiz_options_panel.global_position.x, 20,
		DisplayServer.window_get_size().x - quiz_options_panel.size.x - 20
	)
	options_panel_active_for = quiz_save


func _on_options_pressed() -> void:
	options.visible = not options.visible


func _on_create_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/create_quiz.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit(0)


func play_quiz(quiz: QuizSave = null) -> void:
	if not quiz:
		if options_panel_active_for == null:
			return
		quiz = options_panel_active_for
	options_panel_active_for = null
	quiz_options_layer.visible = false
	var play_menu: PlayMenu = play_menu_scene.instantiate()
	play_menu.init(len(quiz.categories) * len(quiz.point_stages))
	play_menu.start_pressed.connect(start_quiz.bind(quiz))
	add_child(play_menu)


func start_quiz(
	teams: PackedStringArray,
	show_questions: bool,
	show_answers: bool,
	pass_questions: bool,
	pass_points_multiplier: float,
	confirm_before_question: bool,
	quiz: QuizSave,
) -> void:
	GlobalVars.next_play_data = {
		"teams": teams,
		"show_questions": show_questions,
		"show_answers": show_answers,
		"pass_questions": pass_questions,
		"pass_points_multiplier": pass_points_multiplier,
		"confirm_before_question": confirm_before_question,
		"quiz": quiz,
	}
	get_tree().change_scene_to_file("res://scenes/play_quiz.tscn")


func _on_favorite_button_pressed() -> void:
	if options_panel_active_for == null:
		return
	options_panel_active_for.is_favorite = not options_panel_active_for.is_favorite
	options_panel_active_for = null
	quiz_options_layer.visible = false
	GlobalFunctions.save_quiz_saves()
	rebuild_ui()


func _on_edit_button_pressed() -> void:
	if options_panel_active_for == null:
		return
	GlobalVars.next_save_to_be_edited = options_panel_active_for
	options_panel_active_for = null
	quiz_options_layer.visible = false
	get_tree().change_scene_to_file("res://scenes/create_quiz.tscn")


func _on_export_button_pressed() -> void:
	if options_panel_active_for == null:
		return
	var quiz: QuizSave = options_panel_active_for
	options_panel_active_for = null
	quiz_options_layer.visible = false
	var dialog: FileDialog = FileDialog.new()
	dialog.visible = false
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.quizf", tr("QUIZ_FILE"))
	dialog.add_filter("*.tres", tr("GODOT_TEXT_RESOURCE"))
	dialog.title = tr("EXPORT_QUIZ_FILE")
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.current_file = quiz.name.validate_filename() + ".quizf"
	dialog.use_native_dialog = true
	dialog.file_selected.connect(func(path: String) -> void: export_quiz(quiz, path))
	dialog.visible = true
	dialog.popup_centered_ratio()


func export_quiz(quiz: QuizSave, path: String) -> void:
	var quiz_standalone: QuizSaveStandalone = QuizSaveStandalone.new()
	quiz_standalone.from_quiz_save(quiz)
	DirAccess.make_dir_absolute("user://export/")
	var error: Error = ResourceSaver.save(quiz_standalone, "user://export/export.tres")
	if error == OK:
		error = DirAccess.rename_absolute("user://export/export.tres", path)
	if error != OK:
		var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
		dialog.title_text = tr("EXPORT_QUIZ_ERROR_TITLE")
		dialog.content_text = tr("EXPORT_QUIZ_ERROR_CONTENT").format([error_string(error)])
		add_child(dialog)
		dialog.show()


func _on_delete_button_pressed() -> void:
	if options_panel_active_for == null:
		return
	var quiz: QuizSave = options_panel_active_for
	options_panel_active_for = null
	quiz_options_layer.visible = false
	if not Input.is_action_pressed("confirm"):
		var dialog: BetterConfirmationDialog = confirmation_dialog_scene.instantiate()
		dialog.title_text = tr("DELETE_QUIZ_CONFIRM_TITLE")
		dialog.content_text = tr("DELETE_QUIZ_CONFIRM_CONTENT")
		dialog.confirmed.connect(func() -> void: delete_quiz(quiz))
		add_child(dialog)
		dialog.show()
	else:
		delete_quiz(quiz)


func delete_quiz(quiz: QuizSave) -> void:
	GlobalVars.quiz_saves.quiz_saves.erase(quiz)
	GlobalFunctions.save_quiz_saves()
	rebuild_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if quiz_options_layer.visible:
			quiz_options_layer.visible = false
			options_panel_active_for = null
	if is_instance_of(event, InputEventMouseButton):
		var mouse_event: InputEventMouseButton = event
		if mouse_event.is_action_pressed("click"):
			if not quiz_options_panel.get_rect().has_point(mouse_event.global_position):
				if quiz_options_layer.visible:
					quiz_options_layer.visible = false
					options_panel_active_for = null


func _on_import_button_pressed() -> void:
	var dialog: FileDialog = FileDialog.new()
	dialog.visible = false
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.quizf", tr("QUIZ_FILE"))
	dialog.add_filter("*.tres", tr("GODOT_TEXT_RESOURCE"))
	dialog.title = tr("IMPORT_QUIZ_FILE")
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.use_native_dialog = true
	dialog.file_selected.connect(import_quiz)
	dialog.visible = true
	dialog.popup_centered_ratio()


func import_quiz(path: String) -> void:
	DirAccess.make_dir_absolute("user://import/")
	var error: Error = DirAccess.copy_absolute(path, "user://import/import.tres")
	var quiz_standalone: QuizSaveStandalone = load("user://import/import.tres")
	var _err: Error = DirAccess.remove_absolute("user://import/import.tres")
	if error != OK or not is_instance_of(quiz_standalone, QuizSaveStandalone):
		var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
		dialog.title_text = tr("IMPORT_QUIZ_ERROR_TITLE")
		dialog.content_text = tr("IMPORT_QUIZ_ERROR_CONTENT")
		dialog.ok_button_text = tr("NO")
		add_child(dialog)
		dialog.show()
		return
	var quiz: QuizSave = quiz_standalone.load_to_quiz_save()
	GlobalVars.quiz_saves.quiz_saves.append(quiz)
	GlobalFunctions.save_quiz_saves()
	rebuild_ui()


func _on_duplicate_button_pressed() -> void:
	if options_panel_active_for == null:
		return
	var clone: QuizSave = options_panel_active_for.clone()
	GlobalVars.quiz_saves.quiz_saves.append(clone)
	GlobalFunctions.save_quiz_saves()
	options_panel_active_for = null
	quiz_options_layer.visible = false
	rebuild_ui()


func _on_restore_button_pressed() -> void:
	var dialog: FileDialog = FileDialog.new()
	dialog.visible = false
	dialog.access = FileDialog.ACCESS_USERDATA
	dialog.add_filter("*.quizf", tr("QUIZ_FILE"))
	dialog.add_filter("*.tres", tr("GODOT_TEXT_RESOURCE"))
	dialog.title = tr("RESTORE_QUIZ_FILE")
	dialog.current_dir = "user://backup"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.use_native_dialog = true
	dialog.file_selected.connect(import_quiz)
	dialog.visible = true
	dialog.popup_centered_ratio()


func _on_help_button_pressed() -> void:
	var help: HelpDialog = help_scene.instantiate()
	add_child(help)
