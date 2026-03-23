#dialogue_window.gd

extends PanelContainer

var chat: RichTextLabel
var page_label: Label
var left_button: Button
var right_button: Button
var continue_button: Button

var pages: Array[String] = []
var page_index: int = 0
var tutorial_event_id: String = ""

signal dismissed

func setup(event: TutorialEvent, focus_rect: Rect2 = Rect2()):
	chat = $TerminalVBox/BodyHBox/ChatLog
	page_label = $TerminalVBox/FooterHBox/PageLabel
	left_button = $TerminalVBox/FooterHBox/LeftButton
	right_button = $TerminalVBox/FooterHBox/RightButton
	continue_button = $TerminalVBox/FooterHBox/ContinueButton
	pages = event.text.duplicate()
	tutorial_event_id = event.id
	page_index = 0
	if event.has_custom_position:
		position = _clamp_to_viewport(event.default_position, get_viewport_rect().size)
	elif _has_focus_rect(focus_rect):
		position = _get_position_from_focus_rect(focus_rect)
	else:
		position = _get_default_position()
	_refresh_page()
	
func set_text(text: String):
	chat.text = text

func _refresh_page():
	if pages.is_empty():
		set_text("")
		page_label.text = "0/0"
		left_button.disabled = true
		right_button.disabled = true
		return

	page_index = clampi(page_index, 0, pages.size() - 1)
	set_text(pages[page_index])
	page_label.text = "%d/%d" % [page_index + 1, pages.size()]

	var has_multiple_pages := pages.size() > 1
	left_button.visible = has_multiple_pages
	right_button.visible = has_multiple_pages
	page_label.visible = has_multiple_pages
	left_button.disabled = page_index == 0
	right_button.disabled = page_index == pages.size() - 1
	continue_button.disabled = page_index != pages.size() - 1

func _on_left_button_pressed() -> void:
	if page_index == 0:
		return

	page_index -= 1
	_refresh_page()

func _on_right_button_pressed() -> void:
	if page_index >= pages.size() - 1:
		return

	page_index += 1
	_refresh_page()

func _on_continue_button_pressed() -> void:
	if continue_button.disabled:
		return

	dismissed.emit()
	queue_free()

func _get_default_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var target_position := Vector2(viewport_size.x * 0.72, viewport_size.y * 0.28)
	return _clamp_to_viewport(target_position, viewport_size)

func _get_position_from_focus_rect(focus_rect: Rect2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var target_position := Vector2(
		focus_rect.position.x - (size.x * 0.4),
		focus_rect.end.y + 64.0
	)
	return _clamp_to_viewport(target_position, viewport_size)

func _clamp_to_viewport(target_position: Vector2, viewport_size: Vector2) -> Vector2:
	var max_position := viewport_size - size
	return Vector2(
		clampf(target_position.x, 0.0, max_position.x),
		clampf(target_position.y, 0.0, max_position.y)
	)

func _has_focus_rect(focus_rect: Rect2) -> bool:
	return focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0
