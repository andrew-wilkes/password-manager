extends Button

signal group_button_pressed(id)

var id = 0

func _on_GroupButton_pressed():
	emit_signal("group_button_pressed", id)
