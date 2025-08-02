extends Resource
class_name Question
	
var type: QuestionType = QuestionType.MultipleChoice
var text: String = ""
var image: ImageTexture = null
var time: int = 0  # 0 means no limit
var answers: Array[Answer] = []


enum QuestionType {
	MultipleChoice,
	Tournament,
}
