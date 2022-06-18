extends TextureButton

class_name ModulatedTextureButton

var hover_color = Color(0, 0.384, 1)

func _ready():
	var _e = connect("mouse_entered", self, "_on_ModulatedTextureButton_mouse_entered")
	_e = connect("mouse_exited", self, "_on_ModulatedTextureButton_mouse_exited")


func _on_ModulatedTextureButton_mouse_entered():
	modulate = hover_color


func _on_ModulatedTextureButton_mouse_exited():
	modulate = Color.white
