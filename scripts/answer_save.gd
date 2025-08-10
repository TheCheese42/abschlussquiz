@tool
extends Resource
class_name Answer

@export var text: String = ""
@export var image_id: String = str(ResourceUID.create_id())
@export var is_correct: bool = false


func save_image(image: Image) -> void:
	DirAccess.make_dir_absolute("user://saves")
	DirAccess.make_dir_absolute("user://saves/images")
	image.save_png("user://saves/images/" + image_id + ".png")


func load_image() -> ImageTexture:
	var path: String = "user://saves/images/" + image_id + ".png"
	if FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image == null:
			return null
		return ImageTexture.create_from_image(image)
	return null


func delete_image() -> void:
	DirAccess.remove_absolute("user://saves/images/" + image_id + ".png")
