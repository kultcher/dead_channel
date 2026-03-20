extends PanelContainer

@onready var objective_list: RichTextLabel = $ObjectiveList

func _ready() -> void:
	visible = false
	objective_list.bbcode_enabled = true
	objective_list.fit_content = true
	objective_list.scroll_active = false

func set_objective(text: String) -> void:
	var clean_text := text.strip_edges()
	if clean_text == "":
		clear_objective()
		return

	visible = true
	objective_list.text = "[b]Objective:[/b]\n%s" % clean_text

func clear_objective() -> void:
	visible = false
	objective_list.text = ""
