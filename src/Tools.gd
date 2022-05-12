extends Control

func _ready():
	print(bytes_to_int(PoolByteArray([1, 3])))
	print(hex_to_bytes("fff0"))
	var data = PoolByteArray([1, 3])
	print(data.compress(File.COMPRESSION_ZSTD))

func _on_GetKeePass_pressed():
	$FileDialog.popup_centered()


func _on_FileDialog_file_selected(path):
	var kpdx = KPDX.new()
	if kpdx.load_file(path):
		kpdx.extract_header()
		kpdx.set_password(find_node("Password").text)
		kpdx.get_header_fields_and_database()
		var result = kpdx.transform_key()
		if result != "OK":
			print(result)
			return
		result = kpdx.set_composite_key()
		if result != "OK":
			print(result)
		result = kpdx.decode_data()
		if result != "OK":
			print(result)


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
