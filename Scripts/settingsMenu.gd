extends Control

@onready var music_slider: HSlider = $VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SFXContainer/SFXSlider
@onready var music_label: Label = $VBoxContainer/MusicContainer/MusicLabel
@onready var sfx_label: Label = $VBoxContainer/SFXContainer/SFXLabel

func _ready() -> void:
	# Start menu music when entering any menu scene
	AudioManager.start_menu_music()
	
	# Setup volume sliders
	setup_volume_sliders()

func _exit_tree() -> void:
	# Don't stop the music when switching between menus
	# Only stop when going to game scene
	pass

func setup_volume_sliders():
	# Configure slider ranges (0 to 100 for percentage)
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	
	# Set initial values from AudioManager
	music_slider.value = AudioManager.get_music_volume_percent()
	sfx_slider.value = AudioManager.get_sfx_volume_percent()
	
	# Update labels
	update_volume_labels()
	
	# Connect slider signals
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_music_volume_changed(value: float):
	AudioManager.set_music_volume_percent(value)
	update_music_label()

func _on_sfx_volume_changed(value: float):
	AudioManager.set_sfx_volume_percent(value)
	update_sfx_label()

func update_volume_labels():
	update_music_label()
	update_sfx_label()

func update_music_label():
	music_label.text = "Music: " + str(int(music_slider.value)) + "%"

func update_sfx_label():
	sfx_label.text = "SFX: " + str(int(sfx_slider.value)) + "%"
