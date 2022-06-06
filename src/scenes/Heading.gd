extends MarginContainer

class_name Heading

signal clicked(this)

enum { UP, DOWN, NONE }

var db_key = ""
var sort_mode = NONE

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
		sort_mode = (sort_mode + 1) % 2
		set_sort_mode(sort_mode)
		emit_signal("clicked", self)
