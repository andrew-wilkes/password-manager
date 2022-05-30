extends VBoxContainer

signal action(id, data)

func _ready():
	set_text("")


func set_text(txt):
	$Label.text = txt

func _on_Enter_pressed():
	emit_signal("action", "enter_pressed", $Label.text)


func _on_Hidden_pressed():
	$HBox/Hidden.hide()
	$HBox/Visible.show()
	$HBox/Password.secret = false


func _on_Visible_pressed():
	$HBox/Hidden.show()
	$HBox/Visible.hide()
	$HBox/Password.secret = true


func _on_Password_text_changed(new_text):
	emit_signal("action", "password_text_changed", new_text)


func _on_Browse_pressed():
	emit_signal("action", "browse_pressed", null)
