# EffectAreaComponent.gd
# Signal component for projecting areas of effect

class_name EffectAreaComponent extends Resource

enum Shape { RECTANGLE, CONE, CIRCLE }
enum EffectType { HEAT_TICK, DAMAGE, ALERT }

@export var shape: Shape = Shape.RECTANGLE
@export var size: Vector2 = Vector2(1, 1) # Size in CELLS, not pixels!
@export var effect_type: EffectType = EffectType.HEAT_TICK
@export var heat_per_second: float = 0.0
@export var damage_per_second: float = 0.0

func get_desc():
	return "blank"
