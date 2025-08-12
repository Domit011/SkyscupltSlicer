extends Control

@onready var music_slider: HSlider = $VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXContainer/SFXSlider
@onready var music_label: Label = $VBoxContainer/MusicContainer/MusicLabel
@onready var sfx_label: Label = $VBoxContainer/SFXContainer/SFXLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	# Start menu music when entering any menu scene
	if AudioManager:
		AudioManager.start_menu_music()
	
	# Setup volume sliders
	setup_volume_sliders()
	
	# Connect back button (disconnect first if already connected)
	if back_button:
		# Disconnect any existing connections to avoid duplicates
		if back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.disconnect(_on_back_button_pressed)
		back_button.pressed.connect(_on_back_button_pressed)
		print("✅ Back button connected")
	else:
		print("❌ ERROR: back_button not found!")

func _exit_tree() -> void:
	# Don't stop the music when switching between menus
	# Only stop when going to game scene
	pass

func setup_volume_sliders():
	# Configure slider ranges (0 to 100 for percentage)
	if music_slider:
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.step = 1
	else:
		print("❌ ERROR: music_slider not found!")
		return
	
	if sfx_slider:
		sfx_slider.min_value = 0
		sfx_slider.max_value = 100
		sfx_slider.step = 1
	else:
		print("❌ ERROR: sfx_slider not found!")
		return
	
	# Set initial values from AudioManager
	if AudioManager:
		music_slider.value = AudioManager.get_music_volume_percent()
		sfx_slider.value = AudioManager.get_sfx_volume_percent()
	else:
		print("❌ ERROR: AudioManager not found!")
		# Set default values
		music_slider.value = 50
		sfx_slider.value = 50
	
	# Update labels
	update_volume_labels()
	
	# Connect slider signals (disconnect first if already connected)
	if music_slider.value_changed.is_connected(_on_music_volume_changed):
		music_slider.value_changed.disconnect(_on_music_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	
	if sfx_slider.value_changed.is_connected(_on_sfx_volume_changed):
		sfx_slider.value_changed.disconnect(_on_sfx_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_music_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_music_volume_percent(value)
	update_music_label()

func _on_sfx_volume_changed(value: float):
	if AudioManager:
		AudioManager.set_sfx_volume_percent(value)
	update_sfx_label()

func update_volume_labels():
	update_music_label()
	update_sfx_label()

func update_music_label():
	if music_label and music_slider:
		music_label.text = str(int(music_slider.value)) + "%"

func update_sfx_label():
	if sfx_label and sfx_slider:
		sfx_label.text = str(int(sfx_slider.value)) + "%"

func _on_back_button_pressed():
	"""Go back to main menu"""
	print("⬅️ Going back to main menu...")
	# Change this path to match your main menu scene
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Title_screen.tscn")
