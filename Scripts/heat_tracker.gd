extends TextureProgressBar

@onready var heat_debug = $HeatDebug
@onready var heat_manager = $"../HeatManager"

var last_source: String = ""

func _ready():
	if heat_manager != null:
		max_value = heat_manager.max_heat
		value = heat_manager.get_heat()
		last_source = heat_manager.last_source
	GlobalEvents.heat_state_changed.connect(_on_heat_state_changed)


func set_heat(amount: float) -> void:
	value = amount

func _on_heat_state_changed(amount: float, source: String) -> void:
	set_heat(amount)
	last_source = source
	
func _process(_delta: float):
	var display_string = "Heat:%.2f\n" % value
	var display_string2 = "Last Source:\n" + last_source

	heat_debug.text = display_string + display_string2
