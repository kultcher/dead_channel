class_name RebootModule extends ICModule

@export var reboot_time: float = 5.0

func get_desc():
	return "Reboot"

func on_disabled(active_sig: ActiveSignal):
	print("Rebooting signal in %s seconds" % reboot_time)
	CommandDispatch.get_tree().create_timer(reboot_time).timeout.connect(_reboot.bind(active_sig))
	
func _reboot(active_sig: ActiveSignal):
	active_sig.enable_signal()
