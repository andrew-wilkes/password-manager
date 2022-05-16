extends Control

func _ready():
	var adj = AdjacencyGraphs.data
	print(adj.keys())
	assert(adj["qwerty"].size() > 0)
	
