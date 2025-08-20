extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var version_label: Label = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer/VersionLabel
@onready var developer_label: Label = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer/DeveloperLabel
@onready var testers_label: Label = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer/TestersLabel
@onready var icons_label: Label = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer/IconsLabel
@onready var fonts_label: Label = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer/FontsLabel
@onready var licenses_label: Label = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer/LicensesLabel
@onready var all_vbox: VBoxContainer = $PanelContainer/ScrollContainer/MarginContainer/VBoxContainer


func _ready() -> void:
	GlobalFunctions.apply_theme_for_children(self)
	var version: String = GlobalVars.options_save.version
	version_label.text = tr("VERSION_X").format([version])
	var file: FileAccess
	file = FileAccess.open("res://assets/attributions/developers.txt", FileAccess.READ)
	var developers: PackedStringArray = file.get_as_text().split("\n", false)
	file.close()
	developer_label.text = "\n".join(developers)
	file = FileAccess.open("res://assets/attributions/testers.txt", FileAccess.READ)
	var testers: PackedStringArray = file.get_as_text().split("\n", false)
	file.close()
	testers_label.text = "\n".join(testers)
	file = FileAccess.open("res://assets/attributions/icons.txt", FileAccess.READ)
	var icons: PackedStringArray = file.get_as_text().split("\n", false)
	file.close()
	icons_label.text = "\n".join(icons)
	file = FileAccess.open("res://assets/attributions/fonts.txt", FileAccess.READ)
	var fonts: PackedStringArray = file.get_as_text().split("\n", false)
	file.close()
	fonts_label.text = "\n".join(fonts)

	file = FileAccess.open("res://assets/attributions/GODOT_COPYRIGHT.txt", FileAccess.READ)
	var licenses: String = file.get_as_text()
	file.close()
	var lic_label: Label = Label.new()
	lic_label.text = licenses
	lic_label.label_settings = load("res://styles/labels/label_licenses_12.tres")
	lic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	all_vbox.add_child(lic_label)

	on_resize(DisplayServer.window_get_size())


func on_resize(new_size: Vector2i) -> void:
	panel_container.custom_minimum_size.y = new_size.y - 100
	panel_container.size.y = new_size.y - 100
	panel_container.position = Vector2(new_size) / 2 - panel_container.size / 2


func _on_back_button_pressed() -> void:
	queue_free()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		queue_free()
