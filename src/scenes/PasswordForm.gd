extends CenterContainer

signal action(id, data)

enum { ENTER_PRESSED, PASSWORD_TEXT_CHANGED, BROWSE_PRESSED }

func _ready():
	set_text("")


func init(txt):
	set_text(txt)
	visible = true
	$VBox/HBox/Password.grab_focus()


func set_text(txt):
	$VBox/Label.text = txt

func _on_Enter_pressed():
	emit_signal("action", ENTER_PRESSED, $VBox/HBox/Password.text)


func _on_Hidden_pressed():
	$VBox/HBox/Hidden.hide()
	$VBox/HBox/Visible.show()
	$VBox/HBox/Password.secret = false


func _on_Visible_pressed():
	$VBox/HBox/Hidden.show()
	$VBox/HBox/Visible.hide()
	$VBox/HBox/Password.secret = true


func _on_Password_text_changed(new_text):
	emit_signal("action", PASSWORD_TEXT_CHANGED, new_text)


func _on_Browse_pressed():
	emit_signal("action", BROWSE_PRESSED, null)
