extends CanvasLayer
class_name PlayQuiz

var play_question_scene: PackedScene = load("res://scenes/play_question.tscn")

@onready var questions_grid: GridContainer = $MarginContainer/VBoxContainer/QuestionsGrid
@onready var teams_v_box: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/TeamsVBox
@onready var team_box: HBoxContainer = $TeamBox

var _teams: PackedStringArray
var _show_questions: bool
var _show_answers: bool
var _pass_questions: bool
var _pass_points_multiplier: float
var _quiz: QuizSave

var _team_turn_queue: Array[String]


func _init() -> void:
	_teams = GlobalVars.next_play_data["teams"]
	_show_questions = GlobalVars.next_play_data["show_questions"]
	_show_answers = GlobalVars.next_play_data["show_answers"]
	_pass_questions = GlobalVars.next_play_data["pass_questions"]
	_pass_points_multiplier = GlobalVars.next_play_data["pass_points_multiplier"]
	_quiz = GlobalVars.next_play_data["quiz"]
	GlobalVars.next_play_data.clear()
	var num_questions: int = len(_quiz.categories) * len(_quiz.point_stages)
	var num_rounds: int = floor(float(num_questions) / len(_teams))
	for _round: int in num_rounds:
		_team_turn_queue.append_array(_teams.duplicate())
	_team_turn_queue.reverse()


func _ready() -> void:
	rebuild_ui()


func rebuild_ui() -> void:
	var grid: GridContainer = questions_grid
	for child: Control in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for child: Control in teams_v_box.get_children():
		teams_v_box.remove_child(child)
		child.queue_free()

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
			que_panel.gui_input.connect(question_selected.bind(category, stage_idx))
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

	for team: String in _teams:
		var new_team_box: HBoxContainer = team_box.duplicate()
		new_team_box.visible = true
		var name_label: Label = new_team_box.find_child("TeamName", true, false)
		name_label.text = team
		teams_v_box.add_child(new_team_box)


func question_selected(event: InputEvent, category: String, stage_idx: int) -> void:
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
				_teams,
			)
			add_child(play_question)
			play_question.canceled.connect(func() -> void: _team_turn_queue.append(next_team))
