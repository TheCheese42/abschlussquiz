@tool
extends Resource
class_name QuizSave

@export var name: String = ""
@export var categories: PackedStringArray = [tr("CATEGORY_X").format("1")]
@export var point_stages: PackedInt64Array = [10]
@export var questions: Dictionary[String, Array] = {}  # Dictionary[String, Array[Question]]


func rename_category(category: String, new: String) -> void:
	"""Rename a category. Changes both the 'questions' key and the 'categories' value."""
	var category_questions: Array[Question] = questions[category]
	questions.erase(category)
	questions[new] = category_questions
	var cat_index: int = categories.find(category)
	categories.erase(category)
	categories[cat_index] = new


func change_point_stage_value(index: int, new_value: int) -> void:
	"""Change the points value of a point stage."""
	point_stages[index] = new_value


func move_category(category: String, up: bool = true) -> void:
	"""Move a category up if 'up' is true, else down."""
	var index: int = categories.find(category)
	if up:
		index -= 1
	else:
		index += 1
	categories.erase(category)
	categories.insert(index, category)


func add_category(category: String = "") -> void:
	"""Add a category."""
	if category == "":
		category = tr("CATEGORY_X").format(len(categories) + 1)
	while category in categories:
		category += "_"
	categories.append(category)
	update_questions()


func add_point_stage(value: int = 0) -> void:
	"""Add a point stage."""
	point_stages.append(value)
	update_questions()


func remove_category(category: String) -> void:
	"""Remove a category. All corresponding questions will be removed as well."""
	categories.erase(category)
	update_questions()


func remove_last_point_stage() -> void:
	"""Remove the last point stage. All corresponding questions will be removed as well."""
	point_stages.remove_at(len(point_stages) - 1)
	update_questions()


func update_questions() -> void:
	"""To be called after adding or removing categories and point stages."""
	var _new_questions: Dictionary[String, Array] = {}
	for cat: String in categories:
		_new_questions[cat] = []
		for i: int in len(point_stages):
			if not questions.has(cat):  # If the category was just added to categories
				questions[cat] = []
			var que: Question = questions[cat].get(i)
			if que == null:
				que = Question.new()
			_new_questions[cat].append(que)
	questions = _new_questions


enum QuestionType {
	MultipleChoice,
	Tournament,
}


class Question extends Resource:
	var type: QuestionType = QuestionType.MultipleChoice
	var text: String = ""
	var image: ImageTexture = null
	var time: int = 0  # 0 is no limit
	var answers: Array[Answer] = []


class Answer extends Resource:
	var text: String = ""
	var image: ImageTexture = null
	var is_correct: bool = false
