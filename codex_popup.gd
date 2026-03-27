extends PanelContainer

@onready var title_label = $CodexPopupVbox/CodexTopHbox/CodexHeaderPanel/CodexHeaderVbox/CodexTitle
@onready var type_label = $CodexPopupVbox/CodexTopHbox/CodexHeaderPanel/CodexHeaderVbox/CodexType
@onready var extra_label = $CodexPopupVbox/CodexTopHbox/CodexHeaderPanel/CodexHeaderVbox/CodexExtra
@onready var icon = $CodexPopupVbox/CodexTopHbox/CodexIconPanel/CodexIconContainer/CodexIcon
@onready var body = $CodexPopupVbox/CodexBodyPanel/CodexBodyMargin/CodexBody


func setup_and_display(codex_id: StringName):
	var entry = get_resource_from_stringname(codex_id)
	title_label.text = entry.title
	type_label.text = entry.category
	extra_label.text = entry.extra
	icon.texture = entry.icon
	body.text = entry.body_text
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
	var target: String = "res://Resources/Codex/" + StringName(codex_id) + ".tres"	
	var entry = load(target)
	return entry
