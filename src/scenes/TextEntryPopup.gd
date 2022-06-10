extends WindowDialog

signal ok_pressed(txt, adding)

export var margin_size = 20

var adding

func open(title, txt = "", _adding = true):
	adding = _adding
	window_title = title
	$HBox/LineEdit.text = ""
	if not txt.empty():
		$HBox/LineEdit.append_at_cursor(txt)
	popup_centered()
	call_deferred("set_panel_size")


func set_panel_size():
	var vec2 = Vector2(margin_size, margin_size)
	rect_size = $HBox.rect_size + vec2 * 2
	$HBox.rect_position = vec2
	$HBox/LineEdit.grab_focus()


func _on_OK_pressed():
	hide()
	emit_signal("ok_pressed", $HBox/LineEdit.text, adding)


func _on_LineEdit_text_entered(new_text):
	hide()
	emit_signal("ok_pressed", new_text, adding)
