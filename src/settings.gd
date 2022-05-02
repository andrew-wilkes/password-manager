extends Resource

class_name Settings

const FILE_NAME = "user://settings.tres"

export var salt = "%#~!?~"
export var pw_file = "pw-1.tres"

func save_data():
	var _result = ResourceSaver.save(FILE_NAME, self)


func load_data():
	if ResourceLoader.exists(FILE_NAME):
		return ResourceLoader.load(FILE_NAME)
	else:
		return self
