extends Node


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		get_tree().call_group("events", "on_resize", DisplayServer.window_get_size())
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_position(GlobalVars.options_save.window_pos)
			DisplayServer.window_set_size(GlobalVars.options_save.window_size)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		GlobalVars.options_save.window_mode = DisplayServer.window_get_mode()
		GlobalFunctions.save_options()
	if DisplayServer.window_get_mode() != GlobalVars.options_save.window_mode:
		get_tree().call_group("events", "on_resize", DisplayServer.window_get_size())
		GlobalVars.options_save.window_mode = DisplayServer.window_get_mode()
		if GlobalVars.options_save.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_position(GlobalVars.options_save.window_pos)
			DisplayServer.window_set_size(GlobalVars.options_save.window_size)
		GlobalFunctions.save_options()
	if DisplayServer.window_get_size() != GlobalVars.options_save.window_size:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			return
		get_tree().call_group("events", "on_resize", DisplayServer.window_get_size())
		GlobalVars.options_save.window_size = DisplayServer.window_get_size()
		GlobalFunctions.save_options()
	if DisplayServer.window_get_position() != GlobalVars.options_save.window_pos:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			return
		GlobalVars.options_save.window_pos = DisplayServer.window_get_position()
		GlobalFunctions.save_options()
