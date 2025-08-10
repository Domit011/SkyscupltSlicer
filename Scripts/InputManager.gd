# InputManager.gd - AutoLoad singleton
extends Node

# Default input mappings
var default_inputs = {
	"Left": KEY_A,
	"Right": KEY_D,
	"ui_up": KEY_UP,
	"ui_down": KEY_DOWN,
	"ui_left": KEY_LEFT,
	"ui_right": KEY_RIGHT
}

# Current input mappings
var current_inputs = {}

# Signal emitted when inputs change
signal inputs_changed

# File path for saving input settings
const INPUT_SETTINGS_FILE = "user://input_settings.json"

func _ready():
	# Load saved inputs or use defaults
	load_input_settings()
	apply_input_map()

func get_input_key(action_name: String) -> int:
	"""Get the current key code for an action"""
	if action_name in current_inputs:
		return current_inputs[action_name]
	elif action_name in default_inputs:
		return default_inputs[action_name]
	return KEY_UNKNOWN

func get_input_key_name(action_name: String) -> String:
	"""Get the display name for an action's key"""
	var key_code = get_input_key(action_name)
	return OS.get_keycode_string(key_code)

func set_input_key(action_name: String, key_code: int) -> bool:
	"""Set a new key for an action. Returns true if successful."""
	# Check if key is already assigned to another action
	for action in current_inputs:
		if action != action_name and current_inputs[action] == key_code:
			print("Key already assigned to: ", action)
			return false
	
	# Update the mapping
	current_inputs[action_name] = key_code
	
	# Apply to InputMap
	apply_single_input(action_name, key_code)
	
	# Save settings
	save_input_settings()
	
	# Emit signal for UI updates
	inputs_changed.emit()
	
	return true

func apply_input_map():
	"""Apply all current input mappings to Godot's InputMap"""
	for action_name in current_inputs:
		apply_single_input(action_name, current_inputs[action_name])

func apply_single_input(action_name: String, key_code: int):
	"""Apply a single input mapping to InputMap"""
	# Clear existing events for this action
	if InputMap.has_action(action_name):
		InputMap.action_erase_events(action_name)
	else:
		InputMap.add_action(action_name)
	
	# Add new key event
	var input_event = InputEventKey.new()
	input_event.physical_keycode = key_code
	InputMap.action_add_event(action_name, input_event)

func reset_to_defaults():
	"""Reset all inputs to default values"""
	current_inputs = default_inputs.duplicate()
	apply_input_map()
	save_input_settings()
	inputs_changed.emit()

func save_input_settings():
	"""Save current input settings to file"""
	var file = FileAccess.open(INPUT_SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_inputs))
		file.close()
		print("Input settings saved")

func load_input_settings():
	"""Load input settings from file"""
	var file = FileAccess.open(INPUT_SETTINGS_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data is Dictionary:
			current_inputs = json.data
			print("Input settings loaded")
		file.close()
	else:
		# Use defaults if no save file exists
		current_inputs = default_inputs.duplicate()
		print("Using default input settings")

func get_action_icon_texture(action_name: String) -> String:
	"""Get the texture path for an action's key icon"""
	var key_code = get_input_key(action_name)
	
	# Map common keys to icon paths - adjust these paths to match your icons
	match key_code:
		KEY_A:
			return "res://icons/tile_0120.png"
		KEY_D:
			return "res://icons/tile_0122.png"
		KEY_UP:
			return "res://icons/tile_0166.png"
		KEY_DOWN:
			return "res://iconstile_0166.png"
		KEY_LEFT:
			return "res://icons/tile_0169.png"
		KEY_RIGHT:
			return "res://icons/tile_0167.png"
		_:
			return "res://icons/key_unknown.png"


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
