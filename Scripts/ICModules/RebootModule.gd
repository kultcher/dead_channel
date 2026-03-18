class_name RebootModule extends ICModule

@export var reboot_time: float = 5.0

var timer: Timer

func get_desc():
	var desc: String = "Reboot(%ds)" % reboot_time
	return desc

func _init():
	GlobalEvents.tactical_pause.connect(_on_pause)
	GlobalEvents.tactical_unpause.connect(_on_unpause)

func on_disabled(active_sig: ActiveSignal):
	print("Rebooting signal in %s seconds" % reboot_time)
	timer = Timer.new()
	GlobalEvents.add_child(timer)
	timer.timeout.connect(_reboot.bind(active_sig))
	timer.start(reboot_time)
	
func _reboot(active_sig: ActiveSignal):
	active_sig.enable_signal()
	timer.queue_free()
	
func _on_pause():
	if timer:
		timer.set_paused(true)
	
func _on_unpause():
	if timer:
		timer.set_paused(false)
