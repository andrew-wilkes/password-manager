extends VBoxContainer

signal enter_pressed
signal password_text_changed(txt)
signal browse_pressed

func set_filename(fname):
	$Filename.text = fname

func _on_Enter_pressed():
	emit_signal("enter_pressed")


func _on_Hidden_pressed():
	$HBox/Hidden.hide()
	$HBox/Visible.show()
	$HBox/Password.secret = false


func _on_Visible_pressed():
	$HBox/Hidden.show()
	$HBox/Visible.hide()
	$HBox/Password.secret = true


func _on_Password_text_changed(new_text):
	emit_signal("password_text_changed", new_text)


func _on_Browse_pressed():
	emit_signal("browse_pressed")
