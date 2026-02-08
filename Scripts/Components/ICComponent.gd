# ICComponent.gd
# Component for adding IC protection to Signals

class_name ICComponent extends Resource

@export var modules: Array[Resource] = [] # Array of ICModule resources

func get_desc():
	var formatted: String = ""
	var module_info = []
	for module in modules:
		module_info.append(module.get_desc())
	if module_info.size() == 0:
		return module_info[0]
	else:
		for info in module_info:
			if info == module_info[-1]:
				formatted += info
			else:
				formatted += info + " | "
	return formatted

func add_module(module: Resource):
	modules.append(module)

func command_intercept(cmd_context: CommandContext):
	var interrupt = false
	for module in modules:
		interrupt = module.interrupts_commands(cmd_context.command)
		return interrupt

func notify_enabled(active_sig: ActiveSignal):
	for module in modules:
		module.on_enabled(active_sig)

func notify_disabled(active_sig: ActiveSignal):
	for module in modules:
		module.on_disabled(active_sig)
