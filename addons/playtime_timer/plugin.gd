@tool
@icon("./icon.svg")
extends EditorPlugin

const PLUGIN_NAME := "PlaytimeTimer"
const PLUGIN_NAME_INTERNAL := "playtime_timer"
const PLUGIN_ICON:Texture2D = preload("./icon.svg")
const AUTOLOAD_NAME := "PlaytimeManager"
const AUTOLOAD_SCRIPT := "./playtime_manager.gd"

func _enter_tree():
	if EditorInterface.is_plugin_enabled(PLUGIN_NAME_INTERNAL):
		if not Engine.has_singleton(AUTOLOAD_NAME):
			add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _enable_plugin():
	if not Engine.has_singleton(AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)

func _get_plugin_name():
	return PLUGIN_NAME

func _get_plugin_icon():
	return PLUGIN_ICON

func _disable_plugin():
	if Engine.has_singleton(AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

func _exit_tree():
	if Engine.has_singleton(AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
