@tool
@icon("res://addons/playtime_timer/icon.svg")
class_name PlaytimeTimer
extends Resource

## PlaytimeTimer
##
## A count up timer specifically built to run for long period of time in a single scene.[br][br]
## NOTE: this timer itself is ignorant of multi session timing durations,
## so if it is unloaded or freed while active,
## it will loose count of all time it was counting all the way back to the last time it was stopped.
## The starting and stopping of timers on application load, quit, pause, and resume is expected to
## be handled externally by a [PlaytimeManagerNode]

## Emitted when this timer is started. [ts] is the timestame in usec that the timer was started at.
signal started(ts:int)
## Emitted when this timer is stopped. [ts] is the timestame in usec that the timer was stopped at.
signal stopped(int)
## Emitted when this timer is paused. [ts] is the timestame in usec that the timer was paused at.
signal paused(int)
## Emitted when this timer is resumed. [ts] is the timestame in usec that the timer was resumed at.
signal resumed(int)

## Weather or not this timer is active. Will start or stop the timer
## when set to the appropriate [bool] value.
@export var is_active:bool:
	get:
		return _start_session_timestamp >= 0
	set(_value):
		if is_active == _value:
			return
		if _value:
			start_timer()
		else:
			stop_timer()
## Weather or not this timer is paused. Will pause or resume the timer
## when set to the appropriate [bool] value.
@export var is_paused:bool:
	get:
		return _pause_session_timestamp >= 0
	set(_value):
		if is_paused == _value:
			return
		if _value:
			pause_timer()
		else:
			resume_timer()
## The current time, and a [int] of passed microseconds, including both
## the current counted time and prexisting time.
## NOTE: When set, only the presisting time will be modified in order for the sum of
## both the the counted and preexisting time to match that of the set value.
@export var total_time_usec:int:
	get:
		return get_total_time_usec()
	set(_value):
		set_total_time_usec(_value)
## Same as [total_time_usec], but returning a float value of seconds instead.
## See [total_time_usec] for more information.
@export var total_time_sec:float:
	get:
		return total_time_usec * 0.000001
	set(_value):
		total_time_usec = _value * 1000000
## The saved amount of time, in usec.[br]
## NOTE This will not include the currented time counted in this timer is currently active,
## but will once the timer is stopped (without being aborted).
@export var preexisting_time:int = 0

var _start_session_timestamp:int = -1
var _pause_session_timestamp:int = -1

func _init(initial_time_usec:int = 0, auto_start := false):
	preexisting_time = initial_time_usec

	if auto_start:
		start_timer()

func _validate_property(property: Dictionary):
	if property.name == "_preexisting_time":
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _to_string() -> String:
	return str(total_time_sec) + " sec"

## Adds (or removes, if negative) [b][prexisting_time][/b] to the timer.
## This means that using this modifies only the 
func add_time_usec(value:int):
	preexisting_time += value
	emit_changed()

## Get the total time the timer has counted, including prexisting time and the current counted time,
## in usec.
func get_total_time_usec() -> int:
	var ts:int = Time.get_ticks_usec()
	var active_time_diff:int = 0
	if is_active:
		active_time_diff += max(ts - _start_session_timestamp, 0)
		if is_paused:
			active_time_diff -= max(ts - _pause_session_timestamp, 0)
	return preexisting_time + active_time_diff

## Changed the prexisting time to match the set value, in usec.
## NOTE When set, only the presisting time will be modified in order for the sum of
## both the the counted and preexisting time to match that of the set value.
func set_total_time_usec(value:int):
	var current_time:int = get_total_time_usec()
	add_time_usec(value - current_time)

## Starts the timer and resets the current counted progress of the timer
## (the time counted not including [preexisting_time])
func start_timer(ts :int= -1):
	assert(not is_active)
	if ts < 0:
		ts = Time.get_ticks_usec()
	_start_session_timestamp = ts
	if _pause_session_timestamp == 0:
		_pause_session_timestamp = ts
	started.emit(ts)
	emit_changed()

## Stops the current timer, and if not [abort]ing, will add the counted time since the timer
## was last started to the prexisting time, saving it.
## When [abort]ing, the counted time will be discarded instead.
func stop_timer(abort:bool = false, ts :int= -1):
	assert(is_active)
	if ts < 0:
		ts = Time.get_ticks_usec()
	if not abort:
		if is_paused:
			resume_timer(ts)
		preexisting_time += max(ts - _start_session_timestamp, 0)
		_start_session_timestamp = -1
	stopped.emit(ts)
	emit_changed()

## Pauses the timer. Pausing can be done even when the timer is not active.
func pause_timer(ts :int = -1):
	assert(not is_paused)
	if ts < 0:
		ts = Time.get_ticks_usec()
	_pause_session_timestamp = ts if is_active else 0
	paused.emit(ts)
	emit_changed()

## Resumes the timer. Resuming can be done even when the timer is not active.
func resume_timer(ts:int = -1):
	assert(is_paused)
	if ts < 0:
		ts = Time.get_ticks_usec()
	if is_active:
		preexisting_time -= max(ts - _pause_session_timestamp, 0)
	_pause_session_timestamp = -1
	resumed.emit(ts)
	emit_changed()
