extends CanvasLayer
class_name PlayQuestion

#signal completed(correct: bool, team: String, points: int)  # (false, "", 0) if not  answered correctly.
signal canceled

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
		tournament_label.modulate.a = 0.0
		var tournament_tween: Tween = create_tween()
		tournament_tween.set_ease(Tween.EASE_OUT)
		tournament_tween.tween_property(tournament_label, "modulate", Color.WHITE, 1.0)
		panel_vbox.add_child(tournament_label)
		if _question.time > 0:
			time_label = Label.new()
			time_label.label_settings = load("res://styles/labels/label_content_32.tres")
			time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			time_label.text = tr("YOU_HAVE_X_SECONDS").format([_question.time])
			time_label.modulate.a = 0.0
			var time_tween: Tween = create_tween()
			time_tween.set_ease(Tween.EASE_OUT)
			time_tween.tween_property(time_label, "modulate", Color.WHITE, 1.2)
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
	if _show_questions:
		var question_text: Label = Label.new()
		question_text.label_settings = load("res://styles/labels/label_content_32.tres")
		question_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question_text.text = _question.text
		panel_vbox.add_child(question_text)
		var image_texture: ImageTexture = _question.load_image()
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
	panel_container.pivot_offset = panel_container.size / 2#Vector2.ZERO#window_center - panel_container.global_position
	panel_tween = create_tween()
	panel_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.8)


func _on_cancel_button_pressed() -> void:
	emit_signal("canceled")
	get_parent().remove_child(self)  # Quit as soon as possible to avoid spoiler
	queue_free()
