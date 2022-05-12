extends Node

class_name KPDX

enum FIELD_ID {
	EndOfHeader = 0,
	Comment = 1,
	CipherID = 2,
	CompressionFlags = 3,
	MasterSeed = 4,
	TransformSeed = 5, # for backward compatibility
	TransformRounds = 6, # for backward compatibility
	EncryptionIV = 7,
	InnerRandomStreamKey = 8, # for backward compatibility
	StreamStartBytes = 9, # for backward compatibility
	InnerRandomStreamID = 10,
	KdfParameters = 11,
	PublicCustomData = 12
}

var base_signature: PoolByteArray
var version_signature: PoolByteArray
var file_version: PoolByteArray
var header: Dictionary
var data: PoolByteArray
var encoded_db
var key
var composite_key
var database


func set_password(pwd: String):
	# KeePass hashes keys, concatenates them, and then hashes the combined keys
	# We only have a password, no keyfile etc.
	key = hash_bytes(pwd.sha256_buffer())
	prints("key", key)


func set_composite_key():
	var master_seed = header.get(FIELD_ID.MasterSeed)
	if master_seed == null:
		return "Missing MasterSeed field"
	key = hash_bytes(master_seed + key)
	prints("composite_key:", key)
	return "OK"


func transform_key():
	var rounds = header.get(FIELD_ID.TransformRounds)
	var tseed = header.get(FIELD_ID.TransformSeed)
	if tseed == null:
		return "Missing TransformSeed field"
	if rounds == null:
		return "Missing TransformRounds field"
	var encrypted = key
	rounds.invert()
	rounds = bytes_to_int(rounds)
	var aes = AESContext.new()
	aes.start(AESContext.MODE_ECB_ENCRYPT, tseed)
	for _n in rounds:
		encrypted = aes.update(encrypted)
	aes.finish()
	key = hash_bytes(encrypted)
	return "OK"


func extract_header():
	extract_hex_string("base_signature", 0, 3)
	extract_hex_string("version_signature", 4, 7)
	extract_hex_string("file_version", 8, 11)


func decode_data():
	var iv = header.get(FIELD_ID.EncryptionIV)
	if iv == null:
		return "Missing EncryptionIV field"
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var db: PoolByteArray = aes.update(encoded_db)
	aes.finish()
	var start_bytes = db.subarray(0, 31)
	var stream_start_bytes = header.get(FIELD_ID.StreamStartBytes)
	if stream_start_bytes == null:
		return "Missing StreamStartBytes field"
	if stream_start_bytes != start_bytes:
		return "Decoded data mismatch\nStreamStartBytes: " + String(stream_start_bytes) \
		 + "\nStart bytes: " + String(start_bytes)
	prints("End bytes:", db.subarray(-16, -1))
	# Remove end padding and start bytes
	var compressed_data = db.subarray(32, -db[-1] - 1)
	# Try to decompress the data using GZip
	# GZip file format: https://datatracker.ietf.org/doc/html/rfc1952
	# Header should start with 31, 139
	database = compressed_data.decompress_dynamic(-1, File.COMPRESSION_GZIP)
	if database.size() == 0:
		return "Failed to decompress data"
	return "OK"


func get_header_fields_and_database():
	var idx = 12
	var scanning = true
	while scanning:
		var data_length = data[idx + 1] + data[idx + 2] * 16
		header[data[idx]] = data.subarray(idx + 3, idx + 2 + data_length)
		if data[idx] == FIELD_ID.EndOfHeader:
			scanning = false
		idx += 3 + data_length
	encoded_db = data.subarray(idx, -1)
	print("Header length = ", idx)
	print("Encoded database size = ", encoded_db.size())


func extract_hex_string(tname, start_index, end_index):
	var target = get(tname)
	target = data.subarray(start_index, end_index)
	target.invert()
	set(tname, target)
	prints(tname, target.hex_encode())


func load_file(path):
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		data = file.get_buffer(file.get_len())
	file.close()
	return data != null and data.size() > 0


func bytes_to_int(bytes: PoolByteArray):
	var x = 0
	for idx in bytes.size():
		x *= 256
		x += bytes[idx]
	return x


func hash_bytes(b: PoolByteArray):
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(b)
	# Get the computed hash.
	return ctx.finish()
