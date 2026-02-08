# ICComponent.gd
# Component for adding IC protection to Signals

class_name ICComponent extends Resource

@export var modules: Array[Resource] = [] # Array of ICModule resources

func get_desc():
	return "Blank"

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
