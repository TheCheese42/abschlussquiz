extends CanvasLayer
class_name PlayQuestion

#signal completed(correct: bool, team: String, points: int)  # (false, "", 0) if not  answered correctly.
signal canceled

var confetti_scene: PackedScene = load("res://scenes/confetti.tscn")

@onready var progress_bar: ProgressBar = $ColorRect/ProgressBar
@onready var panel_container: PanelContainer = $ColorRect/PanelContainer
@onready var panel_vbox: VBoxContainer = $ColorRect/PanelContainer/MarginContainer/VBoxContainer

var _question: Question
var _category: String
var _points: int
var _team: String
var _show_questions: bool
var _show_answers: bool
var _pass_questions: bool
var _pass_team: String
var _pass_multiplier: float
var _all_teams: Array[String]


func init(
	question: Question,
	category: String,
	points: int,
	team: String,
	show_questions: bool,
	show_answers: bool,
	pass_questions: bool,
	pass_team: String,
	pass_multiplier: float,
	all_teams: Array[String],
) -> void:
	_question = question
	_category = category
	_points = points
	_team = team
	_show_questions = show_questions
	_show_answers = show_answers
	_pass_questions = pass_questions
	_pass_team = pass_team
	_pass_multiplier = pass_multiplier
	_all_teams = all_teams


func _ready() -> void:
	panel_container.scale = Vector2.ZERO
	var header: Label = panel_container.find_child("Header", true, false)
	header.text = tr("QUESTION_INTRO").format({"category": _category, "points": _points})
	var tournament_label: Label = null
	var time_label: Label = null
	if _question.type == Question.QuestionType.Tournament:
		tournament_label = Label.new()
		tournament_label.label_settings = load("res://styles/labels/label_title_56.tres")
		tournament_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tournament_label.text = tr("TOURNAMENT_QUESTION")
		panel_vbox.add_child(tournament_label)
		if _question.time > 0:
			time_label = Label.new()
			time_label.label_settings = load("res://styles/labels/label_content_40.tres")
			time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			time_label.text = tr("YOU_HAVE_X_SECONDS").format([_question.time])
			panel_vbox.add_child(time_label)
	var prog_tween: Tween = create_tween()
	prog_tween.set_ease(Tween.EASE_IN_OUT)
	prog_tween.tween_property(progress_bar, "value", 100.0, 3.5)
	var panel_tween: Tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.8)
	await prog_tween.finished

	# Show question
	panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.3)
	await panel_tween.finished
	header.text = tr("CATEGORY_POINTS").format({"category": _category, "points": _points})
	if tournament_label:
		tournament_label.queue_free()
	if time_label:
		time_label.queue_free()
	var image_texture: ImageTexture = _question.load_image()
	if _show_questions:
		if _question.text:
			var question_text: Label = Label.new()
			question_text.label_settings = load("res://styles/labels/label_content_40.tres")
			question_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			question_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			question_text.text = _question.text
			panel_vbox.add_child(question_text)
		if image_texture:
			var image: TextureRect = TextureRect.new()
			#image.custom_minimum_size = Vector2(0.0, 400.0)
			image.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
			image.texture = image_texture
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			panel_vbox.add_child(image)
	await get_tree().create_timer(0.0).timeout
	var window_center: Vector2 = DisplayServer.window_get_size() / 2
	panel_container.position = window_center - panel_container.size / 2
	panel_container.pivot_offset = panel_container.size / 2
	panel_tween = create_tween()
	panel_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.8)
	await panel_tween.finished

	# Answers
	if _question.type in [Question.QuestionType.MultipleChoice, Question.QuestionType.Tournament]:
		var flow: Container
		if not image_texture:
			# Put answers below
			flow = HFlowContainer.new()
		else:
			flow = VBoxContainer.new()
		var answer_trects: Array[TextureRect] = []
		var answer_list: Array[Answer] = []
		answer_list.assign(
			_question.answers
			if _show_answers and _question.type == Question.QuestionType.MultipleChoice
			else []
		)
		if not answer_list:
			if _question.type == Question.QuestionType.MultipleChoice:
				var answer_correct: Answer = Answer.new()
				answer_correct.text = tr("CORRECT")
				answer_correct.is_correct = true
				var answer_wrong: Answer = Answer.new()
				answer_wrong.text = tr("WRONG")
				answer_list = [answer_correct, answer_wrong]
			elif _question.type == Question.QuestionType.Tournament:
				var team_list: Array[String] = _all_teams
				team_list.append(tr("NOBODY"))
				for team: String in team_list:
					var team_answer: Answer = Answer.new()
					team_answer.text = team
					answer_list.append(team_answer)
		for answer: Answer in answer_list:
			var answer_panel: PanelContainer = PanelContainer.new()
			answer_panel.gui_input.connect(answer_clicked.bind(answer, flow))
			var answer_label: Label = null
			if answer.text:
				answer_label = Label.new()
				answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				answer_label.text = answer.text
				answer_label.label_settings = load("res://styles/labels/label_content_40.tres")
				answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if not image_texture:
				answer_panel.custom_minimum_size.x = panel_container.size.x / 2 - 2
			else:
				answer_panel.custom_minimum_size.x = panel_container.size.x * 0.7
			answer_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var answer_vbox: VBoxContainer = VBoxContainer.new()
			var answer_image: ImageTexture = answer.load_image()
			if answer_image:
				var answer_trect: TextureRect = TextureRect.new()
				answer_trect.texture = answer_image
				answer_trect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
				answer_trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
				answer_trects.append(answer_trect)
				answer_vbox.add_child(answer_trect)
			if answer_label:
				answer_vbox.add_child(answer_label)
			answer_panel.add_child(answer_vbox)
			flow.add_child(answer_panel)
		add_child(flow)
		flow.modulate.a = 0.0
		if not image_texture:
			flow.size.x = panel_container.size.x
		await get_tree().create_timer(0.0).timeout
		if not image_texture:
			flow.position.x = panel_container.position.x
			flow.position.y = panel_container.position.y + panel_container.size.y + 20 - flow.size.y / 2
		else:
			flow.position.x = panel_container.position.x + panel_container.size.x - flow.size.x / 2 + 14
			flow.position.y = (panel_container.position.y + panel_container.size.y / 2) - flow.size.y / 2
		while flow.position.y + flow.size.y >= DisplayServer.window_get_size().y - 100 and answer_trects:
			var enough: bool = false
			for trect: TextureRect in answer_trects:
				if trect.custom_minimum_size == Vector2.ZERO:
					trect.custom_minimum_size = trect.size
				if trect.custom_minimum_size.y <= 100.0:
					enough = true
					break
				trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				trect.size_flags_vertical = Control.SIZE_EXPAND_FILL
				trect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				var aspect_ratio: float = trect.size.x / trect.size.y
				trect.custom_minimum_size.y -= 20.0
				trect.custom_minimum_size.x -= 20.0 * aspect_ratio
			if enough:
				break
			await get_tree().create_timer(0.0).timeout
			flow.size.y = 0.0
			if not image_texture:
				flow.position.x = panel_container.position.x
				flow.position.y = panel_container.position.y + panel_container.size.y + 20 - flow.size.y / 2
			else:
				flow.position.x = panel_container.position.x + panel_container.size.x - flow.size.x / 2 + 14
				flow.position.y = (panel_container.position.y + panel_container.size.y / 2) - flow.size.y / 2
		panel_tween = create_tween()
		panel_tween.set_ease(Tween.EASE_IN_OUT)
		if not image_texture:
			panel_tween.tween_property(
				panel_container, "position",
				Vector2(panel_container.position.x, panel_container.position.y - flow.size.y / 2),
				0.4,
			)
		else:
			panel_tween.tween_property(
				panel_container, "position",
				Vector2(panel_container.position.x - flow.size.x / 2, panel_container.position.y),
				0.4,
			)
		await panel_tween.finished
		var answers_tween: Tween = create_tween()
		answers_tween.set_ease(Tween.EASE_IN_OUT)
		answers_tween.tween_property(flow, "modulate", Color.WHITE, 0.4)


func answer_clicked(event: InputEvent, answer: Answer, answers_container: Container) -> void:
	if event.is_action_pressed("click"):
		panel_container.pivot_offset = panel_container.size / 2
		var panel_tween: Tween = create_tween()
		panel_tween.set_ease(Tween.EASE_IN_OUT)
		panel_tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.4)
		answers_container.pivot_offset = answers_container.size / 2
		var answers_tween: Tween = create_tween()
		answers_tween.set_ease(Tween.EASE_OUT)
		answers_tween.tween_property(answers_container, "scale", Vector2.ZERO, 0.4)
		await answers_tween.finished
		answers_container.queue_free()
		for child: Control in panel_container.get_children():
			panel_container.remove_child(child)
			child.queue_free()
		var state_label: Label = Label.new()
		state_label.label_settings = load("res://styles/labels/label_title_56.tres")
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var sub_label: Label = Label.new()
		sub_label.label_settings = load("res://styles/labels/label_content_40.tres")
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _question.type == Question.QuestionType.MultipleChoice:
			if answer.is_correct:
				var states: Array[String]
				states.assign(tr("CORRECT_STATES").split(":", false))
				states.shuffle()
				state_label.text = states[0]
				sub_label.text = (
					tr("CORRECT_SUB") if randi_range(1, 100) > 5 else tr("CORRECT_SUB_SECRET")
				).format([_points])
				var confetti: Confetti = confetti_scene.instantiate()
				confetti.position = DisplayServer.window_get_size() / 2
				add_child(confetti)
			else:
				var states: Array[String]
				states.assign(tr("WRONG_STATES").split(":", false))
				states.shuffle()
				state_label.text = states[0]
				if _pass_questions:
					sub_label.text = tr("WRONG_SUB_PASSING").format([_pass_team])
				else:
					sub_label.text = tr("WRONG_SUB")
		elif _question.type == Question.QuestionType.Tournament:
			if answer.text == tr("NOBODY"):
				state_label.text = tr("NOBODY_WON")
				sub_label.text = tr("NOBODY_WON_SUB")
			else:
				state_label.text = tr("TEAM_WON").format([answer.text])
				sub_label.text = tr("TEAM_WON_SUB").format([_points])
				var confetti: Confetti = confetti_scene.instantiate()
				confetti.position = DisplayServer.window_get_size() / 2
				add_child(confetti)
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_child(state_label)
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.y = 20.0
		vbox.add_child(spacer)
		vbox.add_child(sub_label)
		panel_container.add_child(vbox)
		panel_container.size = Vector2.ZERO
		await get_tree().create_timer(0.0).timeout
		panel_container.position = Vector2(DisplayServer.window_get_size() / 2) - panel_container.size / 2
		panel_container.pivot_offset = panel_container.size / 2
		panel_tween = create_tween()
		panel_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.4)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		quit()


func _on_cancel_button_pressed() -> void:
	quit()


func quit() -> void:
	emit_signal("canceled")
	get_parent().remove_child(self)  # Quit as soon as possible to avoid spoiler
	queue_free()
