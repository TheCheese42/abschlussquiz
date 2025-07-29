extends Node2D


var paused: bool = false

var options_save: OptionsSave = GlobalFunctions.load_options()


func _ready() -> void:
	GlobalFunctions.apply_options()
