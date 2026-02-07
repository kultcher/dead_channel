# sniffer_puzzle.gd
# Matrix-style hex search minigame. Player must click matching hex values in a scrolling grid.
extends PanelContainer

# --- CONFIG (passed in or set defaults) ---
var config := {
	"grid_cols": 4,
	"grid_rows": 4,
	"cell_size": 80,           # pixels per cell
	"target_count": 1,         # how many values to match
	"scroll_direction": "vertical",  # "vertical" or "horizontal"
	"base_speed": 50.0,        # base pixels/sec
	"speed_variance": 0.5,     # per-column variance (0.5 = 50% spread)
	"col_speeds": [],          # override: if non-empty, used directly
}

# --- REFERENCES ---
var grid_panel: Panel
var grid_container: Control
var target_footer: HBoxContainer
var target_label: Label

# --- STATE ---
var cells: Array = []
var col_speeds: Array[float] = []
var target_sequence: Array[String] = []   # all target values (ordered for display)
var remaining_targets: Array[String] = [] # unsolved targets
var target_slots: Array[PanelContainer] = []
var pending_targets: Array[String] = [] # Values waiting to re-enter the screen
var time_to_solve = 0

const BASE_CELL_COLOR = Color(0, .85, 0)
const TARGET_CELL_COLOR = Color(0, 1, 0)

signal puzzle_solved
signal puzzle_failed

func _ready():
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# Grid panel (clipped area for scrolling hex values)
	grid_panel = Panel.new()
	grid_panel.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	var grid_w = config.grid_cols * config.cell_size
	var grid_h = config.grid_rows * config.cell_size
	grid_panel.custom_minimum_size = Vector2(grid_w, grid_h)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color.BLACK
	grid_panel.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(grid_panel)
	
	grid_container = Control.new()
	grid_panel.add_child(grid_container)
	
	_build_footer(vbox)
	_calculate_speeds()
	_populate_grid()
	_generate_targets()
	_update_footer()

func _process(delta: float):
	time_to_solve += delta

	var is_vertical = config.scroll_direction == "vertical"
	
	for cell in cells:
		var col = cell.get_meta("col")
		var speed = col_speeds[col]
		
		if is_vertical:
			cell.position.y += speed * delta
			if cell.position.y > config.grid_rows * config.cell_size:
				_recycle_cell(cell, true)
		else:
			cell.position.x += speed * delta
			if cell.position.x > config.grid_cols * config.cell_size:
				_recycle_cell(cell, false)

func _calculate_speeds():
	col_speeds.clear()
	if config.col_speeds.size() > 0:
		col_speeds = config.col_speeds.duplicate()
	else:
		for i in config.grid_cols:
			var t = float(i) / max(config.grid_cols - 1, 1)
			var variance = lerp(-config.speed_variance, config.speed_variance, t)
			col_speeds.append(config.base_speed * (1.0 + variance))

# === GRID & CELLS ===

func _populate_grid():
	var total_rows = config.grid_rows + 2
	
	for col in config.grid_cols:
		for row in total_rows:
			var cell = _create_cell(col, row)
			var x = col * config.cell_size
			var y = (row - 1) * config.cell_size
			cell.position = Vector2(x, y)
			grid_container.add_child(cell)
			cells.append(cell)

func _create_cell(col: int, row: int) -> Label:
	var cell = Label.new()
	cell.text = _generate_hex()
	cell.set_meta("col", col)
	cell.set_meta("row", row)
	cell.set_meta("is_target", false)
	cell.set_meta("target_value", "")
	
	cell.custom_minimum_size = Vector2(config.cell_size, config.cell_size)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.add_theme_font_size_override("font_size", 28)
	cell.add_theme_color_override("font_color", BASE_CELL_COLOR)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	
	cell.gui_input.connect(_on_cell_input.bind(cell))
	return cell

func _recycle_cell(cell: Label, is_vertical: bool):
	# 1. Capture the target if we are losing it
	if cell.get_meta("is_target", false):
		var val = cell.get_meta("target_value")
		if val in remaining_targets:
			pending_targets.append(val) # Add to waiting list

	# 2. Reset the cell visually (standard recycling)
	cell.set_meta("is_target", false)
	cell.set_meta("target_value", "")
	cell.add_theme_color_override("font_color", BASE_CELL_COLOR)

	# 3. Reposition to the TOP (The Entrance)
	if is_vertical:
		cell.position.y -= (config.grid_rows + 2) * config.cell_size
	else:
		cell.position.x -= (config.grid_cols + 2) * config.cell_size

	# 4. Assign New Value (The Entry Logic)
	# Check if we have a pending target waiting to enter
	if pending_targets.size() > 0:
		var val = pending_targets.pop_front() # Take the oldest waiting target
		cell.text = val
		cell.set_meta("is_target", true)
		cell.set_meta("target_value", val)
		cell.add_theme_color_override("font_color", TARGET_CELL_COLOR)
	else:
		# Standard random hex
		cell.text = _generate_hex_avoiding_all(remaining_targets)

# === HEX GENERATION ===

func _generate_hex() -> String:
	return "%02X" % randi_range(0, 255)

func _generate_hex_avoiding_all(avoid: Array) -> String:
	var result = _generate_hex()
	while result in avoid:
		result = _generate_hex()
	return result

# === TARGET SYSTEM ===

func _generate_targets():
	target_sequence.clear()
	remaining_targets.clear()
	
	for i in config.target_count:
		var val = _generate_hex_avoiding_all(target_sequence)
		target_sequence.append(val)
		remaining_targets.append(val)
	
	# Seed ALL target values into the grid immediately
	for val in target_sequence:
		_seed_value_in_grid(val)

func _seed_value_in_grid(value: String):
	var candidates = cells.filter(func(c): return not c.get_meta("is_target"))
	if candidates.size() > 0:
		var chosen = candidates.pick_random()
		chosen.text = value
		chosen.set_meta("is_target", true)
		chosen.set_meta("target_value", value)
		chosen.add_theme_color_override("font_color", TARGET_CELL_COLOR)


# === INPUT ===

func _on_cell_input(event: InputEvent, cell: Label):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_check_match(cell)

func _check_match(cell: Label):
	if cell.text in remaining_targets:
		# HIT — remove from remaining, mark cell as no longer a target
		var matched_value = cell.text
		var idx = target_sequence.find(matched_value)
		remaining_targets.erase(matched_value)
		cell.set_meta("is_target", false)
		cell.set_meta("target_value", "")
		
		_mark_slot_complete(idx, matched_value)
		
		if remaining_targets.is_empty():
			puzzle_solved.emit()
			var time_string = "%.1f" % time_to_solve
			print("SNIFFER COMPLETE. Solved in %s seconds." % time_string)
		else:
			_update_footer()
	else:
		# MISS — brief red flash
		cell.add_theme_color_override("font_color", Color.RED)
		get_tree().create_timer(0.15).timeout.connect(
			func(): cell.add_theme_color_override("font_color", BASE_CELL_COLOR)
		)

# === FOOTER UI ===

func _build_footer(parent: VBoxContainer):
	var footer_panel = PanelContainer.new()
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = Color(0.1, 0.1, 0.1)
	footer_style.border_color = Color(0, 1, 0, 0.5)
	footer_style.border_width_top = 2
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	parent.add_child(footer_panel)
	
	target_footer = HBoxContainer.new()
	target_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	target_footer.add_theme_constant_override("separation", 8)
	footer_panel.add_child(target_footer)
	
	target_label = Label.new()
	target_label.text = "TARGET:"
	target_label.add_theme_color_override("font_color", Color(0, 1, 0))
	target_label.add_theme_font_size_override("font_size", 24)
	target_footer.add_child(target_label)
	
	target_slots.clear()
	for i in config.target_count:
		var slot = _create_target_slot()
		target_footer.add_child(slot)
		target_slots.append(slot)

func _create_target_slot() -> PanelContainer:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(60, 40)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05)
	style.border_color = Color(0, 1, 0, 0.3)
	style.set_border_width_all(2)
	slot.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = "??"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0, 1, 0, 0.4))
	lbl.add_theme_font_size_override("font_size", 24)
	slot.add_child(lbl)
	
	return slot

func _update_footer():
	for i in target_slots.size():
		var slot = target_slots[i]
		var lbl = slot.get_child(0) as Label
		var style = slot.get_theme_stylebox("panel") as StyleBoxFlat
		var val = target_sequence[i]
		
		if val in remaining_targets:
			# Unsolved — show value in yellow (clickable in any order)
			lbl.text = val
			lbl.add_theme_color_override("font_color", Color(1, 1, 0))
			style.border_color = Color(1, 1, 0, 0.8)
		else:
			# Completed
			lbl.text = val
			lbl.add_theme_color_override("font_color", Color(0, 1, 0))
			style.border_color = Color(0, 1, 0, 0.8)

func _mark_slot_complete(index: int, value: String):
	var slot = target_slots[index]
	var lbl = slot.get_child(0) as Label
	lbl.text = value
	lbl.add_theme_color_override("font_color", Color(0, 1, 0))
	var style = slot.get_theme_stylebox("panel") as StyleBoxFlat
	style.border_color = Color(0, 1, 0, 0.8)
