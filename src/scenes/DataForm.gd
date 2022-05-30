extends HBoxContainer

signal action(id, data)

func _ready():
	emit_signal("action", "hello", null)
