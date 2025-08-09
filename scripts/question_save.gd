@tool
extends Resource
class_name Question

@export var type: QuestionType = QuestionType.MultipleChoice
@export var text: String = ""
@export var image_id: String = str(ResourceUID.create_id())
@export var time: int = 0  # 0 means no limit
@export var answers: Array[Answer] = []


func save_image(image: Image) -> void:
	DirAccess.make_dir_absolute("user://saves")
	DirAccess.make_dir_absolute("user://saves/images")
	image.save_jpg("user://saves/images/" + image_id + ".jpg")


func load_image() -> ImageTexture:
	var path: String = "user://saves/images/" + image_id + ".jpg"
	if FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image == null:
			return null
		return ImageTexture.create_from_image(image)
	return null


func delete_image() -> void:
	DirAccess.remove_absolute("user://saves/images/" + image_id + ".jpg")


enum QuestionType {
	MultipleChoice,
	Tournament,
}
