extends SceneTree

# Command line args are: password followed by optional user inputs that get added to the dictionary
func _init():
	var password = ""
	var user_inputs = []
	var args = OS.get_cmdline_args()
	if len(args) > 1:
		password = args[1]
	if len(args) > 2:
		for idx in range(2, len(args)):
			user_inputs.append(args[idx])
	var result = Zxcvbn.zxcvbn(password, user_inputs)

	print(JSON.print(result, "\t"))
