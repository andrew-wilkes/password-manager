class_name Utility

static func increment_filename(fname):
	var parts = fname.split(".")
	var regex = RegEx.new()
	regex.compile("\\d+$")
	var result = regex.search(parts[0])
	if result:
		var n = result.get_string()
		parts[0] = parts[0].rstrip(n) + str(int(n) + 1)
	else:
		parts[0] += "1"
	return parts.join(".")


static func load_gzip_data(path, object):
	var data
	var file = File.new()
	if file.file_exists(path):
		var error = file.open(path, File.READ)
		if error == OK:
			var bytes = file.get_buffer(file.get_len())
			var decompressed = bytes.decompress_dynamic(-1, File.COMPRESSION_GZIP)
			var json = decompressed.get_string_from_utf8()
			data = JSON.parse(json).result
		file.close()
	if typeof(data) == typeof(object):
		return data
	else:
		return object


static func is_valid_base64_str(txt):
	var regex = RegEx.new()
	regex.compile("^([-/\\+=A-Za-z0-9]{4})+$")
	var result = regex.search(txt)
	if result:
		return true
	else:
		return false
