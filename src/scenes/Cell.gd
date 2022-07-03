extends MarginContainer

signal clicked(this)

var item

func set_text(txt, rich_text, font_color):
	if rich_text and not txt.empty():
		$RichTextLabel.bbcode_text = '[url=%s]%s[/url]' % [txt, txt]
		$RichTextLabel.show()
		$Label.hide()
	else:
		$Label.text = txt
		$Label.set("custom_colors/font_color", font_color)


func _on_Label_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)


func _on_RichTextLabel_meta_clicked(url):
	var _e = OS.shell_open(url)
