class_name ICProgressRadial extends TextureProgressBar

var active: bool = false
var show_when_idle: bool = false
var new_max: float = 0.0
var _countdown_timer: Timer = null

func _process(_delta: float) -> void:
	if not active:
		return
	if _countdown_timer == null or not is_instance_valid(_countdown_timer):
		stop()
		return
	value = clampf(_countdown_timer.time_left, 0.0, max_value)

func start(duration: float = -1.0, countdown_timer: Timer = null) -> void:
	if duration >= 0.0:
		new_max = duration
		max_value = duration
	_countdown_timer = countdown_timer
	reset()
	visible = true
	active = true

func stop() -> void:
	active = false
	_countdown_timer = null
	reset()
	visible = show_when_idle

func reset() -> void:
	value = new_max

func configure(_active_sig: ActiveSignal, progress: float) -> void:
	new_max = progress
	max_value = new_max
	reset()

func set_idle_visible(value: bool) -> void:
	show_when_idle = value
	if not active:
		visible = show_when_idle

func set_gradient(path: String):
	var grad = load(path)
	texture_progress = grad
