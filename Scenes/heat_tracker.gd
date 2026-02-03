extends TextureProgressBar

@onready var heat_debug = $HeatDebug

var last_source: String = ""

func _ready():
	GlobalEvents.heat_modified.connect(modify_heat)

func modify_heat(amount:float, source: String):
	value += amount
	last_source = source
	
func _process(delta: float):
	value += 1
	var display_string = "Heat:%.2f\n" % value
	var display_string2 = "Last Source:\n" + last_source
	heat_debug.text = display_string + display_string2
