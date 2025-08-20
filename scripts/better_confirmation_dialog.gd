extends CanvasLayer
class_name BetterConfirmationDialog

signal confirmed
signal canceled

@onready var _title: Label = $ColorRect/PanelContainer/VBoxContainer/Title
@onready var _content: Label = $ColorRect/PanelContainer/VBoxContainer/Content
@onready var _ok_button: Button = $ColorRect/PanelContainer/VBoxContainer/HBoxContainer/OKButton
@onready var _cancel_button: Button = $ColorRect/PanelContainer/VBoxContainer/HBoxContainer/CancelButton

var is_done: bool = false  # Prevent double emitting

@export var title_text: String = ""
@export var content_text: String = ""
@export var ok_button_text: String = tr("OK")
@export var cancel_button_text: String = tr("CANCEL")


func _ready() -> void:
	GlobalFunctions.apply_theme_for_children(self)
	_title.text = title_text
	_content.text = content_text
	_ok_button.text = ok_button_text
	_cancel_button.text = cancel_button_text


func _on_ok_button_pressed() -> void:
	if is_done:
		return
	emit_signal("confirmed")
	is_done = true
	queue_free()


func _on_cancel_button_pressed() -> void:
	if is_done:
		return
	emit_signal("canceled")
	is_done = true
	queue_free()
