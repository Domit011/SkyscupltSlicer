extends Control

@onready var main = get_tree().current_scene

func _ready():
	$AnimationPlayer.play("RESET")
	hide()

func resume():
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	hide()
	
func paused():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	show()

func testEsc():
	if Input.is_action_just_pressed("esc") and get_tree().paused == false:
		paused()
	elif Input.is_action_just_pressed("esc") and get_tree().paused == true:
		resume()
		
func _on_play_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _process(delta):
	testEsc()

func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Title_screen.tscn")
