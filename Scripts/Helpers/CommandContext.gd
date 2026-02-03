class_name CommandContext extends Resource

enum CommandStatus {PROCESS, SUCCESS, FAILURE, INTERRUPT}

var command: String
var arg: String
var active_sig: ActiveSignal
var flags: Array = []
var log: Array = []
var status: CommandStatus = CommandStatus.PROCESS
