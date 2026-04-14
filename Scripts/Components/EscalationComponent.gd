class_name EscalationComponent extends Resource

@export var tier_index: int = 0
@export var heat_clear_on_disable: float = 750.0
@export var spawn_behavior: EscalationSpawnBehavior

var _is_active := false
var _has_started_once := false

func initialize(active_sig: ActiveSignal) -> void:
	if active_sig == null:
		return
	if active_sig.is_disabled:
		_is_active = false
		return
	start(active_sig)

func start(active_sig: ActiveSignal) -> void:
	if active_sig == null or _is_active:
		return
	_is_active = true
	_has_started_once = true
	if spawn_behavior != null and spawn_behavior.enabled:
		spawn_behavior.on_started(active_sig, self)

func stop(active_sig: ActiveSignal) -> void:
	if active_sig == null or not _is_active:
		return
	_is_active = false
	if spawn_behavior != null and spawn_behavior.enabled:
		spawn_behavior.on_stopped(active_sig, self)

func on_disabled(active_sig: ActiveSignal) -> void:
	stop(active_sig)
	if heat_clear_on_disable > 0.0:
		GlobalEvents.heat_increased.emit(-heat_clear_on_disable, "Escalation neutralized.")
	

func on_enabled(active_sig: ActiveSignal) -> void:
	start(active_sig)

func is_active() -> bool:
	return _is_active

func has_started_once() -> bool:
	return _has_started_once
