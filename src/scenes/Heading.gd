extends MarginContainer

class_name Heading

signal clicked(this)

enum { UP, DOWN, NONE }

var db_key = ""
var sort_mode = NONE

func _ready():
	# Get a stable column size.
	# Without this, the column width changes as the Arrows are shown and hidden
	# when the heading is wider than the data.
	# Could not find another working solution.
	rect_min_size.x = rect_size.x


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
