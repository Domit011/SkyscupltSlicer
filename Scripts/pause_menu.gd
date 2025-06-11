extends Control

func resume():
	get_tree().paused = false
	
func paused():
	get_tree().paused = true
	
func testEsc():
	if Input.is_action_just_pressed("esc") and get.tree().paused == false:
		paused()
	elif Input.is_action_just_pressed("esc") and get.tree().paused == true:
		resume()
		

func _on_restart_pressed() -> void:
	get.tree().reload_current_scene()


func _on_quit_pressed() -> void:



func _on_play_pressed() -> void:
	resume()
