extends Resource

class_name Settings

const FILE_NAME = "user://settings.tres"

export(String) var salt
export var pw_file = "pw-1.tres"

func save_data():
	var _result = ResourceSaver.save(FILE_NAME, self)


func load_data():
	salt = generate_salt()
	if ResourceLoader.exists(FILE_NAME):
		return ResourceLoader.load(FILE_NAME)
	else:
		return self


func generate_salt():
	# Using a-z0-9 characters so that a user may copy them easily to another device
	var _salt = PoolStringArray()
	for n in 8 + randi() % 5: # 8 .. 12
		var x = randi() % 36
		_salt.append(get_char(x))
	return _salt.join("")


func get_char(x):
		if x < 10:
			return str(x)
		else:
			return char(x + 87)


func test_get_char():
	var chrs = PoolStringArray()
	for n in 36:
		chrs.append(get_char(n))
	print(chrs)


func test_generate_salt():
	for n in 10:
		print(generate_salt())
