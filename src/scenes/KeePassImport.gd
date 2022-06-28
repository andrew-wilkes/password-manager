extends WindowDialog

signal update_groups
signal update_item_list

enum FIELD_ID {
	EndOfHeader = 0,
	Comment = 1,
	CipherID = 2,
	CompressionFlags = 3,
	MasterSeed = 4,
	TransformSeed = 5,
	TransformRounds = 6,
	EncryptionIV = 7,
	InnerRandomStreamKey = 8,
	StreamStartBytes = 9,
	InnerRandomStreamID = 10,
	KdfParameters = 11,
	PublicCustomData = 12
}

onready var password_field = $M/VB/HB2/Password
onready var msg = $M/VB/Message

var settings
var database
var data_bytes: PoolByteArray
var data_blocks: PoolByteArray
var xml
var header: Dictionary
var master_key
var data_idx
var data_size
var encoded_db
var cancel
var update_progress = false
var progress_value = 0

func _ready():
	if get_parent().name == "root":
		open(null, null, null, null)


func open(path, data, db, _settings):
	settings = _settings
	database = db
	data_bytes = data
	data_idx = 0
	data_size = data.size()
	msg.text = read_database_signature()
	$M/VB/Path.text = path
	$M/VB/Cancel.hide()
	$M/VB/ProgressBar.hide()
	call_deferred("set_panel_size")


func read_database_signature():
	var base_signature = get_string_bytes()
	if base_signature != PoolByteArray([0x9a, 0xa2, 0xd9, 0x03]):
		return "Unknown file type."
	var version_signature = get_string_bytes()
	if version_signature == PoolByteArray([0xb5, 0x4b, 0xfb, 0x65]):
		return "KeePass 1.x (.kdb file) not supported."
	if version_signature == PoolByteArray([0xb5, 0x4b, 0xfb, 0x66]):
		return "KeePass 2.x pre-release (.kdbx file).\n" + read_file_version()
	elif version_signature == PoolByteArray([0xb5, 0x4b, 0xfb, 0x67]):
		return "KeePass 2.x post-release (.kdbx file).\n" + read_file_version()
	else:
		return "Unknown KeePass version."


func read_file_version():
	var file_version = get_string_bytes()
	return "File version: %d%d.%d%d" % Array(file_version)


func get_header_fields_and_database():
	var scanning = true
	while scanning:
		if data_idx + 2 >= data_size:
			return
		var data_length = data_bytes[data_idx + 1] + data_bytes[data_idx + 2] * 256
		if data_idx + 2 + data_length >= data_size:
			return
		header[data_bytes[data_idx]] = data_bytes.subarray(data_idx + 3, data_idx + 2 + data_length)
		if data_bytes[data_idx] == FIELD_ID.EndOfHeader:
			scanning = false
		data_idx += 3 + data_length
	if data_idx < data_size:
		encoded_db = data_bytes.subarray(data_idx, -1)


func set_panel_size():
	rect_size = $M.rect_size
	popup_centered()
	var size = rect_size
	yield(get_tree(), "idle_frame")
	rect_size = $M.rect_size
	rect_position -= (rect_size - size) / 2
	password_field.grab_focus()


func _on_Start_pressed():
	$M/VB/ProgressBar.show()
	$M/VB/Cancel.show()
	cancel = false
	get_header_fields_and_database()
	var key = Passwords.hash_bytes(password_field.text.sha256_buffer())
	transform_key(key)


func transform_key(key):
	var rounds = header.get(FIELD_ID.TransformRounds)
	var tseed = header.get(FIELD_ID.TransformSeed)
	if tseed == null:
		msg.text += "\nMissing TransformSeed field."
		return
	if rounds == null:
		msg.text += "\nMissing TransformRounds field."
		return
	var encrypted = key
	rounds = bytes_to_int(rounds)
	msg.text = "Transform rounds: " + str(rounds)
	$M/VB/ProgressBar.max_value = rounds
	var update_interval = rounds / 100
	var update_counter = 0
	var start_time = OS.get_ticks_msec()
	var aes = AESContext.new()
	aes.start(AESContext.MODE_ECB_ENCRYPT, tseed)
	for n in rounds:
		update_counter -= 1
		if update_counter <= 0:
			update_counter = update_interval
			$M/VB/ProgressBar.value = n
			yield(get_tree(), "idle_frame")
			if cancel:
				return
		encrypted = aes.update(encrypted)
	aes.finish()
	key = Passwords.hash_bytes(encrypted)
	var master_seed = header.get(FIELD_ID.MasterSeed)
	if master_seed == null:
		msg.text += "\nMissing MasterSeed field."
		return
	key = Passwords.hash_bytes(master_seed + key)
	# Now we have the Master Key
	decode_data(key)


func _on_Cancel_pressed():
	$M/VB/Cancel.hide()
	msg.text = "Cancelled."
	cancel = true


func decode_data(key):
	var iv = header.get(FIELD_ID.EncryptionIV)
	if iv == null:
		msg.text += "\nMissing EncryptionIV field."
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var db: PoolByteArray = aes.update(encoded_db)
	aes.finish()
	var start_bytes = db.subarray(0, 31)
	var stream_start_bytes = header.get(FIELD_ID.StreamStartBytes)
	if stream_start_bytes == null:
		msg.text += "\nMissing StreamStartBytes field."
		return
	if stream_start_bytes != start_bytes:
		msg.text += "\nDecoded data mismatch."
		return
	# Remove start bytes and end padding
	data_blocks = db.subarray(32, -db[-1] - 1)
	var decrypted_blocks = PoolByteArray()
	var block = get_data_block(0)
	while block.data:
		if block.verified:
			decrypted_blocks.append_array(block.data)
		block = get_data_block(block.idx)
	xml = decrypted_blocks


func get_data_block(idx):
	var id = bytes_to_int(data_blocks.subarray(idx, idx + 3))
	var data_hash = data_blocks.subarray(idx + 4, idx + 35)
	var block_size = bytes_to_int(data_blocks.subarray(idx + 36, idx + 39))
	if block_size == 0:
		return { data = null }
	var compressed_data = data_blocks.subarray(idx + 40, idx + 39 + block_size)
	var hashed_data = Passwords.hash_bytes(compressed_data)
	# GZip file format: https://datatracker.ietf.org/doc/html/rfc1952
	# Starts with 31, 139
	var block_data = compressed_data.decompress_dynamic(-1, File.COMPRESSION_GZIP)
	var verified = true if data_hash == hashed_data else false
	return { id = id, data = block_data, verified = verified, idx = idx + block_size + 40 }


func decode_protected_elements():
	var alg_id = bytes_to_int(header.get(FIELD_ID.InnerRandomStreamID))
	if alg_id == 2: # Salsa20 algorithm
		var iv = PoolByteArray([0xE8, 0x30, 0x09, 0x4B, 0x97, 0x20, 0x5D, 0x2A])
		var _key = Passwords.hash_bytes(header.get(FIELD_ID.InnerRandomStreamKey))
		var salsa = Salsa20.new(_key, iv)
		var stream_pointer = 0
		var key_stream = salsa.generate_key_stream()
		var parser = XMLParser.new()
		var error = parser.open_buffer(xml)
		if error != OK:
			msg.text += "\nError opening XML data."
			return
		while true:
			if parser.read() != OK:
				return
			if parser.get_node_type() == parser.NODE_ELEMENT and parser.get_node_name() == "Value":
				if parser.get_named_attribute_value_safe("Protected") == "True":
					parser.read()
					var encoded_pass = parser.get_node_data()
					var decoded_pass = Marshalls.base64_to_raw(encoded_pass)
					for idx in decoded_pass.size():
						decoded_pass[idx] = decoded_pass[idx] ^ key_stream[stream_pointer]
						stream_pointer += 1
						if stream_pointer >= 64:
							key_stream = salsa.generate_key_stream()
							stream_pointer = 0
					print(decoded_pass.get_string_from_utf8())


func _on_Show_pressed():
	show_password(true)
	password_field.grab_focus()
	password_field.set_cursor_position(password_field.text.length())


func _on_Hide_pressed():
	show_password(false)


func show_password(reveal):
	password_field.secret = not reveal
	$M/VB/HB2/C1/Show.visible = not reveal
	$M/VB/HB2/C1/Hide.visible = reveal


func get_string_bytes():
	if data_idx + 3 < data_size:
		var bytes = data_bytes.subarray(data_idx, data_idx + 3)
		bytes.invert()
		data_idx += 4
		return bytes


func bytes_to_int(bytes: PoolByteArray):
	# LSB comes first so invert the order
	bytes.invert()
	var x = 0
	for idx in bytes.size():
		x *= 256
		x += bytes[idx]
	return x
