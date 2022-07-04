extends Resource

class_name Settings

const FILE_NAME = "user://settings.tres"
const CHARS = "01234567890abcdefghijklmnopqrstuvwxyz"

export var current_file = "pw1.pwd"
export var last_dir = ""
export var date_format = "YYYY-MM-DD"
export var keys = []
export var key_idx = 0

var groups = {} # Saved with the database

func save_data():
	var _result = ResourceSaver.save(FILE_NAME, self)


func load_data():
	if ResourceLoader.exists(FILE_NAME):
		return ResourceLoader.load(FILE_NAME)
	else:
		last_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		keys.append(generate_salt())
		return self


func generate_salt(short = false):
	# In the UI it is called a Key
	# We will not store the salt value in the password db file, otherwise it defeats its purpose
	if short:
		# Using a-z0-9 characters so that a user may copy them easily to another device
		var _salt = PoolStringArray()
		for _n in 8 + randi() % 5: # 8 .. 12
			var x = randi() % CHARS.length()
			_salt.append(CHARS[x])
		return _salt.join("")
	else:
		var crypto = Crypto.new()
		return crypto.generate_random_bytes(23 + randi() % 9).hex_encode()


func add_group(group_name):
	if not group_name in groups.values():
		var max_id = groups.keys().max()
		var group_id = 1 if max_id == null else max_id + 1
		groups[group_id] = group_name


func get_group_id(group_name):
	var gid = 0
	for id in groups:
		if groups[id] == group_name:
			gid = id
			break
	return gid
