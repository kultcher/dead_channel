extends TextureProgressBar

@onready var heat_debug = $HeatDebug
@onready var timeline_manager = $"../SignalTimeline/TimelineManager"

var last_source: String = ""
var null_spike_count: float
var null_spike_scaler: float

func _ready():
	GlobalEvents.heat_increased.connect(modify_heat)

func modify_heat(amount:float, source: String):
	value += amount
	last_source = source
	
func _process(_delta: float):
	var display_string = "Heat:%.2f\n" % value
	var display_string2 = "Last Source:\n" + last_source

	# TODO: Give null speak heat gen it's own home
	heat_debug.text = display_string + display_string2
	if timeline_manager.null_spike_active:
		null_spike_count += _delta * 2
		if null_spike_count > 25.0:
			modify_heat(.25, "Null Spike t4")
		if null_spike_count > 20.0:
			modify_heat(.175, "Null Spike t3")
		if null_spike_count > 15.0:
			modify_heat(.125, "Null Spike t2")
		if null_spike_count > 10.0:
			modify_heat(.1, "Null Spike t1")
