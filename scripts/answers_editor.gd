extends CanvasLayer
class_name AnswersEditor

signal confirmed(answers: Array[Answer])
signal canceled

@onready var answers_grid: GridContainer = $ColorRect/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/AnswersGrid
@onready var answer_box: VBoxContainer = $AnswerBox

var picture_preview_scene: PackedScene = preload("res://scenes/picture_preview.tscn")
var accept_dialog_scene: PackedScene = preload("res://scenes/better_accept_dialog.tscn")

var _answers: Array[Answer] = []


func init(answers: Array[Answer]) -> void:
	_answers = answers


func _ready() -> void:
	rebuild_ui()


func rebuild_ui() -> void:
	for child: Control in answers_grid.get_children():
		answers_grid.remove_child(child)
		child.queue_free()
	var i: int = 1
	for answer: Answer in _answers:
		var new_answer_box: VBoxContainer = answer_box.duplicate()
		new_answer_box.visible = true
		var answer_label: Label = new_answer_box.find_child("AnswerLabel", true, false)
		answer_label.text = tr("ANSWER_X").format([i])
		var answer_text: LineEdit = new_answer_box.find_child("AnswerText", true, false)
		answer_text.text = answer.text
		answer_text.text_changed.connect(func(text: String) -> void: answer.text = text)
		var delete_button: TextureButton = new_answer_box.find_child("DeleteButton", true, false)
		delete_button.pressed.connect(func() -> void: _answers.erase(answer); rebuild_ui())
		var picture_button: Button = new_answer_box.find_child("PictureButton", true, false)
		picture_button.pressed.connect(func() -> void: select_picture(answer))
		var picture_preview_button: TextureButton = new_answer_box.find_child("PicturePreview", true, false)
		picture_preview_button.pressed.connect(func() -> void: show_preview(answer.image))
		var ppb_parent: PanelContainer = picture_preview_button.get_parent()
		ppb_parent.visible = answer.image != null
		var clear_picture_button: TextureButton = new_answer_box.find_child("ClearPicture", true, false)
		clear_picture_button.pressed.connect(func() -> void: answer.image = null; rebuild_ui())
		var cpb_parent: PanelContainer = clear_picture_button.get_parent()
		cpb_parent.visible = answer.image != null
		var correct_answer_check: CheckBox = new_answer_box.find_child("CorrectAnswerCheck", true, false)
		correct_answer_check.set_pressed_no_signal(answer.is_correct)
		correct_answer_check.toggled.connect(func(on: bool) -> void: answer.is_correct = on)
		answers_grid.add_child(new_answer_box)
		i += 1


func select_picture(answer: Answer) -> void:
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
	dialog.file_selected.connect(func(path: String) -> void: open_image(path, answer))
	dialog.visible = true
	add_child(dialog)
	dialog.popup_centered_ratio()
	dialog.show()


func open_image(path: String, answer: Answer) -> void:
	var image: Image = Image.load_from_file(path)
	if image == null:
		var dialog: BetterAcceptDialog = accept_dialog_scene.instantiate()
		dialog.title_text = tr("LOAD_IMAGE_ERROR_TITLE")
		dialog.content_text = tr("LOAD_IMAGE_ERROR_CONTENT")
		add_child(dialog)
		dialog.show()
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	answer.image = texture
	rebuild_ui()


func show_preview(image: ImageTexture) -> void:
	if image:
		var preview: PicturePreview = picture_preview_scene.instantiate()
		preview.texture = image
		add_child(preview)


func _on_ok_button_pressed() -> void:
	emit_signal("confirmed", _answers)
	queue_free()


func _on_cancel_button_pressed() -> void:
	emit_signal("canceled", _answers)
	queue_free()


func _on_add_answer_button_pressed() -> void:
	_answers.append(Answer.new())
	rebuild_ui()
