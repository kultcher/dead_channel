# ResponseEffect.gd
# Wrapper for handling effects on a ResponseComponent

class_name ResponseEffect extends Resource

enum EffectType { HEAT, DAMAGE }
enum Cadence { ONESHOT, CONTINUOUS }

@export var cadence = Cadence.CONTINUOUS
@export var effect_type = EffectType.HEAT
@export var sends_alert: bool = false
@export var amount: float = 0.0


#func _init(cadence: Cadence, effect_type: EffectType, sends_alert: bool, amount: float):
#	self.cadence = cadence
#	self.effect_type = effect_type
#	self.sends_alert = sends_alert
#	self.amount = amount
