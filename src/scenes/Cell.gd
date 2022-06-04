extends MarginContainer

signal clicked(this)

func set_text(txt):
	$Label.text = txt


func _on_Label_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)
