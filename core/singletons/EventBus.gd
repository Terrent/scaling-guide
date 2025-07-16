# core/singletons/EventBus.gd
# A global, autoloaded singleton for decoupled signal-based communication.
# Adheres to a strict naming convention to differentiate server and client-side scope.
extends Node


## SERVER-SIDE SIGNALS (Emitted and consumed ONLY on the server instance)
# These signals relate exclusively to the authoritative game logic.

# Emitted at the end of the day sequence, after the atomic save has successfully completed.
signal server_day_passed(day_number: int)
# Emitted when a player successfully completes an action that grants skill XP.
signal server_player_action_completed(player_id: int, skill_type: StringName, xp_value: int)
# Emitted when an item is successfully crafted by the CraftingManager.
signal server_item_crafted(player_id: int, item_id: StringName, quantity: int)
# Emitted when a player successfully gives a gift to an NPC.
signal server_npc_gifted(player_id: int, npc_id: StringName, item_id: StringName)
# Emitted when an enemy is defeated by a player.
signal server_enemy_defeated(player_id: int, enemy_data: Resource)
# Emitted for the Player-to-Player Trust system when a cooperative action is detected.
signal server_cooperative_action_completed(player1_id: int, player2_id: int, action_type: StringName)
# Emitted by FestivalManager to coordinate world state changes for events.
signal server_festival_state_changed(festival_id: StringName, new_state: int) # Using int for Enum
# Emitted when a player makes a critical, one-time world discovery.
signal server_global_discovery_unlocked(discovery_id: StringName, player_id: int)
# Emitted when a player action contributes to an active community quest.
signal server_community_quest_progress(quest_id: StringName, player_id: int, contribution_data: Dictionary)
# Emitted when a community quest's global objectives are met.
signal server_community_quest_completed(quest_id: StringName)
# Emitted when a player is assigned a room in the Barracks for the first time.
signal server_player_assigned_room(player_id: int, room_id: int)


## CLIENT-SIDE SIGNALS (Emitted and consumed ONLY on client instances)
# These signals primarily relate to UI updates and local feedback.

# Emitted on a client when its authoritative data has been updated by the server.
signal client_player_data_updated(player_data: Dictionary)
# Emitted on a client when its inventory has been changed by the server.
signal client_inventory_changed
# Emitted on a client when its quest log has been changed by the server.
signal client_quest_log_updated
# Emitted on a client to open the dialogue box with specific content.
signal client_dialogue_started(dialogue_data: Resource)
# Emitted on a client to close the dialogue box.
signal client_dialogue_ended
