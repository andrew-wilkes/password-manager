extends VBoxContainer

signal action(id, data)
signal heading_clicked(heading)

enum { HELLO }

var heading_scene = preload("res://scenes/Heading.tscn")

var headings = {
	"title": "Title",
	"username": "Username",
	"url": "URL",
	"notes": "Notes",
	"modified": "Modified",
}

func _ready():
	for key in headings:
		var heading = heading_scene.instance()
		heading.set_sort_mode(heading.NONE)
		heading.find_node("Label").text = headings[key]
		heading.db_key = key
		heading.connect("clicked", self, "heading_clicked")
		$SC/Grid.add_child(heading)
	emit_signal("action", HELLO, null)


func init(_data):
	visible = true


func heading_clicked(heading):
	print(heading.db_key)
	emit_signal("heading_clicked", heading)
