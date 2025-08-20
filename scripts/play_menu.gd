extends CanvasLayer
class_name PlayMenu

signal start_pressed(
	teams: PackedStringArray,
	show_questions: bool,
	show_answers: bool,
	pass_questions: bool,
	pass_points_multiplier: float,
	confirm_before_question: bool,
)
signal canceled

var confirmation_dialog_scene: PackedScene = preload("res://scenes/better_confirmation_dialog.tscn")
var accept_dialog_scene: PackedScene = preload("res://scenes/better_accept_dialog.tscn")

@onready var teams_v_box: VBoxContainer = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/ScrollContainer/TeamsVBox
@onready var team_h_box: HBoxContainer = $TeamHBox
@onready var teams_spin: SpinBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/OptionsBox/TeamsSpin/Control/TeamsSpin
@onready var show_questions_check: CheckBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/OptionsBox/ShowQuestionsCheck
@onready var show_answers_check: CheckBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/OptionsBox/ShowAnswersCheck
@onready var pass_questions_check: CheckBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/OptionsBox/PassQuestionsCheck
@onready var pass_multiplier_spin: SpinBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/OptionsBox/PassPercentBox/Control/PassMultiplierSpin
@onready var confirm_check: CheckBox = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/SetupHBox/OptionsBox/ConfirmCheck

var _num_questions: int


func _ready() -> void:
	GlobalFunctions.apply_theme_for_children(self)
	update_teams(roundi(teams_spin.value))


func init(num_questions: int) -> void:
	_num_questions = num_questions


func update_teams(new_count: int) -> void:
	var old_count: int = teams_v_box.get_child_count()
	while old_count > new_count:
		var child: Control = teams_v_box.get_child(old_count - 1)
		teams_v_box.remove_child(child)
		child.queue_free()
		old_count -= 1
	while new_count > old_count:
		var new_box: HBoxContainer = team_h_box.duplicate()
		new_box.visible = true
		var team_label: Label = new_box.find_child("TeamLabel", true, false)
		team_label.text = tr("TEAM_X_COLON").format([old_count + 1])
		var name_edit: LineEdit = new_box.find_child("TeamNameEdit", true, false)
		name_edit.text = tr("TEAM_X").format([old_count + 1])
		var rnd_button: TextureButton = new_box.find_child("RandomButton", true, false)
		rnd_button.pressed.connect(func() -> void: set_new_random_name(name_edit))
		teams_v_box.add_child(new_box)
		old_count += 1


func set_new_random_name(edit: LineEdit) -> void:
	var existing_names: PackedStringArray = []
	for team_hbox: HBoxContainer in teams_v_box.get_children():
		var team_name_edit: LineEdit = team_hbox.find_child("TeamNameEdit", true, false)
		existing_names.append(team_name_edit.text)
	var random_names: Array[String]
	random_names.assign(tr("TEAM_NAMES").split(":", false))
	random_names.shuffle()
	edit.text = tr("NO_TEAM_NAME_FOUND")
	for name_: String in random_names:
		if name_ not in existing_names:
			edit.text = name_


func _on_teams_spin_value_changed(value: float) -> void:
	update_teams(roundi(value))


func _on_cancel_button_pressed() -> void:
	emit_signal("canceled")
	queue_free()


func _on_start_button_pressed() -> void:
	var num_teams: int = roundi(teams_spin.value)
	if _num_questions % num_teams != 0:
		if not Input.is_action_pressed("confirm"):
			var dialog: BetterConfirmationDialog = confirmation_dialog_scene.instantiate()
			dialog.title_text = tr("IMPOSSIBLE_QUESTION_DISTRIBUTION_TITLE")
			dialog.content_text = tr("IMPOSSIBLE_QUESTION_DISTRIBUTION_CONTENT").format(
				{"questions": _num_questions, "teams": num_teams,
				"remainder": _num_questions % num_teams}
			)
			dialog.ok_button_text = tr("YES")
			dialog.cancel_button_text = tr("NO")
			dialog.confirmed.connect(emit_start)
			add_child(dialog)
			dialog.show()
	else:
		emit_start()


func emit_start() -> void:
	var team_names: PackedStringArray = []
	for team_box: HBoxContainer in teams_v_box.get_children():
		var name_edit: LineEdit = team_box.find_child("TeamNameEdit", true, false)
		var team_name: String = name_edit.text
		if team_name.is_empty():
			var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
			dialog.title_text = tr("EMPTY_TEAM_NAMES_TITLE")
			dialog.content_text = tr("EMPTY_TEAM_NAMES_CONTENT")
			add_child(dialog)
			dialog.show()
			return
		if team_name in team_names:
			var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
			dialog.title_text = tr("DUPLICATE_TEAM_NAMES_TITLE")
			dialog.content_text = tr("DUPLICATE_TEAM_NAMES_CONTENT")
			add_child(dialog)
			dialog.show()
			return
		if team_name == tr("NOBODY"):
			# Prevent a team called tr("NOBODY") to get points
			# when no team whon at a tournament question
			team_name = tr("TEAM_X").format(team_name)
		team_names.append(team_name)
	emit_signal(
		"start_pressed",
		team_names,
		show_questions_check.button_pressed,
		show_answers_check.button_pressed,
		pass_questions_check.button_pressed if len(team_names) > 1 else false,
		pass_multiplier_spin.value,
		confirm_check.button_pressed,
	)
	queue_free()
