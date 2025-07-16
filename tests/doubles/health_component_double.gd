# This script defines the shape of our fake health component.
# It exists only for testing purposes.
extends Node

# These methods exist so that GUT's `double()` and `stub()` have
# a valid method to hook into. The function bodies do not matter.
func heal(amount):
	pass

func restore_stamina(amount):
	pass
