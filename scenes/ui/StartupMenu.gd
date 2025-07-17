# res://scenes/ui/StartupMenu.gd
# This script controls the logic for the initial startup menu, handling
# user input to host or join a multiplayer session.
class_name StartupMenu
extends Control

# Node references are declared using @onready to ensure the nodes are available
# when the variables are initialized. Variables use snake_case.[1]
@onready var ip_address_line_edit: LineEdit = %IpAddressLineEdit
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton


# The _ready function is a Godot virtual function, prefixed with an underscore.[1]
# It's called once when the node enters the scene tree.
# We use it to connect signals to their callback functions.
func _ready() -> void:
	# Connect the 'pressed' signal of each button to its corresponding handler function.
	# The function names follow the _on_[NodeName]_[signal_name] convention.[1]
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)


# This function is called when the HostButton is pressed.
func _on_host_button_pressed() -> void:
	# Call the create_server function on the global NetworkManager singleton.
	# We pass an empty dictionary for settings as none are configured in this basic UI.
	# The NetworkManager handles all the complexity of server creation.[1]
	NetworkManager.create_server({})


# This function is called when the JoinButton is pressed.
func _on_join_button_pressed() -> void:
	# Retrieve the text from the IP address input field.
	var ip_address: String = ip_address_line_edit.text
	
	# Call the join_server function on the global NetworkManager singleton,
	# passing the user-provided IP address. The NetworkManager handles all
	# the complexity of creating a client and connecting.[1]
	NetworkManager.join_server(ip_address)
