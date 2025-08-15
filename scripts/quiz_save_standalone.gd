@tool
extends Resource
class_name QuizSaveStandalone
# Intended to be saved as file. Contains the raw image data.

@export var name: String = tr("NEW_QUIZ")
@export var categories: Array[String] = [tr("CATEGORY_X").format(["1"])]
@export var point_stages: PackedInt64Array = [10]
@export var questions: Dictionary[String, Array] = {}  # Dictionary[String, Array[Question]]
@export var is_favorite: bool = false
@export var images: Dictionary[String, Image] = {}


func from_quiz_save(quiz_save: QuizSave) -> void:
	"""Also stores images within the save."""
	name = quiz_save.name
	categories = quiz_save.categories
	point_stages = quiz_save.point_stages
	questions = quiz_save.questions
	is_favorite = quiz_save.is_favorite
	for category: String in categories:
		for question: Question in questions[category]:
			var image: ImageTexture = question.load_image()
			if image:
				images[question.image_id] = image.get_image()
			else:
				images[question.image_id] = null
			for answer: Answer in question.answers:
				var answer_image: ImageTexture = answer.load_image()
				if answer_image:
					images[answer.image_id] = answer_image.get_image()
				else:
					images[answer.image_id] = null


func load_to_quiz_save() -> QuizSave:
	"""
	The quiz_save is not copied, so it shouldn't be used after the operation.
	Also saves images to disk.
	"""
	var quiz_save: QuizSave = QuizSave.new()
	quiz_save.name = name
	quiz_save.categories = categories
	quiz_save.point_stages = point_stages
	quiz_save.questions = questions
	quiz_save.is_favorite = is_favorite
	for category: String in categories:
		for question: Question in questions[category]:
			var image: Image = images[question.image_id]
			question.image_id = str(ResourceUID.create_id())
			if image:
				question.save_image(image)
			for answer: Answer in question.answers:
				var answer_image: ImageTexture = answer.load_image()
				answer.image_id = str(ResourceUID.create_id())
				if answer_image:
					answer.save_image(answer_image.get_image())
	return quiz_save
