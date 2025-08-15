@tool
extends Resource
class_name QuizSave

@export var name: String = tr("NEW_QUIZ")
@export var categories: Array[String] = [tr("CATEGORY_X").format(["1"])]
@export var point_stages: PackedInt64Array = [10]
@export var questions: Dictionary[String, Array] = {}  # Dictionary[String, Array[Question]]
@export var is_favorite: bool = false


func clone() -> QuizSave:
	var new: QuizSave = duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for category: String in new.categories:
		for question: Question in new.questions[category]:
			var image: ImageTexture = question.load_image()
			question.image_id = str(ResourceUID.create_id())
			if image:
				question.save_image(image.get_image())
			for answer: Answer in question.answers:
				var answer_image: ImageTexture = answer.load_image()
				answer.image_id = str(ResourceUID.create_id())
				if answer_image:
					answer.save_image(answer_image.get_image())
	return new


func rename_category(category: String, new: String) -> void:
	"""Rename a category. Changes both the 'questions' key and the 'categories' value."""
	var category_questions: Array = questions[category]
	questions.erase(category)
	questions[new] = category_questions
	var cat_index: int = categories.find(category)
	categories.erase(category)
	categories.insert(cat_index, new)


func change_point_stage_value(index: int, new_value: int) -> void:
	"""Change the points value of a point stage."""
	point_stages[index] = new_value


func move_category(category: String, up: bool = true) -> void:
	"""Move a category up if 'up' is true, else down."""
	var index: int = categories.find(category)
	if up:
		index -= 1
		if index < 0:
			index = 0
	else:
		index += 1
		if index > len(categories) - 1:
			index = len(categories) - 1
	categories.erase(category)
	categories.insert(index, category)


func add_category(category: String = "") -> void:
	"""Add a category."""
	if category == "":
		category = tr("CATEGORY_X").format([len(categories) + 1])
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
			var que: Question
			if len(questions[cat]) - 1 < i:
				que = Question.new()
			else:
				que = questions[cat].get(i)
			_new_questions[cat].append(que)
	questions = _new_questions
