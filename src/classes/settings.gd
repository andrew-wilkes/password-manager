extends Resource

class_name Settings

const FILE_NAME = "user://settings.tres"

export(String) var salt
export var current_file = "pw1.pwd"
export var last_dir = ""
export var date_format = "YYYY-MM-DD"
export var groups = {}
export var keys = []
export var key_idx = 0

func save_data():
	var _result = ResourceSaver.save(FILE_NAME, self)


func load_data():
	salt = generate_salt()
	if ResourceLoader.exists(FILE_NAME):
		return ResourceLoader.load(FILE_NAME)
	else:
		last_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		return self


func generate_salt(short = false):
	# In the UI it is called a Key
	if short:
		# Using a-z0-9 characters so that a user may copy them easily to another device
		# We will not store the salt value in the password db file, otherwise it defeats its purpose
		var _salt = PoolStringArray()
		for _n in 8 + randi() % 5: # 8 .. 12
			var x = randi() % 36
			_salt.append(get_char(x))
		return _salt.join("")
	else:
		# Convert a random number to a hash string and then trim the hash so
		# that it is not the typical length of a hash
		var h = str(randi()).sha256_text()
		var i = randi() % 8 + 1
		return h.substr(i)


func get_char(x):
	if x < 10:
		return str(x)
	else:
		return char(x + 87)
