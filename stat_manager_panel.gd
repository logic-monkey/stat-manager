@tool
extends VBoxContainer

@onready var tree : Tree = %Tree
var root : TreeItem

var last_variant = "new"
@onready var pluscon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
@onready var removeicon = preload("delete-icon.svg")

enum {STAT, VARIANT}

func _ready() -> void:
	var add_button = Button.new()
	add_button.flat = true
	add_button.icon = pluscon
	%top_menu.add_child(add_button)
	add_button.pressed.connect(add_stat)
	##TODO: Load the dic rather than clear it.
	tree.set_column_title(0, "Name")
	tree.set_column_title(1, "Value")
	tree.set_column_title(2, "Type")
	tree.set_column_expand(2, false)
	tree.set_column_custom_minimum_width(2, 200)
	if FileAccess.file_exists("res://stats.txt"): _load_stats()
	populate_tree()
	pass

func populate_tree():
	tree.clear()
	root = tree.create_item()
	var keys = Stats.dic.keys().duplicate()
	keys.sort()
	for stat in keys:
		var stat_item = tree.create_item(root)
		stat_item.set_text(0,stat)
		stat_item.set_metadata(0, stat)
		stat_item.set_metadata(1, STAT)
		stat_item.add_button(2,pluscon,0,false, "Add New Variant")
		stat_item.add_button(2,removeicon,1,false,"Delete Stat")
		stat_item.set_editable(0, true)
		stat_item.set_editable(1, true)
		stat_item.set_editable(2, true)
		stat_item.set_cell_mode(2,TreeItem.CELL_MODE_RANGE)
		#stat_item.set_range_config(2,0,1,1)
		stat_item.set_text(2,"Integer,Float")
		stat_item.set_range(2,0 if Stats.dic[stat].type == Stats.INT else 1)
		stat_item.set_text(1,"%s" % Stats.dic[stat].default)
		var keys2 = Stats.dic[stat].variants.keys().duplicate()
		keys2.sort()
		for variant in keys2:
			var stat_variant = tree.create_item(stat_item)
			stat_variant.set_text(0,variant)
			stat_variant.set_metadata(0, variant)
			stat_variant.set_metadata(1, VARIANT)
			stat_variant.set_metadata(2, stat)
			stat_variant.set_editable(0, true)
			stat_variant.set_editable(1, true)
			stat_variant.set_text(1, "%s" % Stats.dic[stat].variants[variant])
			stat_variant.add_button(2,removeicon,1,false,"Delete Variant")

	
func add_stat():
	var stat_name = "new_stat"
	var i = 2
	while stat_name in Stats.dic:
		stat_name = "new_stat_%s" % i
		i +=1
	Stats.dic[stat_name] = {"type": Stats.INT , "default": 0, "variants": {}}
	populate_tree()



func add_variant(stat) -> void:
	var item = Stats.dic[stat]
	var variant_name = "new_variant"
	var i = 2
	while variant_name in Stats.dic[stat].variants:
		variant_name = "new_variant_%s" % i
		i += 1
	Stats.dic[stat].variants[variant_name] = Stats.dic[stat].default
	populate_tree()


func _on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			add_variant(item.get_text(0))
		1:
			if item.get_metadata(1) == STAT:
				Stats.dic.erase(item.get_metadata(0))
				_save_stats()
				populate_tree()
			else:
				Stats.dic[item.get_metadata(2)].variants.erase(item.get_metadata(0))
				_save_stats()
				populate_tree()


func _on_tree_item_edited() -> void:
	var item = tree.get_edited()
	var column = tree.get_edited_column()
	if item.get_metadata(1) == STAT:
		match column:
			0:
				var new_name = item.get_text(0)
				if new_name in Stats.dic:
					if new_name == item.get_metadata(0):
						return
					print_rich("[bold][color=red]Two stats cannot have the same name.[/color][/bold]")
					item.set_text(0, item.get_metadata(0))
					return
				Stats.dic[new_name] = Stats.dic[item.get_metadata(0)]
				Stats.dic.erase(item.get_metadata(0))
				_save_stats()
				populate_tree()
				var cur_item = root.get_first_child()
				while cur_item:
					if cur_item.get_text(0)== new_name:
						cur_item.select(0)
						cur_item = null
						break
					cur_item = cur_item.get_next()
			1:
				match Stats.dic[item.get_text(0)].type:
					Stats.INT:
						if item.get_text(1).is_valid_int():
							Stats.dic[item.get_text(0)].default = item.get_text(1).to_int()
							_save_stats()
							populate_tree()
						else:
							item.set_text(1, "%s" % Stats.dic[item.get_text(0)].default)
					Stats.FLOAT:
						if item.get_text(1).is_valid_float():
							Stats.dic[item.get_text(0)].default = item.get_text(1).to_float()
							_save_stats()
							populate_tree()
						else:
							item.set_text(1, "%s" % Stats.dic[item.get_text(0)].default)
			2:
				var type = int(item.get_range(2))
				match type:
					0:
						Stats.dic[item.get_text(0)].default = int(Stats.dic[item.get_text(0)].default)
						Stats.dic[item.get_text(0)].type = Stats.INT
						for variant in Stats.dic[item.get_text(0)].variants:
							Stats.dic[item.get_text(0)].variants[variant] = int(Stats.dic[item.get_text(0)].variants[variant])
						_save_stats()
						populate_tree()
					1:
						Stats.dic[item.get_text(0)].default = float(Stats.dic[item.get_text(0)].default)
						Stats.dic[item.get_text(0)].type = Stats.FLOAT
						for variant in Stats.dic[item.get_text(0)].variants:
							Stats.dic[item.get_text(0)].variants[variant] = float(Stats.dic[item.get_text(0)].variants[variant])
						_save_stats()
						populate_tree()
	else:
		var stat = item.get_metadata(2)
		match column:
			0:
				var new_text = item.get_text(0)
				if new_text in Stats.dic[stat].variants:
					if new_text == item.get_metadata(0):
						return
					print_rich("[bold][color=red]Two variants cannot have the same name.[/color][/bold]")
					item.set_text(0, item.get_metadata(0))
					return
				Stats.dic[stat].variants[new_text] = Stats.dic[stat].variants[item.get_metadata(0)]
				Stats.dic[stat].variants.erase(item.get_metadata(0))
				_save_stats()
				populate_tree()
				var current_stat = root.get_first_child()
				while current_stat:
					if current_stat.get_text(0) == stat:
						var current_var = current_stat.get_first_child()
						while current_var:
							if current_var.get_text(0)== new_text:
								current_var.select(0)
								current_var = null
								break
							current_var = current_var.get_next()
						break
					current_stat = current_stat.get_next()
			1:
				match Stats.dic[stat].type:
					Stats.INT:
						if item.get_text(1).is_valid_int():
							Stats.dic[stat].variants[item.get_text(0)] = item.get_text(1).to_int()
							_save_stats()
							populate_tree()
						else:
							item.set_text(1,"%s" % Stats.dic[stat].variants[item.get_text(0)])
					Stats.FLOAT:
						if item.get_text(1).is_valid_float():
							Stats.dic[stat].variants[item.get_text(0)] = item.get_text(1).to_float()
							_save_stats()
							populate_tree()
						else:
							item.set_text(1,"%s" % Stats.dic[stat].variants[item.get_text(0)])

func _save_stats():
	var file = FileAccess.open("res://stats.stats",FileAccess.WRITE)
	file.store_string(var_to_str(Stats.dic))

func _load_stats():
	var file = FileAccess.open("res://stats.stats",FileAccess.READ)
	Stats.dic = str_to_var(file.get_as_text())



func _on_visibility_changed() -> void:
	if not FileAccess.file_exists("res://stats.stats"): return
	_load_stats()
	populate_tree()
