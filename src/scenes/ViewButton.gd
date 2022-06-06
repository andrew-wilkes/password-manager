extends CenterContainer

signal view_button_pressed()

func _on_Show_pressed():
	emit_signal("view_button_pressed")
