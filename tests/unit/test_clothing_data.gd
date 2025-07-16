extends GutTest

var clothing: ClothingData

func before_each():
	clothing = ClothingData.new()

func test_equip_slot_enum():
	clothing.equip_slot = ClothingData.EquipSlot.HAT
	assert_eq(clothing.equip_slot, ClothingData.EquipSlot.HAT)
	
	clothing.equip_slot = ClothingData.EquipSlot.PANTS
	assert_eq(clothing.equip_slot, ClothingData.EquipSlot.PANTS)

func test_sprite_sheets_dictionary():
	var test_texture = preload("res://icon.svg")
	clothing.sprite_sheets = {
		"HatSprite": test_texture,
		"HairSprite": null  # Some clothes might hide hair
	}
	
	assert_eq(clothing.sprite_sheets["HatSprite"], test_texture)
	assert_null(clothing.sprite_sheets["HairSprite"])

func test_inherits_item_data_properties():
	clothing.display_name = "Straw Hat"
	clothing.value = 100
	assert_eq(clothing.display_name, "Straw Hat")
	assert_eq(clothing.value, 100)
