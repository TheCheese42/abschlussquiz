extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var version_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/VersionLabel
@onready var developer_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/DeveloperLabel
@onready var testers_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/TestersLabel
@onready var icons_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/IconsLabel
@onready var fonts_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FontsLabel
@onready var licenses_label: Label = $PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/LicensesLabel


func _ready() -> void:
	var file: FileAccess
	file = FileAccess.open("res://version.txt", FileAccess.READ)
	var version: String = file.get_line()
	file.close()
	version_label.text = tr("VERSION_X").format([version])
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

	# Quit button, licenses

	on_resize(DisplayServer.window_get_size())


func on_resize(new_size: Vector2i) -> void:
	panel_container.custom_minimum_size.y = new_size.y - 100
	panel_container.size.y = new_size.y - 100
	panel_container.position = Vector2(new_size) / 2 - panel_container.size / 2
