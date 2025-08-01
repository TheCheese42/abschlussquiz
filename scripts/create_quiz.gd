extends CanvasLayer

var confirmation_dialog_scene: PackedScene = preload("res://scenes/better_confirmation_dialog.tscn")

@onready var title: Label = $MarginContainer/HBoxContainer/Title
@onready var quiz_name: LineEdit = $MarginContainer/TabContainer/GENERAL/GENERAL/HBoxContainer/QuizName
@onready var category_h_box: HBoxContainer = $CategoryHBox
@onready var points_h_box: HBoxContainer = $PointsHBox
@onready var categories_v_box: VBoxContainer = $MarginContainer/TabContainer/CATEGORIES/CATEGORIES/HBoxContainer/CategoryContainer/CategoriesVBox
@onready var points_v_box: VBoxContainer = $MarginContainer/TabContainer/CATEGORIES/CATEGORIES/HBoxContainer/PointsContainer/PointsVBox

var edit: bool = false
var save: QuizSave = null

# TODO IMPORTANT
# Allow undo and redo, make backups.


func _ready() -> void:
	if not edit:
		save = QuizSave.new()
	rebuild_ui()


func edit_quiz(quiz_save: QuizSave) -> void:
	"""Call this before adding the node to the scene tree to edit instead of creating."""
	save = quiz_save
	edit = true


func rebuild_ui() -> void:
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
		cat_edit.connect("text_changed", func(new: String) -> void: save.rename_category(category, new))
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


func remove_category(category: String) -> void:
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
	get_tree().change_scene_to_file("res://scenes/main_window.tscn")
