# tests/unit/test_music_data.gd
extends GutTest

var music: MusicData
var mock_audio_stream: AudioStream

func before_each():
	music = MusicData.new()
	# Create a minimal AudioStream resource for testing
	mock_audio_stream = AudioStream.new()

func test_default_values():
	assert_eq(music.vertical_layers.size(), 0)
	assert_eq(music.horizontal_sections.size(), 0)
	assert_eq(music.triggers.size(), 0)

func test_vertical_layering_setup():
	# Set up a typical vertical mix for exploration music
	music.vertical_layers = {
		&"base": mock_audio_stream,      # Always playing
		&"drums": mock_audio_stream,     # Fades in during combat
		&"strings": mock_audio_stream,   # Emotional moments
		&"choir": mock_audio_stream      # Epic moments
	}
	
	assert_eq(music.vertical_layers.size(), 4)
	assert_has(music.vertical_layers, &"base")
	assert_has(music.vertical_layers, &"drums")
	assert_has(music.vertical_layers, &"strings")
	assert_has(music.vertical_layers, &"choir")

func test_horizontal_sections():
	# Different musical themes that can transition between each other
	var peaceful_theme = mock_audio_stream
	var tense_theme = mock_audio_stream
	var victory_theme = mock_audio_stream
	
	music.horizontal_sections = [peaceful_theme, tense_theme, victory_theme]
	
	assert_eq(music.horizontal_sections.size(), 3)
	assert_eq(music.horizontal_sections[0], peaceful_theme)
	assert_eq(music.horizontal_sections[1], tense_theme)
	assert_eq(music.horizontal_sections[2], victory_theme)

func test_combat_music_triggers():
	# Configure triggers for combat music
	music.triggers = {
		&"enter_combat": {
			"type": "fade_in_layer",
			"layer": &"drums",
			"duration": 1.5
		},
		&"combat_intense": {
			"type": "fade_in_layer", 
			"layer": &"choir",
			"duration": 2.0
		},
		&"leave_combat": {
			"type": "fade_out_layer",
			"layer": &"drums",
			"duration": 3.0
		}
	}
	
	assert_eq(music.triggers.size(), 3)
	
	# Test enter combat trigger
	var enter_combat = music.triggers[&"enter_combat"]
	assert_eq(enter_combat["type"], "fade_in_layer")
	assert_eq(enter_combat["layer"], &"drums")
	assert_eq(enter_combat["duration"], 1.5)
	
	# Test leave combat has longer fade
	var leave_combat = music.triggers[&"leave_combat"]
	assert_eq(leave_combat["duration"], 3.0)

func test_emotional_scene_triggers():
	# Configure triggers for dialogue/cutscenes
	music.triggers = {
		&"sad_dialogue": {
			"type": "fade_in_layer",
			"layer": &"strings",
			"duration": 2.5
		},
		&"romantic_scene": {
			"type": "crossfade_to_section",
			"section_index": 2,
			"duration": 4.0
		},
		&"npc_death": {
			"type": "stop_all_layers",
			"except": [&"strings"],
			"duration": 1.0
		}
	}
	
	# Test different trigger types
	assert_has(music.triggers[&"romantic_scene"], "section_index")
	assert_eq(music.triggers[&"romantic_scene"]["section_index"], 2)
	
	# Test complex trigger with exceptions
	var npc_death = music.triggers[&"npc_death"]
	assert_eq(npc_death["type"], "stop_all_layers")
	assert_eq(npc_death["except"][0], &"strings")

func test_farming_music_layers():
	# A peaceful farming area with environmental layers
	music.vertical_layers = {
		&"ambient": mock_audio_stream,     # Birds, wind
		&"melody": mock_audio_stream,      # Main theme
		&"morning": mock_audio_stream,     # Morning instruments
		&"evening": mock_audio_stream,     # Evening instruments
		&"rain": mock_audio_stream         # Rain ambience
	}
	
	music.triggers = {
		&"time_morning": {
			"type": "fade_in_layer",
			"layer": &"morning",
			"duration": 5.0
		},
		&"time_evening": {
			"type": "crossfade_layers",
			"fade_out": &"morning",
			"fade_in": &"evening", 
			"duration": 10.0
		},
		&"weather_rain": {
			"type": "fade_in_layer",
			"layer": &"rain",
			"duration": 3.0
		}
	}
	
	# Verify time-based triggers
	assert_has(music.triggers, &"time_morning")
	assert_has(music.triggers, &"time_evening")
	
	# Test crossfade trigger
	var evening_trigger = music.triggers[&"time_evening"]
	assert_eq(evening_trigger["type"], "crossfade_layers")
	assert_eq(evening_trigger["fade_out"], &"morning")
	assert_eq(evening_trigger["fade_in"], &"evening")

func test_festival_music_configuration():
	# Special music for festivals with multiple sections
	music.horizontal_sections = [
		mock_audio_stream,  # Pre-festival buildup
		mock_audio_stream,  # Festival main theme
		mock_audio_stream,  # Minigame music
		mock_audio_stream   # Festival ending
	]
	
	music.triggers = {
		&"festival_start": {
			"type": "transition_to_section",
			"section_index": 1,
			"transition_type": "immediate"
		},
		&"minigame_start": {
			"type": "transition_to_section",
			"section_index": 2,
			"transition_type": "crossfade",
			"duration": 0.5
		},
		&"festival_end": {
			"type": "transition_to_section",
			"section_index": 3,
			"transition_type": "fade",
			"duration": 3.0
		}
	}
	
	# Test immediate vs crossfade transitions
	assert_eq(music.triggers[&"festival_start"]["transition_type"], "immediate")
	assert_eq(music.triggers[&"minigame_start"]["transition_type"], "crossfade")
	assert_eq(music.triggers[&"festival_end"]["duration"], 3.0)

func test_dungeon_music_layers():
	# Dynamic dungeon music that responds to danger
	music.vertical_layers = {
		&"atmosphere": mock_audio_stream,
		&"tension": mock_audio_stream,
		&"danger": mock_audio_stream,
		&"boss": mock_audio_stream
	}
	
	music.triggers = {
		&"enemy_nearby": {
			"type": "adjust_layer_volume",
			"layer": &"tension",
			"target_volume": 0.7,
			"duration": 1.0
		},
		&"boss_encounter": {
			"type": "complex_action",
			"actions": [
				{"type": "fade_out_layer", "layer": &"atmosphere", "duration": 0.5},
				{"type": "fade_in_layer", "layer": &"boss", "duration": 1.0}
			]
		}
	}
	
	# Test volume adjustment trigger
	var enemy_nearby = music.triggers[&"enemy_nearby"]
	assert_eq(enemy_nearby["type"], "adjust_layer_volume")
	assert_eq(enemy_nearby["target_volume"], 0.7)
	
	# Test complex multi-action trigger
	var boss_trigger = music.triggers[&"boss_encounter"]
	assert_eq(boss_trigger["type"], "complex_action")
	assert_eq(boss_trigger["actions"].size(), 2)

func test_empty_configuration():
	# Music data can be empty (silence)
	assert_eq(music.vertical_layers.size(), 0)
	assert_eq(music.horizontal_sections.size(), 0)
	assert_eq(music.triggers.size(), 0)

func test_single_layer_music():
	# Simple music with just one track
	music.vertical_layers = {
		&"main": mock_audio_stream
	}
	
	assert_eq(music.vertical_layers.size(), 1)
	assert_has(music.vertical_layers, &"main")

# Parameterized test for different music scenarios
func test_music_scenarios(params=use_parameters([
	{
		"name": "Shop",
		"layers": 2,
		"sections": 0,
		"triggers": 1
	},
	{
		"name": "Boss Battle", 
		"layers": 5,
		"sections": 3,
		"triggers": 8
	},
	{
		"name": "Peaceful Farm",
		"layers": 3,
		"sections": 0,
		"triggers": 4
	},
	{
		"name": "Mines",
		"layers": 4,
		"sections": 2,
		"triggers": 6
	}
])):
	# Set up music based on scenario
	for i in range(params.layers):
		music.vertical_layers[StringName("layer_%d" % i)] = mock_audio_stream
	
	for i in range(params.sections):
		music.horizontal_sections.append(mock_audio_stream)
	
	for i in range(params.triggers):
		music.triggers[StringName("trigger_%d" % i)] = {"type": "test"}
	
	gut.p("%s music: %d layers, %d sections, %d triggers" % 
		[params.name, params.layers, params.sections, params.triggers])
	
	assert_eq(music.vertical_layers.size(), params.layers)
	assert_eq(music.horizontal_sections.size(), params.sections)
	assert_eq(music.triggers.size(), params.triggers)

func test_realistic_farm_music_complete():
	# A complete, realistic farm area music setup
	music.vertical_layers = {
		&"nature_ambient": mock_audio_stream,    # Birds, insects
		&"base_melody": mock_audio_stream,       # Main peaceful theme  
		&"morning_birds": mock_audio_stream,     # Extra birds in morning
		&"night_crickets": mock_audio_stream,    # Crickets at night
		&"rain_layer": mock_audio_stream,        # Rain sounds
		&"activity": mock_audio_stream           # When player is active
	}
	
	music.triggers = {
		# Time of day
		&"dawn": {
			"type": "fade_in_layer",
			"layer": &"morning_birds", 
			"duration": 10.0
		},
		&"dusk": {
			"type": "crossfade_layers",
			"fade_out": &"morning_birds",
			"fade_in": &"night_crickets",
			"duration": 15.0
		},
		# Weather
		&"rain_start": {
			"type": "fade_in_layer",
			"layer": &"rain_layer",
			"duration": 5.0
		},
		# Player activity  
		&"start_farming": {
			"type": "fade_in_layer",
			"layer": &"activity",
			"duration": 2.0
		},
		&"stop_farming": {
			"type": "fade_out_layer",
			"layer": &"activity",
			"duration": 4.0
		}
	}
	
	# Verify complete setup
	assert_eq(music.vertical_layers.size(), 6)
	assert_eq(music.triggers.size(), 5)
	
	# Check dawn trigger for gradual morning transition
	assert_eq(music.triggers[&"dawn"]["duration"], 10.0)
	
	# Check dusk has even longer transition
	assert_eq(music.triggers[&"dusk"]["duration"], 15.0)
	
	gut.p("Complete farm music system configured with %d layers and %d triggers" % 
		[music.vertical_layers.size(), music.triggers.size()])
