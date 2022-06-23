extends Control

const FILE_NAME_FILE = "../data/kdbx-file-path.txt"

func _ready():
	$Processing.hide()
	$FilePath.text = get_file_name()
	if $FilePath.text.empty():
		$FilePath.grab_focus()
		$PathNote.show()
	else:
		$Password.grab_focus()
		$PathNote.hide()


func run():
	var keepass = KPDX.new()
	keepass.set_password($Password.text)
	if keepass.load_file($FilePath.text):
		keepass.extract_header()
		keepass.get_header_fields_and_database()
		keepass.transform_key()
		keepass.set_composite_key()
		keepass.decode_data()
		keepass.decode_protected_elements()


func _on_Go_pressed():
	start()


func get_file_name():
	var file = File.new()
	if file.file_exists(FILE_NAME_FILE):
		file.open(FILE_NAME_FILE, File.READ)
		var content = file.get_as_text()
		file.close()
		return content
	else:
		return ""


func _on_Password_text_entered(_new_text):
	start()


func start():
	$Go.hide()
	$Processing.show()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	run()
	$Processing.hide()
	$Go.show()
