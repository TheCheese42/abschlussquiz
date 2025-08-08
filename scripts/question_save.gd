@tool
extends Resource
class_name Question

@export var type: QuestionType = QuestionType.MultipleChoice
@export var text: String = ""
@export var image: ImageTexture = null
@export var time: int = 0  # 0 means no limit
@export var answers: Array[Answer] = []


enum QuestionType {
	MultipleChoice,
	Tournament,
}
