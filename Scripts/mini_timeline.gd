extends PanelContainer

const VISIBLE_COLUMNS := 4
const VISIBLE_LANES := 5
const TOTAL_SLOTS := VISIBLE_COLUMNS * VISIBLE_LANES
const CELL_OFFSET := 4
const MARKER_SCALE := 0.22
const MARKER_STACK_SPACING := 6.0

@onready var grid: GridContainer = $MiniTimelineGrid

var _slot_panels: Array[PanelContainer] = []
var _slot_template: PanelContainer = null
var _signal_manager: Node = null
var _timeline_manager: Node = null

func _ready() -> void:
	_slot_template = $MiniTimelineGrid/MiniSignalPanel
	_signal_manager = get_node_or_null("../SignalTimeline/SignalManager")
	_timeline_manager = get_node_or_null("../SignalTimeline/TimelineManager")

	_initialize_grid()

	if GlobalEvents.cell_reached.is_connected(_on_cell_reached) == false:
		GlobalEvents.cell_reached.connect(_on_cell_reached)

	call_deferred("_refresh_from_timeline")

func _initialize_grid() -> void:
	if _slot_template == null:
		return

	_slot_panels.clear()
	_slot_panels.append(_slot_template)
	for _index in range(1, TOTAL_SLOTS):
		var duplicate_panel := _slot_template.duplicate()
		grid.add_child(duplicate_panel)
		_slot_panels.append(duplicate_panel)

func _refresh_from_timeline() -> void:
	if _timeline_manager == null:
		return
	var current_cell := int(floor(_timeline_manager.current_cell_pos))
	_rebuild_visible_window(current_cell)

func _on_cell_reached(cell: int) -> void:
	_rebuild_visible_window(cell)

func _rebuild_visible_window(current_cell: int) -> void:
	_clear_slot_markers()

	if _signal_manager == null:
		return

	var visible_start_cell := current_cell + CELL_OFFSET
	var visible_end_cell := visible_start_cell + VISIBLE_COLUMNS - 1
	var slot_counts: Dictionary = {}

	for active_sig in _signal_manager.signal_queue:
		if active_sig == null or active_sig.data == null:
			continue

		var signal_cell = active_sig.start_cell_index
		if active_sig.runtime_position_initialized:
			signal_cell = active_sig.runtime_cell_x

		var signal_column := int(floor(signal_cell))
		if signal_column < visible_start_cell or signal_column > visible_end_cell:
			continue

		var lane := clampi(active_sig.data.lane, 0, VISIBLE_LANES - 1)
		var column_index := signal_column - visible_start_cell
		var slot_index := lane * VISIBLE_COLUMNS + column_index
		if slot_index < 0 or slot_index >= _slot_panels.size():
			continue

		var stack_count := int(slot_counts.get(slot_index, 0))
		slot_counts[slot_index] = stack_count + 1
		_add_signal_marker(_slot_panels[slot_index], active_sig, stack_count)

func _clear_slot_markers() -> void:
	for panel in _slot_panels:
		if panel == null:
			continue
		for child in panel.get_children():
			if child is Polygon2D:
				child.queue_free()

func _add_signal_marker(slot_panel: PanelContainer, active_sig, stack_index: int) -> void:
	if slot_panel == null or active_sig == null or active_sig.data == null:
		return

	var visuals = active_sig.data.visuals
	if active_sig.data.use_alternate_visuals and active_sig.data.alternate_visuals != null:
		visuals = active_sig.data.alternate_visuals

	var marker := Polygon2D.new()
	marker.antialiased = true
	marker.color = visuals.fill_color if visuals != null else Color.WHITE
	marker.polygon = _build_marker_polygon(visuals)

	var slot_size := slot_panel.size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		slot_size = slot_panel.custom_minimum_size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		slot_size = Vector2(32.0, 16.0)

	var center := slot_size * 0.5
	var stack_offset := Vector2(stack_index * MARKER_STACK_SPACING, 0.0)
	marker.position = center + stack_offset
	slot_panel.add_child(marker)

func _build_marker_polygon(visuals) -> PackedVector2Array:
	if visuals == null or visuals.polygon.is_empty():
		return PackedVector2Array([
			Vector2(-6, -4),
			Vector2(6, -4),
			Vector2(6, 4),
			Vector2(-6, 4),
		])

	var scaled_points := PackedVector2Array()
	for point in visuals.polygon:
		scaled_points.append(point * MARKER_SCALE)
	return scaled_points
