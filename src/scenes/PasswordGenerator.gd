extends WindowDialog

const ADJECTIVES = "res://data/adjectives.gz"
const ANIMALS = "res://data/animal-words.gz"
const spacers = ["", "-", "@"]

export var color_a = "lime"
export var color_b = "aqua"

var words = { "adjectives": [], "animals": [] }
var colors = [color_a, color_b]
var suggestions = []
var adjective
var picks
var spacer_idx = 0

func _init():
	words["adjectives"] = Utility.load_gzip_data(ADJECTIVES, [])
	words["animals"] = Utility.load_gzip_data(ANIMALS, [])


func _ready():
	randomize()


func open():
	regenerate()
	popup_centered()


func regenerate():
	generate()
	var items = []
	for list in suggestions:
		for _words in list:
			items.append(_words)
	display_list(items)
	yield(get_tree(), "idle_frame")
	rect_size = $M.rect_size


func display_list(items):
	var idx = 0
	var num_hb_nodes = $M/VB/Items.get_child_count()
	if num_hb_nodes < items.size():
		for n in items.size() - $M/VB/Items.get_child_count():
			var hb = $M/VB/Items.get_child(0).duplicate()
			$M/VB/Items.add_child(hb)
			num_hb_nodes += 1
	for hb in $M/VB/Items.get_children():
		if idx >= num_hb_nodes:
			hb.queue_free()
		else:
			add_rich_text(hb.get_node("Text"), items[idx])
			if not hb.get_node("Copy").is_connected("pressed", self, "_on_Copy_pressed"):
				hb.get_node("Copy").connect("pressed", self, "_on_Copy_pressed", [idx])
		idx += 1


func add_rich_text(node: RichTextLabel, _words):
	var txt = PoolStringArray()
	var idx = 0
	for word in _words:
		if spacer_idx == 0:
			txt.append("[color=%s]%s[/color]" % [colors[idx], word])
			idx = wrapi(idx + 1, 0, 2)
		else:
			txt.append(word)
	node.bbcode_text = txt.join(spacers[spacer_idx])


func generate():
	adjective = pick_adjective()
	picks = pick_words(3)
	populate_list()


func populate_list():
	suggestions.clear()
	suggestions = [[], [], []]
	for i in 3:
		var s1 = [adjective]
		s1.append(picks[i])
		suggestions[0].append(s1)
		for j in 3:
			if i != j:
				var s2 = s1.duplicate()
				s2.append(picks[j])
				suggestions[1].append(s2)
				for k in 3:
					if k != i and k != j:
						var s3 = s2.duplicate()
						s3.append(picks[k])
						suggestions[2].append(s3)


func pick_adjective():
	return words["adjectives"][randi() % words["adjectives"].size()]


func pick_words(num_words):
	var _picks = []
	for idx in num_words:
		_picks.append(pick_word(idx))
	return _picks


func pick_word(idx):
	return words["animals"][idx][randi() % words["animals"][idx].size()]


func _on_Copy_pressed(idx):
	OS.set_clipboard($M/VB/Items.get_child(idx).get_node("Text").text)


func _on_Regenerate_pressed():
	regenerate()


func _on_Pad_pressed():
	spacer_idx = wrapi(spacer_idx + 1, 0, spacers.size())
	var items = []
	for list in suggestions:
		for _words in list:
			items.append(_words)
	display_list(items)
	yield(get_tree(), "idle_frame")
	rect_size = $M.rect_size
