extends Node2D


var next_save_to_be_edited: QuizSave = null

var options_save: OptionsSave = GlobalFunctions.load_options()
var quiz_saves: QuizSaves = GlobalFunctions.load_quiz_saves()


func _ready() -> void:
	GlobalFunctions.apply_options()
