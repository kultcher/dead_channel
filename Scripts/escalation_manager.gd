extends Node

const PANEL_BG := Color(0.05, 0.02, 0.02, 0.92)
const PANEL_BORDER := Color(0.85, 0.2, 0.18, 1.0)
const PIP_READY := Color(0.28, 0.12, 0.12, 1.0)
const PIP_TRIGGERED := Color(0.78, 0.24, 0.18, 1.0)
const PIP_ACTIVE := Color(1.0, 0.72, 0.5, 1.0)
const BAR_IDLE := Color(0.24, 0.08, 0.08, 1.0)
const BAR_ACTIVE := Color(0.95, 0.26, 0.18, 1.0)

@export var escalation_thresholds: Array[float] = [0.25, 0.5, 0.75, 1.0]
@export var tier_labels: Array[String] = ["TRACE", "PURSUIT", "LOCKDOWN", "HUNTER"]
@export var panel_margin := Vector2(24.0, 24.0)
@export var panel_min_size := Vector2(300.0, 168.0)

@onready var heat_manager = $"../HeatManager"
@onready var timeline_manager = $"../SignalTimeline/TimelineManager"
@onready var escalation_panel: PanelContainer = $"../SignalTimeline/EscalationPanel"
@onready var escalation_container: CenterContainer = $"../SignalTimeline/EscalationPanel/EscalationContainer"
@onready var scan_controller = $"../SignalTimeline/ScanController"
@onready var terminal_window = $"../WorkspaceAnchor/TerminalWindow"

var _signal_scene := preload("res://Scenes/signal_entity.tscn")
var _spawner := SignalSpawner.new()

var _triggered_tiers: Array[bool] = []
var _active_tier_index := -1

var _panel_margin_box: MarginContainer
var _panel_vbox: VBoxContainer
var _alert_bar: ColorRect
var _pip_row: HBoxContainer
var _tier_pips: Array[ColorRect] = []
var _signal_row: HBoxContainer
var _signal_hosts: Dictionary = {}
var _active_escalation_signals: Dictionary = {}

func _ready() -> void:
	if process_mode == Node.PROCESS_MODE_DISABLED: return
	_initialize_tier_state()
	_build_panel()
	if escalation_panel != null:
		panel_margin = escalation_panel.position
	if GlobalEvents.heat_state_changed != null:
		GlobalEvents.heat_state_changed.connect(_on_heat_state_changed)
	if timeline_manager != null and timeline_manager.layout_changed != null:
		timeline_manager.layout_changed.connect(_on_timeline_layout_changed)
	_refresh_panel_layout()
	_refresh_panel(heat_manager.get_heat_ratio() if heat_manager != null else 0.0)

func get_active_tier_index() -> int:
	return _active_tier_index

func get_signal_by_system_id(system_id: String) -> ActiveSignal:
	for active_sig in _active_escalation_signals.values():
		if active_sig == null or active_sig.data == null:
			continue
		if active_sig.data.system_id == system_id:
			return active_sig
	return null

func get_triggered_tier_count() -> int:
	var count := 0
	for triggered in _triggered_tiers:
		if triggered:
			count += 1
	return count

func has_triggered_tier(tier_index: int) -> bool:
	if tier_index < 0 or tier_index >= _triggered_tiers.size():
		return false
	return _triggered_tiers[tier_index]

func _initialize_tier_state() -> void:
	_triggered_tiers.clear()
	for _i in escalation_thresholds.size():
		_triggered_tiers.append(false)

func _on_heat_state_changed(amount: float, _last_source: String) -> void:
	var heat_ratio := 0.0
	if heat_manager != null:
		heat_ratio = heat_manager.get_heat_ratio()
	else:
		var max_heat := 1.0
		if amount > 0.0:
			max_heat = amount
		heat_ratio = amount / max_heat

	_update_thresholds(heat_ratio)
	_refresh_panel(heat_ratio)

func _update_thresholds(heat_ratio: float) -> void:
	var new_active_tier := -1
	for i in range(escalation_thresholds.size()):
		var threshold := escalation_thresholds[i]
		if heat_ratio >= threshold:
			new_active_tier = i
			if not _triggered_tiers[i]:
				_triggered_tiers[i] = true
				_spawn_escalation_signal_for_tier(i)
				GlobalEvents.escalation_threshold_triggered.emit(i, threshold)

	if new_active_tier != _active_tier_index:
		_active_tier_index = new_active_tier
		GlobalEvents.escalation_state_changed.emit(_active_tier_index, get_triggered_tier_count())

func _build_panel() -> void:
	if escalation_panel == null or escalation_container == null:
		return

	escalation_panel.visible = true
	escalation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	escalation_panel.add_theme_stylebox_override("panel", style)

	for child in escalation_container.get_children():
		child.queue_free()

	_panel_margin_box = MarginContainer.new()
	_panel_margin_box.add_theme_constant_override("margin_left", 16)
	_panel_margin_box.add_theme_constant_override("margin_top", 14)
	_panel_margin_box.add_theme_constant_override("margin_right", 16)
	_panel_margin_box.add_theme_constant_override("margin_bottom", 14)
	escalation_container.add_child(_panel_margin_box)

	_panel_vbox = VBoxContainer.new()
	_panel_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_vbox.add_theme_constant_override("separation", 10)
	_panel_margin_box.add_child(_panel_vbox)

	_alert_bar = ColorRect.new()
	_alert_bar.custom_minimum_size = Vector2(0.0, 8.0)
	_alert_bar.color = BAR_IDLE
	_panel_vbox.add_child(_alert_bar)

	_pip_row = HBoxContainer.new()
	_pip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_pip_row.add_theme_constant_override("separation", 10)
	_panel_vbox.add_child(_pip_row)

	_tier_pips.clear()
	for _i in range(escalation_thresholds.size()):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(44.0, 20.0)
		pip.color = PIP_READY
		_pip_row.add_child(pip)
		_tier_pips.append(pip)

	_signal_row = HBoxContainer.new()
	_signal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_signal_row.add_theme_constant_override("separation", 18)
	_panel_vbox.add_child(_signal_row)

func _refresh_panel_layout() -> void:
	if escalation_panel == null:
		return
	escalation_panel.position = panel_margin
	escalation_panel.custom_minimum_size = panel_min_size
	for tier_index in _signal_hosts.keys():
		_refresh_signal_host_layout(int(tier_index))

func _on_timeline_layout_changed(_viewport_size: Vector2) -> void:
	_refresh_panel_layout()

func _refresh_panel(heat_ratio: float) -> void:
	if escalation_panel == null or _alert_bar == null:
		return

	_alert_bar.color = BAR_ACTIVE if _active_tier_index >= 0 else BAR_IDLE

	for i in range(_tier_pips.size()):
		var pip := _tier_pips[i]
		if pip == null:
			continue
		if i == _active_tier_index:
			pip.color = PIP_ACTIVE
		elif _triggered_tiers[i]:
			pip.color = PIP_TRIGGERED
		else:
			pip.color = PIP_READY

	var width_scale := clampf(heat_ratio, 0.08, 1.0)
	_alert_bar.custom_minimum_size.x = panel_min_size.x * width_scale

func _spawn_escalation_signal_for_tier(tier_index: int) -> void:
	if _active_escalation_signals.has(tier_index):
		return
	if _signal_row == null:
		return

	var tier_id := "%02d" % [tier_index + 1]
	var active_sig := ActiveSignal.new()
	active_sig.data = _spawner.create_escalation_signal(tier_id, 2)
	active_sig.start_cell_index = 0.0
	active_sig.setup()
	active_sig.generate_scan_layers()
	_active_escalation_signals[tier_index] = active_sig

	var host := Control.new()
	host.custom_minimum_size = Vector2(84.0, 84.0)
	host.mouse_filter = Control.MOUSE_FILTER_PASS
	_signal_row.add_child(host)
	_signal_hosts[tier_index] = host
	host.resized.connect(_refresh_signal_host_layout.bind(tier_index))

	var signal_node = _signal_scene.instantiate()
	host.add_child(signal_node)
	signal_node.setup(active_sig)
	signal_node.signal_interaction.connect(_on_escalation_signal_left_clicked)
	signal_node.scan_toggle_requested.connect(_on_escalation_signal_right_clicked)
	signal_node.tooltip_lock_requested.connect(_on_escalation_signal_middle_clicked)
	signal_node.hover_started.connect(_on_escalation_signal_mouse_enter)
	signal_node.hover_ended.connect(_on_escalation_signal_mouse_exit)
	active_sig.instance_node = signal_node

	_refresh_signal_host_layout(tier_index)

func _refresh_signal_host_layout(tier_index: int) -> void:
	if not _signal_hosts.has(tier_index):
		return
	if not _active_escalation_signals.has(tier_index):
		return

	var host: Control = _signal_hosts[tier_index]
	var active_sig: ActiveSignal = _active_escalation_signals[tier_index]
	if host == null or active_sig == null or active_sig.instance_node == null:
		return

	active_sig.instance_node.position = host.size * 0.5

func _is_escalation_signal_in_range(_active_sig: ActiveSignal) -> bool:
	return true

func _on_escalation_signal_left_clicked(active_sig: ActiveSignal) -> void:
	if not GlobalEvents.is_tutorial_feature_enabled("connect"):
		return
	if terminal_window == null:
		return
	terminal_window.access_signal_via_click(active_sig)

func _on_escalation_signal_right_clicked(active_sig: ActiveSignal) -> void:
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	if not _is_escalation_signal_in_range(active_sig):
		return
	if scan_controller != null:
		scan_controller.toggle_scan(active_sig)

func _on_escalation_signal_middle_clicked(active_sig: ActiveSignal) -> void:
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	if not _is_escalation_signal_in_range(active_sig):
		return
	if active_sig == null:
		return
	active_sig.is_tooltip_collapsed = not active_sig.is_tooltip_collapsed
	if active_sig.instance_node != null:
		active_sig.instance_node.tooltip_main.set_tooltip_collapsed(active_sig.is_tooltip_collapsed)
		active_sig.instance_node.bring_to_front()

func _on_escalation_signal_mouse_enter(active_sig: ActiveSignal) -> void:
	if not GlobalEvents.is_tutorial_feature_enabled("scan"):
		return
	if not _is_escalation_signal_in_range(active_sig):
		return
	if active_sig != null and active_sig.instance_node != null:
		active_sig.instance_node.set_hover_highlight(true)
		active_sig.instance_node.show_hover_tooltip()

func _on_escalation_signal_mouse_exit(active_sig: ActiveSignal) -> void:
	if active_sig != null and active_sig.instance_node != null:
		active_sig.instance_node.set_hover_highlight(false)
		active_sig.instance_node.fade_tooltip_body()
