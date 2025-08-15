extends CanvasLayer
class_name CreateQuiz

var confirmation_dialog_scene: PackedScene = preload("res://scenes/better_confirmation_dialog.tscn")
var accept_dialog_scene: PackedScene = preload("res://scenes/better_accept_dialog.tscn")
var picture_preview_scene: PackedScene = preload("res://scenes/picture_preview.tscn")
var answer_editor_scene: PackedScene = preload("res://scenes/answers_editor.tscn")

@onready var title: Label = $MarginContainer/HBoxContainer/Title
@onready var quiz_name: LineEdit = $MarginContainer/TabContainer/GENERAL/GENERAL/HBoxContainer/QuizName
@onready var category_h_box: HBoxContainer = $CategoryHBox
@onready var points_h_box: HBoxContainer = $PointsHBox
@onready var categories_v_box: VBoxContainer = $MarginContainer/TabContainer/CATEGORIES/CATEGORIES/HBoxContainer/CategoryContainer/CategoriesVBox
@onready var points_v_box: VBoxContainer = $MarginContainer/TabContainer/CATEGORIES/CATEGORIES/HBoxContainer/PointsContainer/PointsVBox
@onready var questions_grid: GridContainer = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/QuestionsGrid
@onready var grid_panel: PanelContainer = $GridPanel
@onready var questions_editor_box: BoxContainer = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox
@onready var questions_tab_box: BoxContainer = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer
@onready var tab_container: TabContainer = $MarginContainer/TabContainer
@onready var question_editor_scroll: ScrollContainer = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer
@onready var mode_menu: OptionButton = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/GeneralBox/ModeBox/ModeOption
@onready var time_spin: SpinBox = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/GeneralBox/TimeBox/TimeSpin
@onready var picture_button: Button = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/GeneralBox/PictureBox/PictureButton
@onready var question_text_edit: TextEdit = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/TextBox/QuestionTextEdit
@onready var picture_preview_container: PanelContainer = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/GeneralBox/PictureBox/PicturePreviewContainer
@onready var clear_picture_container: PanelContainer = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/GeneralBox/PictureBox/ClearPictureContainer
@onready var edit_answers: Button = $MarginContainer/TabContainer/QUESTIONS/QUESTIONS/VBoxContainer/ScrollContainer/QuestionsEditorBox/MoveEditAnswersBox/EditAnswers
var edit: bool = false
var save: QuizSave = null
var undo_queue: Array[QuizSave] = []
var last_state: QuizSave = null
var redo_queue: Array[QuizSave] = []
var queue_len_on_last_undo: int = 0
var just_redone: bool = false
var selected_question_category: String = ""
var selected_question_stage: int = 0
# Dictionary[String, Array[PanelContainer]]
var question_panels: Dictionary[String, Array] = {}


func _ready() -> void:
	if GlobalVars.next_save_to_be_edited:
		save = GlobalVars.next_save_to_be_edited
		GlobalVars.next_save_to_be_edited = null
		edit = true
	if not edit:
		save = QuizSave.new()
		GlobalVars.quiz_saves.quiz_saves.append(save)
	selected_question_category = save.categories.get(0) if save.categories.get(0) else ""
	save.update_questions()
	rebuild_ui()
	await get_tree().create_timer(0.0).timeout
	rebuild_ui()


func rebuild_ui(append_to_undos: bool = true) -> void:
	GlobalFunctions.save_quiz_saves()
	if append_to_undos:
		if last_state == null:
			last_state = save.duplicate(true)
		else:
			undo_queue.append(last_state)
			last_state = save.duplicate(true)
		redo_queue.clear()
	rebuild_categories_points()
	rebuild_questions()
	rebuild_question_editor()


func rebuild_question_editor() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	match question.type:
		Question.QuestionType.MultipleChoice:
			mode_menu.selected = 0
		Question.QuestionType.Tournament:
			mode_menu.selected = 1
	time_spin.value = question.time
	var image: ImageTexture = question.load_image()
	picture_preview_container.visible = image != null
	clear_picture_container.visible = image != null
	question_text_edit.text = question.text
	edit_answers.visible = question.type == Question.QuestionType.MultipleChoice
	var time_box: HBoxContainer = time_spin.get_parent()
	time_box.visible = question.type == Question.QuestionType.Tournament


func rebuild_questions() -> void:
	for child: Control in questions_grid.get_children():
		questions_grid.remove_child(child)
		child.queue_free()
	question_panels.clear()
	questions_grid.columns = len(save.categories) + 1
	if selected_question_category not in save.categories:
		selected_question_category = save.categories[0]
	if selected_question_stage >= len(save.point_stages):
		selected_question_stage = 0
	var empty_panel: PanelContainer = grid_panel.duplicate()
	empty_panel.visible = true
	var empty_stylebox: StyleBoxFlat = empty_panel.get_theme_stylebox("panel")
	empty_stylebox = empty_stylebox.duplicate(true)
	empty_panel.add_theme_stylebox_override("panel", empty_stylebox)
	empty_stylebox.border_width_top = 2
	empty_stylebox.border_width_left = 2
	empty_panel.add_child(Control.new())
	questions_grid.add_child(empty_panel)  # Upper left corner is emtpy
	for category: String in save.categories:
		question_panels[category] = []
		var label: Label = Label.new()
		label.label_settings = load("res://styles/labels/label_content_24.tres")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = category
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var panel: PanelContainer = grid_panel.duplicate()
		panel.visible = true
		var stylebox: StyleBoxFlat = panel.get_theme_stylebox("panel")
		stylebox = stylebox.duplicate(true)
		panel.add_theme_stylebox_override("panel", stylebox)
		stylebox.border_width_top = 2
		if category == save.categories[len(save.categories) - 1]:
			stylebox.border_width_right = 2
		panel.add_child(label)
		questions_grid.add_child(panel)
	for stage: int in len(save.point_stages):
		var is_last_stage: bool = stage == len(save.point_stages) - 1
		var points: int = save.point_stages[stage]
		var label: Label = Label.new()
		label.label_settings = load("res://styles/labels/label_content_24.tres")
		label.text = str(points)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var panel: PanelContainer = grid_panel.duplicate()
		panel.visible = true
		var stylebox: StyleBoxFlat = panel.get_theme_stylebox("panel")
		stylebox = stylebox.duplicate(true)
		panel.add_theme_stylebox_override("panel", stylebox)
		stylebox.border_width_left = 2
		if is_last_stage:
			stylebox.border_width_bottom = 2
		panel.add_child(label)
		questions_grid.add_child(panel)
		for category: String in save.categories:
			var question: Question = save.questions[category][stage]
			var question_label: Label = Label.new()
			question_label.label_settings = load("res://styles/labels/label_content_16.tres")
			question_label.text = question.text
			question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			question_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			question_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var question_panel: PanelContainer = grid_panel.duplicate()
			question_panel.gui_input.connect(
				func(event: InputEvent) -> void: select_question(event, category, stage)
			)
			question_panels[category].append(question_panel)
			question_panel.visible = true
			var question_stylebox: StyleBoxFlat = question_panel.get_theme_stylebox("panel")
			question_stylebox = question_stylebox.duplicate(true)
			question_panel.add_theme_stylebox_override("panel", question_stylebox)
			if is_last_stage:
				question_stylebox.border_width_bottom = 2
			if category == save.categories[len(save.categories) - 1]:
				question_stylebox.border_width_right = 2
			if selected_question_category == category and selected_question_stage == stage:
				question_stylebox.bg_color.a8 = 150
			question_panel.add_child(question_label)
			questions_grid.add_child(question_panel)
	if tab_container.size.x / questions_grid.columns < 400:
		var new_box: BoxContainer = VBoxContainer.new()
		new_box.add_theme_constant_override("separation", 25)
		questions_tab_box.replace_by(new_box)
		questions_tab_box.queue_free()
		questions_tab_box = new_box
		var new_editor_box: BoxContainer = HBoxContainer.new()
		new_editor_box.add_theme_constant_override("separation", 25)
		question_editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		question_editor_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
		new_editor_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		questions_editor_box.replace_by(new_editor_box)
		questions_editor_box.queue_free()
		questions_editor_box = new_editor_box
	else:
		var new_box: BoxContainer = HBoxContainer.new()
		new_box.add_theme_constant_override("separation", 25)
		questions_tab_box.replace_by(new_box)
		questions_tab_box.queue_free()
		questions_tab_box = new_box
		var new_editor_box: BoxContainer = VBoxContainer.new()
		new_editor_box.add_theme_constant_override("separation", 25)
		question_editor_scroll.size_flags_horizontal = Control.SIZE_SHRINK_END
		question_editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		questions_editor_box.replace_by(new_editor_box)
		questions_editor_box.queue_free()
		questions_editor_box = new_editor_box
		question_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Make text edit fill the blank space
		var qte_parent: Control = question_text_edit.get_parent()
		qte_parent.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var qte_parent_parent: Control = question_text_edit.get_parent().get_parent()
		qte_parent_parent.size_flags_vertical = Control.SIZE_EXPAND_FILL


func select_question(event: InputEvent, category: String, stage: int) -> void:
	if is_instance_of(event, InputEventMouseButton):
		if event.is_action_pressed("click"):
			selected_question_category = category;
			selected_question_stage = stage;
			rebuild_ui()


func on_resize(_size: Vector2) -> void:
	rebuild_questions()


func rebuild_categories_points() -> void:
	for child: Control in categories_v_box.get_children():
		categories_v_box.remove_child(child)
		child.queue_free()
	for child: Control in points_v_box.get_children():
		points_v_box.remove_child(child)
		child.queue_free()
	title.text = tr("EDIT_QUIZ") if edit else tr("CREATE_QUIZ")
	quiz_name.text = save.name

	# Categories
	for category: String in save.categories:
		var hbox: HBoxContainer = category_h_box.duplicate()
		hbox.visible = true
		var label: Label = hbox.find_child("Label", true, false)
		label.text = tr("CATEGORY_X_COLON").format([save.categories.find(category) + 1])
		var cat_edit: LineEdit = hbox.find_child("CategoryEdit", true, false)
		cat_edit.text = category
		cat_edit.connect("text_changed", func(new: String) -> void: rename_category(cat_edit, category, new))
		# Delete
		var cat_del: TextureButton = hbox.find_child("DeleteButton", true, false)
		cat_del.connect("pressed", func() -> void: remove_category(category))
		# Move Up
		var mv_up_btn: TextureButton = hbox.find_child("MoveUpButton", true, false)
		if save.categories.find(category) == 0:
			mv_up_btn.disabled = true
		else:
			mv_up_btn.connect("pressed", func() -> void: save.move_category(category, true); rebuild_ui())
		# Move Down
		var mv_down_btn: TextureButton = hbox.find_child("MoveDownButton", true, false)
		if save.categories.find(category) >= len(save.categories) - 1:
			mv_down_btn.disabled = true
		else:
			mv_down_btn.connect("pressed", func() -> void: save.move_category(category, false); rebuild_ui())
		categories_v_box.add_child(hbox)

	# Points
	var i: int = 0
	for point_stage: int in save.point_stages:
		var hbox: HBoxContainer = points_h_box.duplicate()
		hbox.visible = true
		var label: Label = hbox.find_child("Label", true, false)
		label.text = tr("POINT_STAGE_X_COLON").format([i + 1])
		var points_spin: SpinBox = hbox.find_child("PointsSpin", true, false)
		points_spin.value = point_stage
		points_spin.connect(
			"value_changed", func(value: int) -> void: save.change_point_stage_value(i, value)
		)
		var del_btn: TextureButton = hbox.find_child("DeleteButton", true, false)
		if i != len(save.point_stages) - 1:
			del_btn.disabled = true
			del_btn.visible = false
		else:
			del_btn.connect("pressed", remove_last_point_stage)
		points_v_box.add_child(hbox)
		i += 1


func rename_category(cat_edit: LineEdit, category: String, new: String) -> void:
	save.rename_category(category, new)
	for signal_conn: Dictionary in cat_edit.get_signal_connection_list("text_changed"):
		var callable: Callable = signal_conn["callable"]
		cat_edit.disconnect("text_changed", callable)
	cat_edit.connect("text_changed", func(new_: String) -> void: rename_category(cat_edit, new, new_))


func remove_category(category: String) -> void:
	if len(save.categories) <= 1:
		return
	if not Input.is_action_pressed("confirm"):
		var dialog: BetterConfirmationDialog = confirmation_dialog_scene.instantiate()
		dialog.title_text = tr("DELETE_CATEGORY_CONFIRM_TITLE")
		dialog.content_text = tr("DELETE_CATEGORY_CONFIRM_CONTENT")
		dialog.confirmed.connect(func() -> void: save.remove_category(category); rebuild_ui())
		add_child(dialog)
		dialog.show()
	else:
		save.remove_category(category)
	rebuild_ui()


func remove_last_point_stage() -> void:
	if len(save.point_stages) <= 1:
		return
	if not Input.is_action_pressed("confirm"):
		var dialog: BetterConfirmationDialog = confirmation_dialog_scene.instantiate()
		dialog.title_text = tr("DELETE_POINT_STAGE_CONFIRM_TITLE")
		dialog.content_text = tr("DELETE_POINT_STAGE_CONFIRM_CONTENT")
		dialog.confirmed.connect(func() -> void: save.remove_last_point_stage(); rebuild_ui())
		add_child(dialog)
		dialog.show()
	else:
		save.remove_last_point_stage()
	rebuild_ui()


func _on_add_category_pressed() -> void:
	save.add_category()
	rebuild_ui()


func _on_add_points_stage_pressed() -> void:
	save.add_point_stage()
	rebuild_ui()


func _on_back_button_pressed() -> void:
	GlobalFunctions.save_quiz_saves()
	get_tree().change_scene_to_file("res://scenes/main_window.tscn")


func _on_quiz_name_text_changed(new_text: String) -> void:
	if new_text:  # Don't save if the name is empty
		save.name = new_text
		GlobalFunctions.save_quiz_saves()
		undo_queue.append(last_state)
		last_state = save.duplicate(true)
		redo_queue.clear()


func undo() -> void:
	var last_save: QuizSave = undo_queue.pop_back()
	if last_save == null:
		return
	redo_queue.append(save)
	var index: int = GlobalVars.quiz_saves.quiz_saves.find(save)
	if index != -1:
		GlobalVars.quiz_saves.quiz_saves.remove_at(index)
	GlobalVars.quiz_saves.quiz_saves.insert(index, last_save)
	save = last_save
	last_state = save.duplicate(true)
	rebuild_ui(false)


func redo() -> void:
	var next_save: QuizSave = redo_queue.pop_back()
	if next_save == null:
		return
	var index: int = GlobalVars.quiz_saves.quiz_saves.find(save)
	if index != -1:
		GlobalVars.quiz_saves.quiz_saves.remove_at(index)
	save = next_save
	undo_queue.append(last_state)
	last_state = save.duplicate(true)
	just_redone = true
	rebuild_ui(false)


func _on_undo_button_pressed() -> void:
	undo()


func _on_redo_button_pressed() -> void:
	redo()


func _on_picture_preview_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	var image: ImageTexture = question.load_image()
	if image:
		var preview: PicturePreview = picture_preview_scene.instantiate()
		preview.texture = image
		add_child(preview)


func _on_clear_picture_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	question.delete_image()
	rebuild_ui()


func _on_picture_button_pressed() -> void:
	var dialog: FileDialog = FileDialog.new()
	dialog.visible = false
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter(
		"*.jpg, *.jpeg, *.png, *.tga, *.webp, *.svg, *.bmp, *.dds, *.ktx, *.exr, *.hdr",
		tr("SUPPORTED_IMAGE_FILES"),
	)
	dialog.title = tr("SELECT_IMAGE")
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.use_native_dialog = true
	dialog.file_selected.connect(open_image)
	dialog.visible = true
	add_child(dialog)
	dialog.popup_centered_ratio()
	dialog.show()


func open_image(path: String) -> void:
	var image: Image = Image.load_from_file(path)
	if image == null:
		var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
		dialog.title_text = tr("LOAD_IMAGE_ERROR_TITLE")
		dialog.content_text = tr("LOAD_IMAGE_ERROR_CONTENT")
		add_child(dialog)
		dialog.show()
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	question.save_image(image)
	rebuild_ui()


func _on_mode_option_item_selected(index: int) -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	match index:
		0:
			question.type = Question.QuestionType.MultipleChoice
			question.time = 0
		1:
			question.type = Question.QuestionType.Tournament
			question.answers.clear()
	rebuild_ui()


func _on_time_spin_value_changed(value: float) -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	question.time = int(value)
	GlobalFunctions.save_quiz_saves()
	undo_queue.append(last_state)
	last_state = save.duplicate(true)
	redo_queue.clear()


func _on_question_text_edit_text_changed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	question.text = question_text_edit.text
	var panel: PanelContainer = question_panels[selected_question_category][selected_question_stage]
	var label: Label = panel.get_child(0)
	label.text = question.text
	GlobalFunctions.save_quiz_saves()
	undo_queue.append(last_state)
	last_state = save.duplicate(true)
	redo_queue.clear()


func _on_edit_answers_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	var answer_editor: AnswersEditor = answer_editor_scene.instantiate()
	answer_editor.init(question.answers)
	answer_editor.confirmed.connect(
		func(answers: Array[Answer]) -> void: question.answers = answers; rebuild_ui()
	)
	add_child(answer_editor)


func _on_tab_container_tab_changed(_tab: int) -> void:
	rebuild_ui(false)


func _on_move_left_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	var cat_index: int = save.categories.find(selected_question_category)
	if cat_index > 0:
		var other_question: Question = save.questions[save.categories[cat_index - 1]][selected_question_stage]
		save.questions[save.categories[cat_index - 1]][selected_question_stage] = question
		save.questions[selected_question_category][selected_question_stage] = other_question
		selected_question_category = save.categories[cat_index - 1]
		rebuild_questions()


func _on_move_right_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	var cat_index: int = save.categories.find(selected_question_category)
	if cat_index < len(save.categories) - 1:
		var other_question: Question = save.questions[save.categories[cat_index + 1]][selected_question_stage]
		save.questions[save.categories[cat_index + 1]][selected_question_stage] = question
		save.questions[selected_question_category][selected_question_stage] = other_question
		selected_question_category = save.categories[cat_index + 1]
		rebuild_ui()


func _on_move_up_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	if selected_question_stage > 0:
		var other_question: Question = save.questions[selected_question_category][selected_question_stage - 1]
		save.questions[selected_question_category][selected_question_stage - 1] = question
		save.questions[selected_question_category][selected_question_stage] = other_question
		selected_question_stage -= 1
		rebuild_questions()


func _on_move_down_pressed() -> void:
	var question: Question = save.questions[selected_question_category][selected_question_stage]
	if selected_question_stage < len(save.point_stages) - 1:
		var other_question: Question = save.questions[selected_question_category][selected_question_stage + 1]
		save.questions[selected_question_category][selected_question_stage + 1] = question
		save.questions[selected_question_category][selected_question_stage] = other_question
		selected_question_stage += 1
		rebuild_questions()


func _on_go_left_button_pressed() -> void:
	var cat_index: int = save.categories.find(selected_question_category)
	if Input.is_action_just_pressed("left"):
		if cat_index > 0:
			selected_question_category = save.categories[cat_index - 1]
			rebuild_ui()


func _on_go_right_button_pressed() -> void:
	var cat_index: int = save.categories.find(selected_question_category)
	if Input.is_action_just_pressed("right"):
		if cat_index < len(save.categories) - 1:
			selected_question_category = save.categories[cat_index + 1]
			rebuild_ui()


func _on_go_up_button_pressed() -> void:
	if Input.is_action_just_pressed("up"):
		if selected_question_stage > 0:
			selected_question_stage -= 1
			rebuild_ui()


func _on_go_down_button_pressed() -> void:
	if Input.is_action_just_pressed("down"):
		if selected_question_stage < len(save.point_stages) - 1:
			selected_question_stage += 1
			rebuild_ui()
