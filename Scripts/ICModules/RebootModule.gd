class_name RebootModule extends ICModule

@export var reboot_time: float = 5.0

var timer: Timer

func get_desc():
	var desc: String = "Reboot(%ds)" % reboot_time
	return desc

func get_codex_id():
	return &"codex_reboot"

func postprocess_action(action_context: ActionContext) -> void:
	if action_context == null or not action_context.was_successful():
		return
	if action_context.action_type != ActionContext.ActionType.DISABLE_SIGNAL:
		return
	var active_sig := action_context.primary_target
	if active_sig == null:
		return

	if timer != null and is_instance_valid(timer):
		timer.queue_free()
	timer = Timer.new()
	timer.one_shot = true
	GlobalEvents.add_child(timer)
	timer.timeout.connect(_reboot.bind(active_sig), CONNECT_ONE_SHOT)
	timer.start(reboot_time)

func on_enabled(_active_sig: ActiveSignal):
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
	timer = null
	
func _reboot(active_sig: ActiveSignal):
	if timer != null and is_instance_valid(timer):
		timer.queue_free()
		timer = null
	if active_sig == null or not active_sig.is_disabled:
		return

	var action := ActionContext.create_system_action(
		ActionContext.ActionType.ENABLE_SIGNAL,
		active_sig,
		ActionContext.SourceType.IC_MODULE
	)
	action.add_tag(&"ic")
	action.add_tag(&"reboot")
	action.set_metadata(&"codex_id", get_codex_id())
	ActionResolver.enqueue_action(action)
