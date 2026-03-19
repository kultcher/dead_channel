#dialogue_window.gd

extends PanelContainer

var chat: RichTextLabel
var page_label: Label
var left_button: Button
var right_button: Button
var continue_button: Button

var pages: Array[String] = []
var page_index: int = 0

signal dismissed

func setup(event: TutorialEvent):
	chat = $TerminalVBox/ChatLog
	page_label = $TerminalVBox/FooterHBox/PageLabel
	left_button = $TerminalVBox/FooterHBox/LeftButton
	right_button = $TerminalVBox/FooterHBox/RightButton
	continue_button = $TerminalVBox/FooterHBox/ContinueButton
	pages = event.text.duplicate()
	page_index = 0
	position = event.default_position if event.default_position != Vector2.ZERO else Vector2(1400, 300)
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
