extends HBoxContainer

signal action(id, data)

enum { HELLO }

func _ready():
	emit_signal("action", HELLO, null)
