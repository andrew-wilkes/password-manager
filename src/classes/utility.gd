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
