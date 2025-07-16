extends GutTest

# Example of a more complex integration test

func test_consumable_with_configured_values():
	var health_potion = ConsumableData.new()
	health_potion.item_id = &"health_potion"
	health_potion.display_name = "Health Potion"
	health_potion.description = "Restores 25 HP"
	health_potion.stack_size = 10
	health_potion.value = 50
	health_potion.health_restore = 25
	health_potion.stamina_restore = 0
	
	# Test that it maintains ItemData properties
	assert_eq(health_potion.display_name, "Health Potion")
	assert_eq(health_potion.stack_size, 10)
	
	# Test ConsumableData specific properties  
	assert_eq(health_potion.health_restore, 25)
	assert_eq(health_potion.stamina_restore, 0)
	
	# Test execution
	var mock_user = Node.new()
	mock_user.set_name("TestPlayer")
	
	var mock_health = double(preload("res://tests/doubles/health_component_double.gd")).new()
	mock_health.set_name("PlayerHealth")
	stub(mock_health, "heal")
	stub(mock_health, "restore_stamina")
	
	add_child_autofree(mock_user)
	mock_user.add_child(mock_health)
	
	health_potion.execute_consume(mock_user)
	
	assert_called(mock_health, "heal", [25])
	assert_called(mock_health, "restore_stamina", [0])
