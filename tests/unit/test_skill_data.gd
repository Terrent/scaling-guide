# tests/unit/test_skill_data.gd
extends GutTest

var skill: SkillData

func before_each():
	skill = SkillData.new()

func test_default_values():
	assert_eq(skill.skill_id, &"")
	assert_eq(skill.display_name, "")
	assert_eq(skill.xp_per_level.size(), 0)
	assert_eq(skill.professions.size(), 0)

func test_basic_skill_setup():
	skill.skill_id = &"farming"
	skill.display_name = "Farming"
	
	assert_eq(skill.skill_id, &"farming")
	assert_eq(skill.display_name, "Farming")

func test_xp_progression_curve():
	# Typical exponential progression
	skill.xp_per_level = [
		100,    # Level 1
		200,    # Level 2  
		350,    # Level 3
		550,    # Level 4
		800,    # Level 5 (profession choice!)
		1100,   # Level 6
		1500,   # Level 7
		2000,   # Level 8
		2600,   # Level 9
		3300    # Level 10 (second profession choice!)
	]
	
	assert_eq(skill.xp_per_level.size(), 10)
	assert_eq(skill.xp_per_level[0], 100)  # Level 1 is easy
	assert_eq(skill.xp_per_level[9], 3300) # Level 10 is hard
	
	# Verify progression gets harder
	for i in range(1, skill.xp_per_level.size()):
		assert_gt(skill.xp_per_level[i], skill.xp_per_level[i-1], 
			"XP requirement should increase each level")

func test_profession_choices():
	# Farming skill professions (Stardew Valley style)
	skill.professions = {
		5: [&"rancher", &"tiller"],           # Level 5 choice
		10: {                                 # Level 10 choices depend on level 5
			&"rancher": [&"coopmaster", &"shepherd"],
			&"tiller": [&"artisan", &"agriculturist"]
		}
	}
	
	# Check level 5 professions
	assert_has(skill.professions, 5)
	var level_5_choices = skill.professions[5]
	assert_eq(level_5_choices.size(), 2)
	assert_has(level_5_choices, &"rancher")
	assert_has(level_5_choices, &"tiller")
	
	# Check level 10 professions
	assert_has(skill.professions, 10)
	var level_10_choices = skill.professions[10]
	assert_has(level_10_choices, &"rancher")
	assert_has(level_10_choices, &"tiller")

func test_combat_skill_professions():
	skill.skill_id = &"combat"
	skill.display_name = "Combat"
	
	skill.professions = {
		5: [&"fighter", &"scout"],
		10: {
			&"fighter": [&"brute", &"defender"],
			&"scout": [&"acrobat", &"desperado"]
		}
	}
	
	# Test fighter path
	var fighter_level_10 = skill.professions[10][&"fighter"]
	assert_has(fighter_level_10, &"brute")
	assert_has(fighter_level_10, &"defender")
	
	# Test scout path
	var scout_level_10 = skill.professions[10][&"scout"]
	assert_has(scout_level_10, &"acrobat")
	assert_has(scout_level_10, &"desperado")

func test_mining_skill_complete():
	skill.skill_id = &"mining"
	skill.display_name = "Mining"
	
	# Slower early progression, faster later
	skill.xp_per_level = [
		50,     # Level 1 - Find your first ore
		150,    # Level 2
		300,    # Level 3
		500,    # Level 4
		750,    # Level 5 - Profession choice
		1050,   # Level 6
		1400,   # Level 7
		1800,   # Level 8
		2250,   # Level 9
		2750    # Level 10 - Specialization
	]
	
	skill.professions = {
		5: [&"miner", &"geologist"],
		10: {
			&"miner": [&"blacksmith", &"prospector"],
			&"geologist": [&"excavator", &"gemologist"]
		}
	}
	
	# Calculate total XP for max level
	var total_xp = 0
	for xp in skill.xp_per_level:
		total_xp += xp
	
	gut.p("Total XP to max Mining: %d" % total_xp)
	assert_eq(total_xp, 11000)  # Fixed: 50+150+300+500+750+1050+1400+1800+2250+2750 = 11000


func test_skill_without_professions():
	# Some skills might not have profession choices
	skill.skill_id = &"luck"
	skill.display_name = "Luck"
	skill.xp_per_level = [100, 250, 450, 700, 1000]
	skill.professions = {}  # No professions
	
	assert_eq(skill.professions.size(), 0)
	assert_eq(skill.xp_per_level.size(), 5)  # Only 5 levels

func test_calculate_level_from_xp():
	# Helper function to determine current level from XP
	skill.xp_per_level = [100, 200, 350, 550, 800]
	
	# Test cases: [current_xp, expected_level]
	var test_cases = [
		[0, 0],      # No XP = Level 0
		[50, 0],     # Not enough for level 1
		[100, 1],    # Exactly level 1
		[150, 1],    # Between 1 and 2
		[300, 2],    # Exactly level 2 (100 + 200)
		[650, 3],    # Exactly level 3 (100 + 200 + 350)
		[1199, 3],   # Almost level 4
		[1200, 4],   # Exactly level 4 (100 + 200 + 350 + 550)
		[1999, 4],   # Almost level 5
		[2000, 5]    # Max level (100 + 200 + 350 + 550 + 800 = 2000)
	]
	
	for test in test_cases:
		var xp = test[0]
		var expected_level = test[1]
		var calculated_level = _calculate_level(skill, xp)
		assert_eq(calculated_level, expected_level, 
			"XP %d should be level %d" % [xp, expected_level])

# Helper function for level calculation
func _calculate_level(skill_data: SkillData, current_xp: int) -> int:
	var total_required = 0
	var level = 0
	
	for i in range(skill_data.xp_per_level.size()):
		total_required += skill_data.xp_per_level[i]
		if current_xp >= total_required:
			level = i + 1
		else:
			break
	
	return level

func test_foraging_skill_unique_professions():
	skill.skill_id = &"foraging"
	skill.display_name = "Foraging"
	
	skill.professions = {
		5: [&"forester", &"gatherer"],
		10: {
			&"forester": [&"lumberjack", &"tapper"],
			&"gatherer": [&"botanist", &"tracker"]
		}
	}
	
	# Verify unique profession names
	var all_professions = []
	all_professions.append_array(skill.professions[5])
	
	for prof_list in skill.professions[10].values():
		all_professions.append_array(prof_list)
	
	# Check no duplicates
	var unique_professions = {}
	for prof in all_professions:
		assert_does_not_have(unique_professions, prof, "Duplicate profession found")
		unique_professions[prof] = true

func test_social_skill_different_progression():
	# Social skill might have different progression
	skill.skill_id = &"social"
	skill.display_name = "Charisma"
	
	# Easier progression for social skill
	skill.xp_per_level = [
		50,   # Level 1 - First friend
		100,  # Level 2
		175,  # Level 3
		275,  # Level 4
		400,  # Level 5 - Profession
		550,  # Level 6
		725,  # Level 7
		925,  # Level 8
		1150, # Level 9
		1400  # Level 10 - Specialization
	]
	
	skill.professions = {
		5: [&"friendly", &"charming"],
		10: {
			&"friendly": [&"popular", &"beloved"],
			&"charming": [&"romantic", &"persuasive"]
		}
	}
	
	# Social progression should be easier than combat
	var combat_level_5 = 800  # From earlier test
	var social_level_5 = skill.xp_per_level[4]
	assert_lt(social_level_5, combat_level_5, "Social should be easier to level")

# Parameterized test for all skills
func test_all_game_skills(params=use_parameters([
	{
		"id": &"farming",
		"name": "Farming",
		"level_5_profs": [&"rancher", &"tiller"],
		"total_levels": 10
	},
	{
		"id": &"mining",
		"name": "Mining", 
		"level_5_profs": [&"miner", &"geologist"],
		"total_levels": 10
	},
	{
		"id": &"combat",
		"name": "Combat",
		"level_5_profs": [&"fighter", &"scout"],
		"total_levels": 10
	},
	{
		"id": &"fishing",
		"name": "Fishing",
		"level_5_profs": [&"fisher", &"trapper"],
		"total_levels": 10
	},
	{
		"id": &"foraging",
		"name": "Foraging",
		"level_5_profs": [&"forester", &"gatherer"],
		"total_levels": 10
	}
])):
	skill.skill_id = params.id
	skill.display_name = params.name
	
	# Set up XP curve
	skill.xp_per_level = []
	for i in range(params.total_levels):
		skill.xp_per_level.append((i + 1) * 100 * (i + 1) / 2)
	
	# Set up professions
	skill.professions = {
		5: params.level_5_profs
	}
	
	gut.p("%s skill: %d levels, professions at level 5: %s" % 
		[params.name, params.total_levels, params.level_5_profs])
	
	assert_eq(skill.skill_id, params.id)
	assert_eq(skill.xp_per_level.size(), params.total_levels)
	assert_eq(skill.professions[5], params.level_5_profs)

func test_xp_curve_comparison():
	# Compare different XP curves
	var linear_curve = []
	var quadratic_curve = []
	var exponential_curve = []
	
	for i in range(10):
		linear_curve.append((i + 1) * 100)              # 100, 200, 300...
		quadratic_curve.append((i + 1) * (i + 1) * 50)  # 50, 200, 450...
		exponential_curve.append(int(100 * pow(1.5, i))) # 100, 150, 225...
	
	# Test that curves have expected properties
	gut.p("Level 10 XP requirements:")
	gut.p("  Linear: %d" % linear_curve[9])
	gut.p("  Quadratic: %d" % quadratic_curve[9])
	gut.p("  Exponential: %d" % exponential_curve[9])
	
	assert_lt(linear_curve[9], quadratic_curve[9])
	assert_lt(linear_curve[9], exponential_curve[9])
