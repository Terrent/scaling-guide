# data/resources/enemies/enemy_data.gd
# A data container that informs other game systems about an enemy's attributes.
# It is passed via the server_enemy_defeated signal.
class_name EnemyData
extends Resource

@export var enemy_id: StringName = &""
@export var display_name: String = ""
@export var health: int = 10
@export var damage: int = 1
@export var xp_value: int = 5

# A dictionary defining potential item drops and their probabilities.
# Key: item_id (StringName), Value: drop_chance (float, 0.0 to 1.0).
@export var loot_table: Dictionary
