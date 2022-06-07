extends MarginContainer

signal clicked(this)

export(int) var char_width = 12

func set_text(txt, rich_text):
	if rich_text:
		$RichTextLabel.bbcode_text = '[url=%s]%s[/url]' % [txt, txt]
		$RichTextLabel.rect_min_size.x = txt.length() * char_width
		$RichTextLabel.show()
		$Label.hide()
	else:
		$Label.text = txt


func _on_Label_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("clicked", self)


func _on_RichTextLabel_meta_clicked(url):
	var _e = OS.shell_open(url)
