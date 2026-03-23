class_name RebootModule extends ICModule

@export var reboot_time: float = 5.0

var timer: Timer

func get_desc():
	var desc: String = "Reboot(%ds)" % reboot_time
	return desc

func _init():
	pass

func on_disabled(active_sig: ActiveSignal):
	print("Rebooting signal in %s seconds" % reboot_time)
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
	timer = Timer.new()
	GlobalEvents.add_child(timer)
	timer.timeout.connect(_reboot.bind(active_sig))
	timer.start(reboot_time)
	
func _reboot(active_sig: ActiveSignal):
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
		timer = null
	if active_sig != null and active_sig.is_disabled:
		active_sig.enable_signal()
