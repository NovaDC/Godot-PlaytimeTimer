@tool
@icon("res://addons/playtime_timer/icon.svg")
class_name PlaytimeManagerNode
extends Node

## PlaytimeManagerNode
##
## A node and optionally an autoload singleton class that, when in the scene tree,
## allows for [PlaytimeTimer]s to be easily managed, created, removed, saved, and loaded;
## without having to track them in a seprate node.
## When used as a singleton, it will be under the name [PlaytimeManager].
## The PlaytimeTimer plugin must be anabled for the singleton to be used,
## however both [PlaytimeManagerNode] and [PlaytimeTimer] can be used without having to be enabled.

## String values that when returned by [OS.get_name],
## will ensure that [NOTIFICATION_WM_GO_BACK_REQUEST]
## is treated the same as [NOTIFICATION_WM_CLOSE_REQUEST]
const BACK_IS_CLOSE_OS_NAMES:Array[String] = ["Android"]

## A mapping of [String] timer names to their respective [PlaytimeTImers].
## Not particularly usefull when used as a singleton,
## but handy when adding this node to the tree manually.
@export var timers := {}
## A collection of potential timer name [String]s that,
## if the timer exists, will be automatically started when the scene starts.
## Not particularly usefull when used as a singleton,
## but handy when adding this node to the tree manually.
@export var autostart_timers:Array[String] = []
## Returns a dict mapping timer names to [float]s of their current counted time.
@export var times:Dictionary:
	get:
		return get_times()
	set(_value):
		set_times(_value)

func _notification(what:int):
	match(what):
		NOTIFICATION_WM_CLOSE_REQUEST, \
		NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_PREDELETE, \
		NOTIFICATION_EXIT_TREE, \
		NOTIFICATION_CRASH, \
		NOTIFICATION_DISABLED:
			stop_all()
		NOTIFICATION_WM_GO_BACK_REQUEST \
		when get_tree().quit_on_go_back and OS.get_name() in BACK_IS_CLOSE_OS_NAMES:
			stop_all()
		NOTIFICATION_ENTER_TREE, \
		NOTIFICATION_READY, \
		NOTIFICATION_APPLICATION_RESUMED, \
		NOTIFICATION_ENABLED:
			for timer_name in autostart_timers:
				if not timers.has(timer_name):
					timers[timer_name].start_timer(0)
		NOTIFICATION_PAUSED:
			pause_all()
		NOTIFICATION_UNPAUSED:
			resume_all()

func _to_string() -> String:
	return get_json_times()

## Adds a playtime timer to this [PlaytimeManagerNode] with the given [timer_name].
## If a timer with the same name already exists, it is replaced by this new one.
## Returns the newly created [PlaytimeTimer].
func add_timer(timer_name:String,
			   start := true,
			   pause := false,
			   initial_time_sec:float = 0
			  ) -> PlaytimeTimer:
	timers[timer_name] = PlaytimeTimer.new(initial_time_sec)
	timers[timer_name].is_active = start
	timers[timer_name].is_paused = pause
	return timers[timer_name]

## Checks if a certian timer exists in this [PlaytimeManagerNode].
func has_timer(timer_name:String) -> bool:
	return timer_name in timers.keys()

## Trys to add a playtime timer to this [PlaytimeManagerNode] with the given [timer_name]
## only if the timer with that [timer_name] does not exist.
## Returns the [PlaytimeTimer] with the given name, weather its created or already existing.
func try_add_timer(timer_name:String,
				   start := true,
				   pause := false,
				   initial_time_sec:float = 0
				  ) -> PlaytimeTimer:
	if not has_timer(timer_name):
		add_timer(timer_name, start, pause, initial_time_sec)
	return timers[timer_name]

## Removes the timer with the given [timer_name] in this [PlaytimeManagerNode].
func remove_timer(timer_name:String):
	timers.erase(timer_name)

## Starts any stopped timers.
func start_all():
	for timer in timers.values():
		timer.is_active = true

## Stops any started timers.
## If [abort], the working values in the timers will [b]not[/b] be saved to the timers state,
## loosing any the time counted form when the timer was last started.
func stop_all(abort := false):
	for timer in timers.values():
		if timer.is_active:
			timer.stop_timer(false)

## Pauses any unpaused timers.[br]
## NOTE: the timer does not need to be started for it to be paused.
func pause_all():
	for timer in timers.values():
		timer.is_paused = true

## Resumes any paused timers.[br]
## NOTE: the timer does not need to be started for it to be resumed.
func resume_all():
	for timer in timers.values():
		timer.is_paused = false

## Returns a dict mapping timer names to their current counted time.
func get_times() -> Dictionary:
	var ret:Dictionary = {}
	for timer_name in timers.keys():
		ret[timer_name] = timers[timer_name]
	return ret

## Uses a dict mapping timer names to their current counted time to
## set all timers in this [PlaytimeManagerNode].
func set_times(data:Dictionary, start_new := false, pause_new := false):
	for old_key in timers.keys():
		if old_key not in data.keys():
			timers.erase(old_key)
	
	for new_key in data.keys():
		if new_key in timers.keys():
			timers[new_key].set_total_time_usec(data[new_key])
		else:
			add_timer(new_key, start_new, pause_new, data[new_key])

## Get a mapping of timer names to their counted times as a json string.
func get_json_times() -> String:
	return JSON.stringify(get_times)

## Sets the current timers in this [PlaytimeManagerNode] form the given json string.
func set_json_times(data:String):
	var json := JSON.new()
	assert(json.parse(data) == OK)
	set_times(json.get_data())

## Saves a json dict mapping of timer names to their current counted values as a json text file.
func save_times(path:String):
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(get_json_times())

## Loads a json dict mapping of timer names to their current counted values from the path.
func load_times(path:String):
	assert(FileAccess.file_exists(path))
	var f = FileAccess.open(path, FileAccess.READ)
	set_json_times(f.get_as_text())
