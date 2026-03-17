#dialogue_window.gd

extends PanelContainer

var chat: RichTextLabel

func setup(event: TutorialEvent):
	chat = $TerminalVBox/ChatLog
	self.position = Vector2(1400, 300)
	set_text(event.text[0])
	
func set_text(text: String):
	chat.text = text

func _on_button_pressed() -> void:
	queue_free()
