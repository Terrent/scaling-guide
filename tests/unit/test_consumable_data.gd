extends GutTest

# Preload the script that defines our test double's structure.
# This gives GUT a concrete blueprint to work with.
const HealthComponentDouble = preload("res://tests/doubles/health_component_double.gd")

# Test subject and doubles
var consumable: ConsumableData
var mock_user: Node
var mock_health_component # This will be a proper GutDouble

func before_each():
	consumable = ConsumableData.new()
	# Use a real Node instead of a double for the user
	mock_user = Node.new()
	mock_user.set_name("MockUser")
	
	# Keep the health component as a double
	mock_health_component = double(HealthComponentDouble).new()
	mock_health_component.set_name("PlayerHealth")
	
	stub(mock_health_component, "heal")
	stub(mock_health_component, "restore_stamina")
	
	# Add to scene tree in the correct order
	add_child_autofree(mock_user)  # Use autofree for automatic cleanup
	mock_user.add_child(mock_health_component)

func after_each():
	remove_child(mock_user)
	mock_user.free()

# This parameterized test runs multiple scenarios through the same logic.
func test_execute_consume_restores_correct_values(params=use_parameters([
	{"health": 25, "stamina": 10},
	{"health": 0, "stamina": 0},
	{"health": 50, "stamina": 0},
	{"health": 0, "stamina": 30}
])):
	# Arrange
	consumable.health_restore = params.health
	consumable.stamina_restore = params.stamina

	# Act
	consumable.execute_consume(mock_user)

	# Assert
	assert_called(mock_health_component, "heal", [params.health])
	assert_called(mock_health_component, "restore_stamina", [params.stamina])
