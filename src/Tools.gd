extends Control

class KeePass:
	var base_signature: PoolByteArray
	var version_signature: PoolByteArray
	var file_version: PoolByteArray
	var header: Dictionary
	var data: PoolByteArray


func _ready():
	pass


func _on_GetKeePass_pressed():
	$FileDialog.popup_centered()


func _on_FileDialog_file_selected(path):
	var file = File.new()
	file.open(path, File.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	var keepass = KeePass.new()
	keepass.base_signature = get_subarray(data, 0, 3)
	keepass.version_signature = get_subarray(data, 4, 7)
	keepass.file_version = get_subarray(data, 8, 11)
	# Now get header fields
	var idx = 12
	while data[idx] > 0:
		var data_length = data[idx + 1] + data[idx + 2] * 16
		keepass.header[data[idx]] = data.subarray(idx + 3, idx + 2 + data_length)
		idx += 3 + data_length
	keepass.data = data.subarray(idx, data.size() - 1)
	prints("base_signature", keepass.base_signature.hex_encode())
	prints("version_signature", keepass.version_signature.hex_encode())
	prints("file_version", keepass.file_version.hex_encode())
	prints("Size:", data.size())


func get_subarray(data: PoolByteArray, start, end):
	var subarray = data.subarray(start, end)
	subarray.invert()
	return subarray
