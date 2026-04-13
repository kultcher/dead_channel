extends PanelContainer

const CODEX_ENTRIES := {
	&"codex_bouncer": preload("res://Resources/Codex/codex_bouncer.tres"),
	&"codex_faraday": preload("res://Resources/Codex/codex_faraday.tres"),
	&"codex_reboot": preload("res://Resources/Codex/codex_reboot.tres"),
	&"codex_cipher_substitution": preload("res://Resources/Codex/codex_cipher_substitution.tres"),
}

@onready var title_label = $CodexPopupVbox/CodexTopHbox/CodexHeaderPanel/CodexHeaderVbox/CodexTitle
@onready var type_label = $CodexPopupVbox/CodexTopHbox/CodexHeaderPanel/CodexHeaderVbox/CodexType
@onready var extra_label = $CodexPopupVbox/CodexTopHbox/CodexHeaderPanel/CodexHeaderVbox/CodexExtra
@onready var icon = $CodexPopupVbox/CodexTopHbox/CodexIconPanel/CodexIconContainer/CodexIcon
@onready var body = $CodexPopupVbox/CodexBodyPanel/CodexBodyMargin/CodexBody


func setup_and_display(codex_id: StringName):
	process_mode = Node.PROCESS_MODE_ALWAYS
	var entry = get_resource_from_stringname(codex_id)
	if entry == null:
		queue_free()
		return
	title_label.text = entry.title
	type_label.text = entry.category
	extra_label.text = entry.extra
	icon.texture = entry.icon
	body.text = entry.body_text
	self.show()
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_close_popup()

func _on_button_pressed() -> void:
	_close_popup()

func _close_popup():
	get_tree().paused = false
	queue_free()

func get_resource_from_stringname(codex_id: StringName) -> Resource:
	if CODEX_ENTRIES.has(codex_id):
		return CODEX_ENTRIES[codex_id]
	var target := "res://Resources/Codex/%s.tres" % String(codex_id)
	if ResourceLoader.exists(target):
		return load(target)
	push_warning("Codex entry not found: %s" % String(codex_id))
	return null
