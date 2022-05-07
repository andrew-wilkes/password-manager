extends Control

class KeePass:
	var base_signature: PoolByteArray
	var version_signature: PoolByteArray
	var file_version: PoolByteArray
	var header: Dictionary
	var data: PoolByteArray


func _ready():
	print(bytes_to_int(PoolByteArray([1, 3])))
	print(hex_to_bytes("fff0"))


func _on_GetKeePass_pressed():
	$FileDialog.popup_centered()


func _on_FileDialog_file_selected(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	var keepass = KeePass.new()
	# The following values are stored as LE (LSB byte first)
	keepass.base_signature = get_subarray(data, 0, 3)
	keepass.version_signature = get_subarray(data, 4, 7)
	keepass.file_version = get_subarray(data, 8, 11)
	# Now get header fields
	var idx = 12
	var scanning = true
	while scanning:
		var data_length = data[idx + 1] + data[idx + 2] * 16
		keepass.header[data[idx]] = get_subarray(data, idx + 3, idx + 2 + data_length)
		if data[idx] == 0:
			scanning = false
		idx += 3 + data_length
	keepass.data = data.subarray(idx, data.size() - 1)
	prints("base_signature", keepass.base_signature.hex_encode())
	prints("version_signature", keepass.version_signature.hex_encode())
	prints("file_version", keepass.file_version.hex_encode())
	prints("Size:", data.size())
	var composite_key = find_node("Password").text.sha256_text()
	composite_key = composite_key.sha256_text()
	var transform_seed = keepass.header[5] # Is byte order correct?
	transform_seed.invert()
	var encrypted = hex_to_bytes(composite_key)
	#encrypted.invert()
	var transform_rounds = bytes_to_int(keepass.header[6])
	var aes = AESContext.new()
	aes.start(AESContext.MODE_ECB_ENCRYPT, transform_seed)
	for _n in transform_rounds:
		encrypted = aes.update(encrypted)
	aes.finish()
	var _hash = encrypted.hex_encode().sha256_text()
	# Is the byte order correct for the master_seed?
	var master_seed = keepass.header[4]
	#master_seed.invert()
	var master_key = hex_to_bytes((master_seed.hex_encode() + _hash).sha256_text())
	# Decrypt the data
	var iv = keepass.header[7] # Is byte order correct?
	#iv.invert()
	aes.start(AESContext.MODE_CBC_DECRYPT, master_key, iv)
	var db = aes.update(keepass.data)
	aes.finish()
	var stream_start_bytes = keepass.header[9] # Is byte order correct?
	stream_start_bytes.invert()
	print(stream_start_bytes)
	print(db.subarray(0, 31))


func bytes_to_int(bytes: PoolByteArray):
	var x = 0
	for idx in bytes.size():
		x *= 256
		x += bytes[idx]
	return x


func hex_to_bytes(hex_string):
	var bytes = PoolByteArray()
	for idx in range(0, hex_string.length(), 2):
		bytes.append(("0x" + hex_string.substr(idx, 2)).hex_to_int())
	return bytes


func get_subarray(data: PoolByteArray, start, end):
	var subarray = data.subarray(start, end)
	subarray.invert()
	return subarray
