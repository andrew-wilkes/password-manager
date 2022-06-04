extends MarginContainer

signal clicked(this)

enum { NONE, UP, DOWN }

var db_key = ""

func set_sort_mode(mode):
	match mode:
		NONE:
			$HBox/ArrowUp.hide()
			$HBox/ArrowDown.hide()
		UP:
			$HBox/ArrowUp.show()
			$HBox/ArrowDown.hide()
		DOWN:
			$HBox/ArrowUp.hide()
			$HBox/ArrowDown.show()


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)
