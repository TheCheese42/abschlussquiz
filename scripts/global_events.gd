extends Node


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			GlobalVars.options_save.window_size = DisplayServer.window_get_size()
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		GlobalVars.options_save.window_mode = DisplayServer.window_get_mode()
		GlobalFunctions.save_options()
	if DisplayServer.window_get_size() != GlobalVars.options_save.window_size:
		GlobalVars.options_save.window_size = DisplayServer.window_get_size()
		GlobalFunctions.save_options()
