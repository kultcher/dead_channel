extends Node

var codex_seen: Dictionary = {}
var codex_popup_seen: Dictionary = { &"codex_reboot": true }
var tutorial_flags: Dictionary = {}

func _ready():
	GlobalEvents.signal_scan_complete.connect(_has_seen_codex_popup)

func _has_seen_codex_popup(signal_data: SignalData):
	var unseen_info: Array[StringName] = check_against_codex(signal_data)
	if unseen_info.size() == 0: return
	for codex_id in unseen_info:
		if not codex_popup_seen.get(codex_id, false):
			GlobalEvents.show_codex_popup.emit(codex_id, signal_data)
			codex_popup_seen[codex_id] = true

func check_against_codex(signal_data: SignalData) -> Array[StringName]:
	var codex_ids: Array[StringName] = []
	if signal_data.ic_modules.modules.size() > 0:
		for module in signal_data.ic_modules.modules:
			codex_ids.append(module.get_codex_id())
	return codex_ids
