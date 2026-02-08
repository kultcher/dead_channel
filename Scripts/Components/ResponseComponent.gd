# ResponseComponent.gd

class_name ResponseComponent extends Resource

@export var effects: Array[Resource] = []

enum Effect { HEAT, DAMAGE }
enum Cadence { ONESHOT, CONTINUOUS }

func on_detection(active_sig: ActiveSignal, delta: float) -> void:
	for effect in effects:
		match effect.cadence:
			ResponseEffect.Cadence.CONTINUOUS:
				_apply_effect(effect, effect.amount * delta, active_sig)
			ResponseEffect.Cadence.ONESHOT:
				_apply_effect(effect, effect.amount, active_sig)
				active_sig.disable_signal()

func _apply_effect(effect: ResponseEffect, value: float, _active_sig: ActiveSignal) -> void:
	match effect.effect_type:
		ResponseEffect.EffectType.HEAT:
			GlobalEvents.heat_increased.emit(value, "Detected by " + _active_sig.data.display_name + ".")
		ResponseEffect.EffectType.DAMAGE:
			GlobalEvents.runner_damaged.emit(value)

func get_desc():
	return "Blank"
