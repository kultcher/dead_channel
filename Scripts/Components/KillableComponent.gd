# KillableComponent.gd
# Governs how Signals are disabled

class_name KillableComponent extends Resource

func try_kill(cmd_context):
	cmd_context.active_sig.disable_signal()
	var name = cmd_context.active_sig.data.system_id
	cmd_context.log.append("Shutting down " + name + "...")
