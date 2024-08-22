@tool
extends EditorPlugin

const main_panel = preload("stat-manager-panel.tscn")
var main_panel_instance

func _enter_tree():
	main_panel_instance = main_panel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()

func _has_main_screen() -> bool: 
	return true

func _make_visible(visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = visible
	
func _get_plugin_name() -> String:
	return "Stats"
	
func _get_plugin_icon() -> Texture2D:
	var tex = preload("stat-manager-icon.svg")
	return tex
