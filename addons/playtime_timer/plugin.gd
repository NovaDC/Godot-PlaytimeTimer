@tool
@icon("./icon.svg")
extends EditorPlugin

const PLUGIN_NAME := "PlaytimeTimer"

const PLUGIN_NAME_INTERNAL := "playtime_timer"

const PLUGIN_ICON:Texture2D = preload("./icon.svg")

const AUTOLOAD_NAME:StringName = "PlaytimeManager"

const AUTOLOAD_SCRIPT := "./playtime_manager.gd"

const ENSURE_SCRIPT_DOCS:Array[Script] = [
	preload("./playtime_timer.gd"),
	preload("./playtime_manager.gd"),
]

# Every once ands a while the script docs simply refuse to update properly.
# This nudges the docs into a ensuring that the important scripts added by
# this addon are actually loaded.
func _ensure_script_docs() -> void:
	var edit := get_editor_interface().get_script_editor()
	for scr in ENSURE_SCRIPT_DOCS:
		edit.update_docs_from_script(scr)

func _enter_tree() -> void:
	_ensure_script_docs()
	if EditorInterface.is_plugin_enabled(PLUGIN_NAME_INTERNAL):
		if not Engine.has_singleton(AUTOLOAD_NAME):
			add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _enable_plugin() -> void:
	_ensure_script_docs()
	if not Engine.has_singleton(AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return PLUGIN_ICON

func _disable_plugin() -> void:
	if Engine.has_singleton(AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

func _exit_tree() -> void:
	if Engine.has_singleton(AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
