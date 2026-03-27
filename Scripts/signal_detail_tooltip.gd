extends PanelContainer


@onready var tt_header = $TooltipHbox/TooltipVBox/HeaderPanel/MarginContainer/HeaderText
@onready var tt_body_box = $TooltipHbox/BodyBox
@onready var tt_body = $TooltipHbox/BodyBox/BodyText
@onready var tt_active_scan = $TooltipHbox/TooltipVBox/IconsHBox/ActiveScanPanel
@onready var tt_scan_icon = $TooltipHbox/TooltipVBox/IconsHBox/ActiveScanPanel/ScanMargin/ActiveScanIcon
@onready var tt_lock_state = $TooltipHbox/TooltipVBox/IconsHBox/LockStatePanel
@onready var tt_lock_icon = $TooltipHbox/TooltipVBox/IconsHBox/LockStatePanel/LockMargin/LockStateIcon
@onready var tt_ic_icon = $TooltipHbox/TooltipVBox/IconsHBox/ICStatePanel/ICMargin/ICStateIcon


const COLOR_STATUS_UNKNOWN := Color("4a2d64")
const COLOR_STATUS_SCANNING := Color("009632ff")
const COLOR_STATUS_COMPLETE := Color("00fa64ff")
const COLOR_STATUS_PARTIAL := Color("c1a126")

const COLOR_LOCK_OPEN := Color("0096faff")
const COLOR_LOCK_LOCKED := Color("ff0000ff")
const COLOR_LOCK_HACKED := Color("0096faff")

func set_tooltip_collapsed(collapsed: bool):
	show()
	tt_body_box.visible = not collapsed
	tt_body.visible = not collapsed
	tt_active_scan.visible = true
	tt_lock_state.visible = true
	#size.x = tooltip_main_initial_x

func get_lock_state_focus_rect() -> Rect2:
	if tt_lock_state == null or not tt_lock_state.is_visible_in_tree():
		return Rect2()
	return tt_lock_state.get_global_rect()

enum IconState { UNKNOWN_SCAN, UNKNOWN_LOCK, SCANNING, PARTIAL, COMPLETE, OPEN, LOCKED, HACKED, NO_IC, ACTIVE_IC }

func set_panel_state(icon: Control, type):
#	var base_style = panel.get_theme_stylebox("panel")
#	var style: StyleBoxFlat
#	if base_style is StyleBoxFlat:
#		style = (base_style as StyleBoxFlat).duplicate()
#	else:
#		style = StyleBoxFlat.new()
#	panel.add_theme_stylebox_override("panel", style)
	match type:
		#IconState.UNKNOWN_SCAN:
			#icon.set_self_modulate(COLOR_STATUS_UNKNOWN)
		#IconState.UNKNOWN_LOCK:
			#icon.set_self_modulate(COLOR_STATUS_UNKNOWN)
		IconState.SCANNING:	
			icon.set_self_modulate(COLOR_STATUS_SCANNING)
		IconState.PARTIAL: icon.set_self_modulate(COLOR_STATUS_PARTIAL)
		IconState.COMPLETE:
			icon.texture = preload("res://Visuals/Icons/Simple/check-mark.svg")
			icon.set_self_modulate(COLOR_STATUS_COMPLETE)
		IconState.OPEN:
			icon.texture = preload("res://Visuals/Icons/Simple/padlock-open.svg")
			icon.set_self_modulate(COLOR_LOCK_OPEN)
		IconState.LOCKED:
			icon.texture = preload("res://Visuals/Icons/Simple/padlock.svg")
			icon.set_self_modulate(COLOR_LOCK_LOCKED)
		IconState.HACKED:
			icon.texture = preload("res://Visuals/Icons/Simple/padlock-open.svg")
			icon.set_self_modulate(COLOR_LOCK_HACKED)
		IconState.ACTIVE_IC:
			icon.set_self_modulate(COLOR_LOCK_LOCKED)
		IconState.NO_IC:
			icon.texture = preload("res://Visuals/Icons/Simple/cancel.svg")
			icon.set_self_modulate(COLOR_STATUS_COMPLETE)
