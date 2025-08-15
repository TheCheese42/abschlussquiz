extends CanvasLayer
class_name PlayQuiz

var play_question_scene: PackedScene = preload("res://scenes/play_question.tscn")
var game_over_scene: PackedScene = preload("res://scenes/game_over.tscn")
var confirmation_dialog_scene: PackedScene = preload("res://scenes/better_confirmation_dialog.tscn")
var accept_dialog_scene: PackedScene = preload("res://scenes/better_accept_dialog.tscn")

@onready var next_team_label: Label = $MarginContainer2/NextTeamLabel
@onready var questions_grid: GridContainer = $MarginContainer/VBoxContainer/QuestionsGrid
@onready var teams_flow: VFlowContainer = $MarginContainer/VBoxContainer/HBoxContainer/TeamsVBox
@onready var team_box: HBoxContainer = $TeamBox
@onready var options_layer: CanvasLayer = $OptionsLayer
@onready var options_panel: PanelContainer = $OptionsLayer/OptionsPanel
@onready var points_v_box: VBoxContainer = $ManualEditor/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/PointsVBox
@onready var manual_editor: CanvasLayer = $ManualEditor
@onready var dots_button: TextureButton = $MarginContainer/VBoxContainer/HBoxContainer/DotsButton

var _teams: PackedStringArray
var _show_questions: bool
var _show_answers: bool
var _pass_questions: bool
var _pass_points_multiplier: float
var _confirm_before_question: bool
var _quiz: QuizSave

var _teams_points: Dictionary[String, int]
var _team_turn_queue: Array[String]
var _teams_boxes: Dictionary[String, HBoxContainer]


func _init() -> void:
	_teams = GlobalVars.next_play_data["teams"]
	_show_questions = GlobalVars.next_play_data["show_questions"]
	_show_answers = GlobalVars.next_play_data["show_answers"]
	_pass_questions = GlobalVars.next_play_data["pass_questions"]
	_pass_points_multiplier = GlobalVars.next_play_data["pass_points_multiplier"]
	_confirm_before_question = GlobalVars.next_play_data["confirm_before_question"]
	_quiz = GlobalVars.next_play_data["quiz"]
	GlobalVars.next_play_data.clear()
	var num_questions: int = len(_quiz.categories) * len(_quiz.point_stages)
	var num_rounds: int = floor(float(num_questions) / len(_teams))
	for _round: int in num_rounds:
		_team_turn_queue.append_array(_teams.duplicate())
	_team_turn_queue.reverse()
	for team: String in _teams:
		_teams_points[team] = 0


func _ready() -> void:
	if len(_teams) > len(_quiz.categories) * len(_quiz.point_stages):
		var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
		dialog.title_text = tr("NICE_TRY")
		dialog.content_text = tr("MORE_TEAMS_THAN_QUESTIONS")
		dialog.ok_button_text = tr("BACK")
		add_child(dialog)
		dialog.show()
		dialog.confirmed.connect(
			func() -> void: get_tree().change_scene_to_file("res://scenes/main_window.tscn")
		)
		return
	rebuild_ui()


func rebuild_ui() -> void:
	if _team_turn_queue:
		next_team_label.text = tr("NEXT_UP").format([_team_turn_queue[-1]])
	else:
		next_team_label.visible = false
	var grid: GridContainer = questions_grid
	for child: Control in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	grid.columns = len(_quiz.categories) + 1
	var stylebox_t: StyleBoxFlat = StyleBoxFlat.new()
	stylebox_t.bg_color.a = 0.0
	stylebox_t.border_color = Color.BLACK
	stylebox_t.content_margin_bottom = 20
	stylebox_t.content_margin_top = 20
	stylebox_t.content_margin_left = 20
	stylebox_t.content_margin_right = 20
	var stylebox_tr: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_tr.border_width_left = 1
	stylebox_tr.border_width_bottom = 1
	var stylebox_r: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_r.border_width_top = 1
	stylebox_r.border_width_left = 1
	stylebox_r.border_width_bottom = 1
	var stylebox_br: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_br.border_width_top = 1
	stylebox_br.border_width_left = 1
	var stylebox_b: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_b.border_width_left = 1
	stylebox_b.border_width_top = 1
	stylebox_b.border_width_right = 1
	var stylebox_bl: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_bl.border_width_top = 1
	stylebox_bl.border_width_right = 1
	var stylebox_l: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_l.border_width_top = 1
	stylebox_l.border_width_right = 1
	stylebox_l.border_width_bottom = 1
	var stylebox_tl: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_tl.border_width_right = 1
	stylebox_tl.border_width_bottom = 1
	var stylebox_m: StyleBoxFlat = stylebox_t.duplicate(true)
	stylebox_m.border_width_top = 1
	stylebox_m.border_width_left = 1
	stylebox_m.border_width_bottom = 1
	stylebox_m.border_width_right = 1
	stylebox_t.border_width_left = 1
	stylebox_t.border_width_bottom = 1
	stylebox_t.border_width_right = 1
	var empty: PanelContainer = PanelContainer.new()
	empty.add_theme_stylebox_override("panel", stylebox_tl)
	grid.add_child(empty)
	for category: String in _quiz.categories:
		var cat_label: Label = Label.new()
		cat_label.label_settings = load("res://styles/labels/label_content_32.tres")
		cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_label.text = category
		var cat_panel: PanelContainer = PanelContainer.new()
		cat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _quiz.categories.find(category) == len(_quiz.categories) - 1:
			cat_panel.add_theme_stylebox_override("panel", stylebox_tr)
		else:
			cat_panel.add_theme_stylebox_override("panel", stylebox_t)
		cat_panel.add_child(cat_label)
		grid.add_child(cat_panel)
	for stage_idx: int in len(_quiz.point_stages):
		var stage: int = _quiz.point_stages[stage_idx]
		var stage_label: Label = Label.new()
		stage_label.label_settings = load("res://styles/labels/label_content_32.tres")
		stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stage_label.text = str(stage)
		var stage_panel: PanelContainer = PanelContainer.new()
		if stage_idx == len(_quiz.point_stages) - 1:
			stage_panel.add_theme_stylebox_override("panel", stylebox_bl)
		else:
			stage_panel.add_theme_stylebox_override("panel", stylebox_l)
		stage_panel.add_child(stage_label)
		grid.add_child(stage_panel)
		for category: String in _quiz.categories:
			var que_label: Label = Label.new()
			que_label.label_settings = load("res://styles/labels/label_title_48.tres")
			que_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			que_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			que_label.text = tr("HIDDEN_QUESTION")
			var que_panel: PanelContainer = PanelContainer.new()
			que_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			que_panel.gui_input.connect(question_selected.bind(category, stage_idx, que_panel))
			que_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			if _quiz.categories.find(category) == len(_quiz.categories) - 1:
				if stage_idx == len(_quiz.point_stages) - 1:
					que_panel.add_theme_stylebox_override("panel", stylebox_br)
				else:
					que_panel.add_theme_stylebox_override("panel", stylebox_r)
			elif stage_idx == len(_quiz.point_stages) - 1:
				que_panel.add_theme_stylebox_override("panel", stylebox_b)
			else:
				que_panel.add_theme_stylebox_override("panel", stylebox_m)
			que_panel.add_child(que_label)
			grid.add_child(que_panel)
	rebuild_teams_flow()


func rebuild_teams_flow() -> void:
	for child: Control in teams_flow.get_children():
		teams_flow.remove_child(child)
		child.queue_free()
	_teams_boxes.clear()
	for team: String in _teams:
		var points: int = _teams_points[team]
		var new_team_box: HBoxContainer = team_box.duplicate()
		new_team_box.visible = true
		var name_label: Label = new_team_box.find_child("TeamName", true, false)
		var score_label: Label = new_team_box.find_child("TeamScore", true, false)
		score_label.text = str(points)
		name_label.text = team
		teams_flow.add_child(new_team_box)
		_teams_boxes[team] = new_team_box


func show_manual_editor() -> void:
	for child: Control in points_v_box.get_children():
		points_v_box.remove_child(child)
		child.queue_free()
	for team: String in _teams:
		var hbox: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = tr("X_COLON").format([team])
		label.label_settings = load("res://styles/labels/label_content_32.tres")
		hbox.add_child(label)
		var spin: SpinBox = SpinBox.new()
		spin.min_value = 0.0
		spin.set_value_no_signal(_teams_points[team])
		spin.allow_greater = true
		spin.rounded = true
		spin.update_on_text_changed = true
		spin.value_changed.connect(
			func(value: int) -> void: _teams_points[team] = value; rebuild_teams_flow()
		)
		hbox.add_child(spin)
		points_v_box.add_child(hbox)
	manual_editor.visible = true


func question_selected(event: InputEvent, category: String, stage_idx: int, panel: PanelContainer) -> void:
	if is_instance_of(event, InputEventMouseButton):
		var mouse_event: InputEventMouseButton = event
		if mouse_event.double_click:
			var question: Question = _quiz.questions[category][stage_idx]
			var play_question: PlayQuestion = play_question_scene.instantiate()
			var next_team: String = _team_turn_queue.pop_back()
			var pass_team: String = _teams[_teams.find(next_team) - (len(_teams) - 1)]
			play_question.init(
				question,
				category,
				_quiz.point_stages[stage_idx],
				next_team,
				_show_questions,
				_show_questions,
				_pass_questions,
				pass_team,
				_pass_points_multiplier,
				_confirm_before_question,
				_teams,
			)
			add_child(play_question)
			play_question.canceled.connect(func() -> void: _team_turn_queue.append(next_team))
			play_question.completed.connect(question_completed.bind(panel))


func question_completed(correct: bool, team: String, points: int, panel: PanelContainer) -> void:
	panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
	for connection: Dictionary in panel.gui_input.get_connections():
		var callable: Callable = connection["callable"]
		panel.gui_input.disconnect(callable)
	var label: Label = panel.get_child(0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.text = str(points) if correct else tr("X")
	panel.remove_child(label)
	var panel_stylebox: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate(true)
	panel_stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.1)
	panel.add_theme_stylebox_override("panel", panel_stylebox)
	if team:  # else is tournament when nobody won or multiple choice if passed and still wrong
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_child(label)
		var sub_label: Label = Label.new()
		sub_label.label_settings = load("res://styles/labels/label_content_24.tres")
		sub_label.text = team
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(sub_label)
		panel.add_child(vbox)
	else:
		panel.add_child(label)
	if correct:
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		var thbox: HBoxContainer = _teams_boxes[team]
		var score_label: Label = thbox.find_child("TeamScore", true, false)
		tween.tween_method(
			func(score: int) -> void: score_label.text = str(score),
			_teams_points[team], _teams_points[team] + points, 4.0
		).set_delay(1.0)
		_teams_points[team] += points
	if _team_turn_queue:
		next_team_label.text = tr("NEXT_UP").format([_team_turn_queue[-1]])
	else:
		# Quiz is done
		next_team_label.visible = false
		end_quiz()
	await get_tree().create_timer(0.0).timeout


func end_quiz() -> void:
	var game_over: GameOver = game_over_scene.instantiate()
	game_over.init(_teams_points)
	add_child(game_over)


func _on_dots_button_pressed() -> void:
	if not options_layer.visible:
		options_panel.position = (
			dots_button.global_position - options_panel.size + Vector2(-4, dots_button.size.y)
		)
		options_layer.visible = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if options_layer.visible:
			options_layer.visible = false
	if is_instance_of(event, InputEventMouseButton):
		var mouse_event: InputEventMouseButton = event
		if mouse_event.is_action_pressed("click"):
			if not options_panel.get_rect().has_point(mouse_event.global_position):
				if options_layer.visible:
					options_layer.visible = false


func _on_stop_button_pressed() -> void:
	if not Input.is_action_pressed("confirm"):
		var dialog: BetterConfirmationDialog = confirmation_dialog_scene.instantiate()
		dialog.title_text = tr("STOP_QUIZ_CONFIRM_TITLE")
		dialog.content_text = tr("STOP_QUIZ_CONFIRM_CONTENT")
		dialog.confirmed.connect(end_quiz)
		add_child(dialog)
		dialog.show()
	else:
		end_quiz()


func _on_manual_edit_button_pressed() -> void:
	show_manual_editor()


func _on_close_button_pressed() -> void:
	manual_editor.visible = false
