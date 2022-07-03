extends CenterContainer

signal view_button_pressed()

var item

func _on_Show_pressed():
	emit_signal("view_button_pressed")
