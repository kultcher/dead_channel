extends Label

signal sniff_cell_clicked(value)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sniff_cell_clicked.emit(self.text)	
