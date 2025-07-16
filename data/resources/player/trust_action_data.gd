# data/resources/player/trust_action_data.gd
# Defines the trust value gained for a specific cooperative player action.
class_name TrustActionData
extends Resource

# A unique identifier for the cooperative action (e.g., water_other_player_crop).
@export var action_type: StringName = &""

# The amount of Trust gained between the two players for completing this action.
@export var trust_value: int = 1

# The cooldown in in-game hours before this action can grant Trust again between the same two players.
@export var cooldown_hours: int = 24
