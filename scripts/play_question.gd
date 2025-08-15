extends CanvasLayer
class_name PlayQuestion

signal completed(correct: bool, team: String, points: int)  # (false, "", 0) if not  answered correctly.
signal canceled

var confetti_scene: PackedScene = preload("res://scenes/confetti.tscn")

@onready var progress_bar: ProgressBar = $ColorRect/ProgressBar
@onready var panel_container: PanelContainer = $ColorRect/PanelContainer
@onready var panel_margin: MarginContainer = $ColorRect/PanelContainer/MarginContainer
@onready var panel_vbox: VBoxContainer = $ColorRect/PanelContainer/MarginContainer/VBoxContainer
@onready var cancel_button: Button = $ColorRect/MarginContainer/CancelButton
@onready var color_rect: ColorRect = $ColorRect

var _question: Question
var _category: String
var _points: int
var _team: String
var _show_questions: bool
var _show_answers: bool
var _pass_questions: bool
var _pass_team: String
var _pass_multiplier: float
var _confirm_before_question: bool
var _all_teams: Array[String]
var _is_pass_run: bool = false


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
	confirm_before_question: bool,
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
	_confirm_before_question = confirm_before_question
	_all_teams = all_teams


func _ready() -> void:
	start_show()


func start_show() -> void:
	panel_container.scale = Vector2.ZERO
	progress_bar.value = 0.0
	var header: Label = panel_container.find_child("Header", true, false)
	var tournament_label: Label = null
	var time_label: Label = null
	var time_bar: ProgressBar = null
	var time_bar_tween: Tween = null
	var proceed_button: Button = null
	if not _is_pass_run:
		header.text = tr("QUESTION_INTRO").format({"category": _category, "points": _points})
		if _is_pass_run:
			header.text += "\n" + tr("TEAM_TURN").format([_team])
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
				time_bar = ProgressBar.new()
				time_bar.custom_minimum_size.y = 10
				time_bar.show_percentage = false
				time_bar.max_value = _question.time
				time_bar.value = _question.time 
				var time_bar_stylebox: StyleBoxFlat = StyleBoxFlat.new()
				time_bar_stylebox.set_corner_radius_all(10)
				time_bar_stylebox.bg_color = Color(0x39c457ff)
				time_bar.add_theme_stylebox_override("fill", time_bar_stylebox)
				time_bar_tween = create_tween()
				time_bar_tween.tween_property(time_bar, "value", 0.0, _question.time)
				time_bar_tween.pause()
				var time_bar_color_tween: Tween = create_tween()
				time_bar_color_tween.set_trans(Tween.TRANS_EXPO)
				time_bar_color_tween.set_ease(Tween.EASE_IN)
				time_bar_color_tween.tween_property(
					time_bar_stylebox, "bg_color", Color(0xc45039ff), _question.time
				)
				var time_up: Callable = func() -> void:
					var time_bar_fade_tween: Tween = create_tween()
					time_bar_fade_tween.set_ease(Tween.EASE_IN_OUT)
					time_bar_fade_tween.tween_property(time_bar, "modulate", Color.TRANSPARENT, 0.5)
					await time_bar_fade_tween.finished
				time_bar_tween.finished.connect(time_up)
		if _confirm_before_question:
			proceed_button = Button.new()
			proceed_button.text = tr("PROCEED")
			proceed_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var key_enter: InputEventKey = InputEventKey.new()
			key_enter.keycode = KEY_ENTER
			var key_space: InputEventKey = InputEventKey.new()
			key_space.keycode = KEY_SPACE
			var shortcut: Shortcut = Shortcut.new()
			shortcut.events = [key_enter, key_space]
			proceed_button.set_shortcut(shortcut)
			proceed_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			panel_vbox.add_child(proceed_button)
		await get_tree().create_timer(0.0).timeout
		panel_container.position = Vector2(DisplayServer.window_get_size()) / 2 - panel_container.size / 2
		var panel_tween_: Tween = create_tween()
		panel_tween_.set_ease(Tween.EASE_OUT)
		panel_tween_.tween_property(panel_container, "scale", Vector2.ONE, 0.8)
		if not proceed_button:
			# No need for a progress bar if the user has to click anyway
			var prog_tween: Tween = create_tween()
			prog_tween.set_ease(Tween.EASE_IN_OUT)
			prog_tween.tween_property(progress_bar, "value", 100.0, 3.5 if not _is_pass_run else 3.0)
			await prog_tween.finished
		else:
			await proceed_button.pressed

	# Show question
	var panel_tween: Tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.3)
	await panel_tween.finished
	header.text = tr("CATEGORY_POINTS").format({"category": _category, "points": _points})
	if tournament_label:
		tournament_label.queue_free()
	if time_label:
		time_label.queue_free()
	if proceed_button:
		proceed_button.queue_free()
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
			image.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
			image.texture = image_texture
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			panel_vbox.add_child(image)
	if time_bar:
		panel_vbox.add_child(time_bar)
	panel_vbox.size.y = 0.0
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
				answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				answer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		await answers_tween.finished
		if time_bar_tween:
			await get_tree().create_timer(0.5).timeout
			time_bar_tween.play()


func answer_clicked(event: InputEvent, answer: Answer, answers_container: Container) -> void:
	if not event.is_action_pressed("click"):
		return
	for child: Control in answers_container.get_children():
		child.set_block_signals(true)
	cancel_button.visible = false
	cancel_button.disabled = true
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
	for child: Control in panel_vbox.get_children():
		if child.name == "Header":
			continue
		panel_vbox.remove_child(child)
		child.queue_free()
	var state_label: Label = panel_vbox.find_child("Header", true, false)
	state_label.label_settings = load("res://styles/labels/label_title_56.tres")
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub_label: Label = Label.new()
	sub_label.label_settings = load("res://styles/labels/label_content_40.tres")
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var was_correct: bool = false
	var active_team: String = ""  # "" means no team won in a tournament or multiple choice if passed and still wrong
	var proceed_button: Button = null
	if _question.type == Question.QuestionType.MultipleChoice:
		active_team = _team
		if answer.is_correct:
			was_correct = true
			var states: Array[String]
			states.assign(tr("CORRECT_STATES").split(":", false))
			states.shuffle()
			state_label.text = states[0]
			sub_label.text = (
				# 5% chance for secret message
				tr("CORRECT_SUB") if randi_range(1, 100) > 5 else tr("CORRECT_SUB_SECRET")
			).format([_points])
			var confetti: Confetti = confetti_scene.instantiate()
			confetti.position = DisplayServer.window_get_size() / 2
			get_parent().add_child(confetti)
		else:
			var states: Array[String]
			states.assign(tr("WRONG_STATES").split(":", false))
			states.shuffle()
			state_label.text = states[0]
			if _pass_questions:
				sub_label.text = tr("WRONG_SUB_PASSING").format([_pass_team])
				if _confirm_before_question:
					proceed_button = Button.new()
					proceed_button.text = tr("PROCEED")
					proceed_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					var key_enter: InputEventKey = InputEventKey.new()
					key_enter.keycode = KEY_ENTER
					var key_space: InputEventKey = InputEventKey.new()
					key_space.keycode = KEY_SPACE
					var shortcut: Shortcut = Shortcut.new()
					shortcut.events = [key_enter, key_space]
					proceed_button.set_shortcut(shortcut)
					proceed_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			else:
				sub_label.text = tr("WRONG_SUB")
	elif _question.type == Question.QuestionType.Tournament:
		if answer.text == tr("NOBODY"):
			state_label.text = tr("NOBODY_WON")
			sub_label.text = tr("NOBODY_WON_SUB")
		else:
			active_team = answer.text
			was_correct = true
			state_label.text = tr("TEAM_WON").format([answer.text])
			sub_label.text = tr("TEAM_WON_SUB").format([_points])
			var confetti: Confetti = confetti_scene.instantiate()
			confetti.position = DisplayServer.window_get_size() / 2
			add_child(confetti)
	panel_vbox.add_child(sub_label)
	if proceed_button:
		panel_vbox.add_child(proceed_button)
	panel_container.size = Vector2.ZERO
	state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	await get_tree().create_timer(0.0).timeout
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_container.position = Vector2(DisplayServer.window_get_size() / 2) - panel_container.size / 2
	panel_container.pivot_offset = panel_container.size / 2
	panel_tween = create_tween()
	panel_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.4)
	progress_bar.value = 0.0
	if not proceed_button:
		var prog_tween: Tween = create_tween()
		prog_tween.set_ease(Tween.EASE_IN_OUT)
		prog_tween.tween_property(progress_bar, "value", 100.0, 3)
		await prog_tween.finished
	else:
		await proceed_button.pressed
	panel_tween = create_tween()
	panel_tween.tween_property(panel_container, "scale", Vector2.ZERO, 0.4)
	await panel_tween.finished
	if _question.type == Question.QuestionType.MultipleChoice and not was_correct and _pass_questions:
		_team = _pass_team
		_points = roundi(_points * _pass_multiplier)
		_pass_questions = false
		_is_pass_run = true
		for child: Control in panel_vbox.get_children():
			if child.name == "Header":
				continue
			panel_vbox.remove_child(child)
			child.queue_free()
		start_show()
	else:
		var crect_tween: Tween = create_tween()
		crect_tween.set_ease(Tween.EASE_IN_OUT)
		crect_tween.tween_property(color_rect, "color", Color.TRANSPARENT, 0.3)
		await crect_tween.finished
		if not was_correct and _is_pass_run:
			active_team = ""
		emit_signal("completed", was_correct, active_team, _points)
		queue_free()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		if not cancel_button.disabled:
			quit()


func _on_cancel_button_pressed() -> void:
	quit()


func quit() -> void:
	emit_signal("canceled")
	get_parent().remove_child(self)  # Quit as soon as possible to avoid spoiler
	queue_free()
