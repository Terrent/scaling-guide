# data/resources/world/music_data.gd
# Defines the adaptive music configuration for a specific map or game state.
# Used by the client-side MusicManager to create a dynamic soundtrack.
class_name MusicData
extends Resource

# A dictionary of audio stems for vertical mixing.
# Key: layer_name (StringName), Value: audio_stream (AudioStream)
# Example: { &"drums": res://.../drums.ogg, &"strings": res://.../strings.ogg }
@export var vertical_layers: Dictionary = {}

# An array of full music tracks for horizontal mixing (e.g., transitioning between themes).
@export var horizontal_sections: Array[AudioStream]

# A dictionary defining how to react to game events.
# Key: trigger_event (StringName), Value: action_data (Dictionary)
# Example: { &"enter_combat": { "type": "fade_in_layer", "layer": &"drums", "duration": 1.5 } }
# Example: { &"leave_combat": { "type": "fade_out_layer", "layer": &"drums", "duration": 3.0 } }
@export var triggers: Dictionary = {}
