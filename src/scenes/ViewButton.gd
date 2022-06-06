extends MarginContainer

signal view_button_pressed(ob, index)

var idx = 0

func _on_Show_pressed():
	$Show.hide()
	$Hide.show()
	emit_signal("view_button_pressed", idx, true)


func _on_Hide_pressed():
	$Show.show()
	$Hide.hide()
	emit_signal("view_button_pressed", idx, false)


func reset():
	$Show.show()
	$Hide.hide()
