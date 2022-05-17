extends GutTest

func test_adjacency_graphs():
	assert_true(AdjacencyGraphs.data is Dictionary, "Should contain a dictionary")
	assert_true(AdjacencyGraphs.data.has('qwerty'), "Should have 'qwerty'")
	assert_true(AdjacencyGraphs.data.has('dvorak'), "Should have 'dvorak'")
	assert_true(AdjacencyGraphs.data.has('keypad'), "Should have 'keypad'")
	assert_true(AdjacencyGraphs.data.has('mac_keypad'), "Should have 'mac_keypad'")
