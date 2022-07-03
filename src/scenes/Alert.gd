extends Container

func show_message(txt):
	$Label.text = txt
	$Timer.start()


func _on_Timer_timeout():
	$Label.text = ""
