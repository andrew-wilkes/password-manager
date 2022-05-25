extends WindowDialog

const MARGIN = 10

export(String, MULTILINE) var dialogue_text = "" setget set_dialogue_text

func _on_ScrollableWindowDialog_resized():
	$VBox.rect_position = Vector2(MARGIN, MARGIN)
	$VBox.rect_size = rect_size - 2 * Vector2(MARGIN, MARGIN)


func _on_OK_pressed():
	hide()


func set_dialogue_text(txt):
	$VBox/SC/Dialog.text = txt.c_unescape()
