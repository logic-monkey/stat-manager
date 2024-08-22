extends Node
class_name Stats

enum {INT = 0, FLOAT = 1}
static var dic: Dictionary = {}

static  func _init() -> void:
	_load_stats()
	
static func _load_stats():
	if not FileAccess.file_exists("user://stats.stats"): return
	var file = FileAccess.open("user://stats.stats",FileAccess.READ)
		
@export var Name: String

func read(stat:String):
	if not stat in dic: return null
	if Name.is_empty() or not Name in dic[stat].variants: return dic[stat].default
	return dic[stat].variants[Name]
