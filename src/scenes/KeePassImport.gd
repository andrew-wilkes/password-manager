extends WindowDialog

func open(csv, db):
	call_deferred("set_panel_size")


func set_panel_size():
	rect_size = $M.rect_size
	popup_centered()
	var size = rect_size
	yield(get_tree(), "idle_frame")
	rect_size = $M.rect_size
	rect_position -= (rect_size - size) / 2
