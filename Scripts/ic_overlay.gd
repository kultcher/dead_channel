class_name ICOverlay extends TextureRect

@export var shader: Shader = null

var active: bool = false
var _active_sig: ActiveSignal = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if shader != null:
		_apply_shader(shader)

func configure(active_sig: ActiveSignal, shader_resource: Shader = null) -> void:
	_active_sig = active_sig
	if shader_resource != null:
		shader = shader_resource
	if shader != null:
		_apply_shader(shader)

func set_active(value: bool) -> void:
	active = value

func _apply_shader(shader_resource: Shader) -> void:
	var material := ShaderMaterial.new()
	material.shader = shader_resource
	self.material = material
