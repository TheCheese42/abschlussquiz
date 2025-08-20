extends CanvasLayer
class_name GameOver

var confetti_scene: PackedScene = preload("res://scenes/confetti.tscn")

@onready var congrats_panel: PanelContainer = $ColorRect/CongratsPanel
@onready var winner_panel: PanelContainer = $ColorRect/WinnerPanel
@onready var others_v_box: VBoxContainer = $ColorRect/WinnerPanel/MarginContainer/VBoxContainer/OthersVBox
@onready var winner_label: Label = $ColorRect/WinnerPanel/MarginContainer/VBoxContainer/WinnerLabel
@onready var finish_button: Button = $ColorRect/WinnerPanel/MarginContainer/VBoxContainer/FinishButton

var _teams_points: Dictionary[String, int]


func init(teams_points: Dictionary[String, int]) -> void:
	_teams_points = teams_points


func _ready() -> void:
	GlobalFunctions.apply_theme_for_children(self)
	start_show()


func start_show() -> void:
	var teams_ordered: Array[String] = []
	var teams: Array[String] = _teams_points.keys()
	var points: Array[int] = []
	var final_teams_points: Dictionary[String, int] = {}
	for team: String in teams:
		points.append(_teams_points[team])
	while teams:
		var highest_points_team: String = ""
		var highest_points_points: int = 0
		var to_remove: Array[int] = []
		for idx: int in len(teams):
			var t_name: String = teams[idx]
			var t_points: int = points[idx]
			if not highest_points_team:
				to_remove.append(idx)
				highest_points_team = t_name
				highest_points_points = t_points
			else:
				if t_points == highest_points_points:
					to_remove.append(idx)
					highest_points_team += ", " + t_name
				elif t_points > highest_points_points:
					to_remove.clear()
					to_remove.append(idx)
					highest_points_team = t_name
					highest_points_points = t_points
		to_remove.reverse()
		for idx: int in to_remove:
			teams.remove_at(idx)
			points.remove_at(idx)
		teams_ordered.append(highest_points_team)
		final_teams_points[highest_points_team] = highest_points_points

	congrats_panel.pivot_offset = congrats_panel.size / 2
	winner_panel.pivot_offset = winner_panel.size / 2
	congrats_panel.scale = Vector2.ZERO
	var congrats_tween: Tween = create_tween()
	congrats_tween.tween_property(congrats_panel, "scale", Vector2.ONE, 0.4)
	await congrats_tween.finished
	await get_tree().create_timer(3.0).timeout
	congrats_tween = create_tween()
	congrats_tween.tween_property(congrats_panel, "scale", Vector2.ZERO, 0.4)
	await congrats_tween.finished
	congrats_panel.visible = false
	winner_panel.visible = true
	winner_panel.scale = Vector2.ZERO
	var winner_tween: Tween = create_tween()
	winner_tween.tween_property(winner_panel, "scale", Vector2.ONE, 0.4)
	var winner_team: String = teams_ordered.pop_front()
	winner_label.text = tr("TEAM_POINTS").format(
		{"team": winner_team, "points": final_teams_points[winner_team]}
	)
	winner_label.modulate = Color.TRANSPARENT
	var other_labels: Array[Label] = []
	for other_team: String in teams_ordered:
		var label: Label = Label.new()
		label.label_settings = load("res://styles/labels/label_content_32.tres")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = tr("TEAM_POINTS").format(
			{"team": other_team, "points": final_teams_points[other_team]}
		)
		label.modulate = Color.TRANSPARENT
		other_labels.append(label)
		others_v_box.add_child(label)
	await winner_tween.finished
	winner_tween = create_tween()
	winner_tween.tween_property(winner_label, "modulate", Color.WHITE, 0.5).set_delay(1.0)
	await winner_tween.finished
	var confetti: Confetti = confetti_scene.instantiate()
	confetti.position = DisplayServer.window_get_size() / 2
	add_child(confetti)
	for _i: int in 3:
		await get_tree().create_timer(0.5).timeout
		confetti = confetti_scene.instantiate()
		confetti.position = DisplayServer.window_get_size() / 2
		add_child(confetti)
	for label: Label in other_labels:
		var other_tween: Tween = create_tween()
		other_tween.tween_property(label, "modulate", Color.WHITE, 0.4)
		await other_tween.finished
	winner_tween = create_tween()
	winner_tween.tween_property(finish_button, "modulate", Color.WHITE, 0.5)
	finish_button.disabled = false


func _on_finish_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_window.tscn")
