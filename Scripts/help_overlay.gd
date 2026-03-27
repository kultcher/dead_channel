extends Panel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_exit_help()

func _on_button_pressed() -> void:
	_exit_help()

func _exit_help():
	get_tree().paused = false
	queue_free()
