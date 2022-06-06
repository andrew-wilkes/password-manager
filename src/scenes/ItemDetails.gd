extends WindowDialog

var button

func open(_item):
	popup_centered()
	call_deferred("set_panel_size")


func set_panel_size():
	rect_size = $M.rect_size


func _on_Show_pressed():
	pass # Replace with function body.


func _on_Hide_pressed():
	pass # Replace with function body.
