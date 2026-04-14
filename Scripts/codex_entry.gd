class_name CodexEntry extends Resource

enum CodexType { IC }

@export var codex_id: StringName
@export var title: String
@export var category: String
@export var extra: String
@export var icon: Texture2D
@export_multiline() var body_text: String
