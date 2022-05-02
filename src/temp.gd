extends Resource

class_name Temp

export(PoolByteArray) var data
export(PoolByteArray) var iv = PoolByteArray()

var settings: Settings

func _init(_settings):
	settings = _settings
