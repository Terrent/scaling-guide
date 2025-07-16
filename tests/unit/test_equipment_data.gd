extends GutTest

var equipment: EquipmentData

func before_each():
	equipment = EquipmentData.new()

func test_equip_slot_types():
	equipment.equip_slot = EquipmentData.EquipSlot.WEAPON
	assert_eq(equipment.equip_slot, EquipmentData.EquipSlot.WEAPON)
	
	equipment.equip_slot = EquipmentData.EquipSlot.RING_2
	assert_eq(equipment.equip_slot, EquipmentData.EquipSlot.RING_2)

func test_stat_bonuses_dictionary():
	equipment.stat_bonuses = {
		&"attack": 10,
		&"defense": 5,
		&"crit_chance": 0.15
	}
	
	assert_eq(equipment.stat_bonuses[&"attack"], 10)
	assert_eq(equipment.stat_bonuses[&"defense"], 5)
	assert_almost_eq(equipment.stat_bonuses[&"crit_chance"], 0.15, 0.001)
