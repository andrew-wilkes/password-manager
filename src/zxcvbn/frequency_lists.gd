extends Node

const COMPRESSED_LISTS = "res://zxcvbn/frequency_lists.gz"

var data  = {}

func _init():
	var dictionary = Utility.load_gzip_data(COMPRESSED_LISTS, {})
	for key in dictionary:
		data[key] = dictionary[key].split(",")
