extends Node

const COMPRESSED_LISTS = "res://zxcvbn/frequency_lists.gz"

var data  = {}

func _init():
	var file = File.new()
	if file.file_exists(COMPRESSED_LISTS):
		load_list(file)


func load_list(file):
	var _error = file.open(COMPRESSED_LISTS, File.READ)
	if _error == OK:
		var bytes = file.get_buffer(file.get_len())
		var decompressed = bytes.decompress_dynamic(-1, File.COMPRESSION_GZIP)
		var json = decompressed.get_string_from_utf8()
		var dict = JSON.parse(json).result
		for key in dict.keys():
			data[key] = dict[key].split(",")
	file.close()
