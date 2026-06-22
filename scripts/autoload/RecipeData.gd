extends Node

# Each recipe has:
#   id, display_name, description, icon_ingredient (for menu thumbnail)
#   steps: Array of { id, name, station, minigame, ingredients, instruction, time_limit }
#   Stations: "sink", "chopping", "frying", "cooking", "working"
#   Minigames: "wash", "chop", "mince", "fry", "simmer", "crack_egg", "mix", "roll", "plate"

const RECIPES: Dictionary = {

# ─────────────────────────────────────────────────────────────────────────────
"tortang_talong": {
	"id": "tortang_talong",
	"display_name": "Tortang Talong",
	"tagalog_name": "Tortang Talong",
	"description": "Grilled eggplant omelette – a Filipino breakfast favourite!\nSmoke the talong, peel it, then fry with beaten egg.",
	"icon": "icon_eggplant",
	"color": "7a3278",
	"region": "luzon",
	"steps": [
		{
			"id": "wash_talong",
			"name": "Wash the Eggplant",
			"station": "sink",
			"minigame": "wash",
			"ingredients": ["icon_eggplant"],
			"instruction": "Rinse the eggplant under the tap!\nSwipe left-right to scrub it clean.",
			"time_limit": 20.0,
			"required": true
		},
		{
			"id": "grill_talong",
			"name": "Grill & Peel Eggplant",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_eggplant"],
			"instruction": "Hold the eggplant over the flame!\nKeep the bar in the sweet spot to char it evenly.",
			"time_limit": 25.0,
			"required": true
		},
		{
			"id": "crack_eggs",
			"name": "Crack & Beat Eggs",
			"station": "working",
			"minigame": "crack_egg",
			"ingredients": ["icon_egg", "icon_garlic", "icon_onion"],
			"instruction": "Crack the eggs into the bowl – don't break the yolk!\nThen beat with garlic and onion.",
			"time_limit": 22.0,
			"required": true
		},
		{
			"id": "fry_torta",
			"name": "Fry the Torta",
			"station": "frying",
			"minigame": "fry",
			"ingredients": ["icon_eggplant", "icon_egg"],
			"instruction": "Pour the egg over the eggplant and fry!\nFlip at the right time for a golden omelette.",
			"time_limit": 30.0,
			"required": true
		},
		{
			"id": "plate_torta",
			"name": "Plate the Dish",
			"station": "working",
			"minigame": "plate",
			"ingredients": ["icon_tomato", "icon_cheese"],
			"instruction": "Arrange the torta neatly on the plate!\nDrag ingredients into the correct zones.",
			"time_limit": 15.0,
			"required": true
		}
	]
},

# ─────────────────────────────────────────────────────────────────────────────
"lumpiang_shanghai": {
	"id": "lumpiang_shanghai",
	"display_name": "Lumpiang Shanghai",
	"tagalog_name": "Lumpiang Shanghai",
	"description": "Crispy Filipino spring rolls filled with seasoned ground pork!\nRoll them tight and fry golden.",
	"icon": "icon_lumpia_fried",
	"color": "b56a2a",
	"region": "luzon",
	"steps": [
		{
			"id": "wash_veggies",
			"name": "Wash Vegetables",
			"station": "sink",
			"minigame": "wash",
			"ingredients": ["icon_carrot", "icon_onion", "icon_garlic"],
			"instruction": "Scrub the veggies under the tap!\nSwipe to clean each one.",
			"time_limit": 18.0,
			"required": true
		},
		{
			"id": "mince_filling",
			"name": "Mince & Mix Filling",
			"station": "chopping",
			"minigame": "mince",
			"ingredients": ["icon_carrot", "icon_onion", "icon_garlic", "icon_pork"],
			"instruction": "Mince the veggies finely!\nTap rapidly to chop – the faster the better!",
			"time_limit": 28.0,
			"required": true
		},
		{
			"id": "mix_filling",
			"name": "Season & Mix",
			"station": "working",
			"minigame": "mix",
			"ingredients": ["icon_pork", "icon_egg"],
			"instruction": "Mix the pork filling with egg and seasoning!\nRotate the bowl in circles to combine.",
			"time_limit": 20.0,
			"required": true
		},
		{
			"id": "roll_lumpia",
			"name": "Roll the Lumpia",
			"station": "working",
			"minigame": "roll",
			"ingredients": ["icon_lumpia_wrapper"],
			"instruction": "Place filling on the wrapper and roll tight!\nFollow the arrow prompts to roll perfectly.",
			"time_limit": 35.0,
			"required": true
		},
		{
			"id": "fry_lumpia",
			"name": "Deep Fry",
			"station": "frying",
			"minigame": "fry",
			"ingredients": ["icon_lumpia_rolled"],
			"instruction": "Fry the lumpia until golden and crispy!\nKeep the heat in the right zone.",
			"time_limit": 30.0,
			"required": true
		}
	]
},

# ─────────────────────────────────────────────────────────────────────────────
"sinigang_na_baboy": {
	"id": "sinigang_na_baboy",
	"display_name": "Sinigang na Baboy",
	"tagalog_name": "Sinigang na Baboy",
	"description": "Sour tamarind pork soup – the ultimate Filipino comfort dish!\nSour, savory, and loaded with vegetables.",
	"icon": "icon_tamarind",
	"color": "2d6e38",
	"region": "visayas",
	"steps": [
		{
			"id": "wash_pork",
			"name": "Wash the Pork",
			"station": "sink",
			"minigame": "wash",
			"ingredients": ["icon_pork"],
			"instruction": "Rinse the pork ribs under cold water!\nScrub to remove blood and impurities.",
			"time_limit": 18.0,
			"required": true
		},
		{
			"id": "chop_veggies",
			"name": "Chop Vegetables",
			"station": "chopping",
			"minigame": "chop",
			"ingredients": ["icon_radish", "icon_kangkong", "icon_tomato", "icon_onion"],
			"instruction": "Chop the vegetables into big pieces!\nTime your knife strikes on the beat.",
			"time_limit": 25.0,
			"required": true
		},
		{
			"id": "boil_pork",
			"name": "Boil the Pork",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_pork", "icon_onion", "icon_tomato"],
			"instruction": "Bring the pork to a boil, then simmer!\nKeep the heat steady – don't let it overflow.",
			"time_limit": 40.0,
			"required": true
		},
		{
			"id": "add_tamarind",
			"name": "Add Tamarind & Veggies",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_tamarind", "icon_radish", "icon_kangkong"],
			"instruction": "Add tamarind broth and vegetables!\nAdjust heat to keep a gentle simmer.",
			"time_limit": 30.0,
			"required": true
		},
		{
			"id": "plate_sinigang",
			"name": "Serve in a Bowl",
			"station": "working",
			"minigame": "plate",
			"ingredients": ["icon_kangkong", "icon_chili"],
			"instruction": "Ladle the sinigang into a bowl!\nDrag items into the right positions.",
			"time_limit": 12.0,
			"required": true
		}
	]
},

# ─────────────────────────────────────────────────────────────────────────────
"kaldereta": {
	"id": "kaldereta",
	"display_name": "Kaldereta",
	"tagalog_name": "Kaldereta",
	"description": "Rich Filipino beef stew with liver sauce and vegetables!\nHearty, spicy, and perfect with rice.",
	"icon": "icon_beef_cube",
	"color": "8c3030",
	"region": "mindanao",
	"steps": [
		{
			"id": "wash_beef",
			"name": "Wash & Dry Beef",
			"station": "sink",
			"minigame": "wash",
			"ingredients": ["icon_beef_cube"],
			"instruction": "Rinse the beef chunks clean!\nSwipe to scrub off any bone fragments.",
			"time_limit": 18.0,
			"required": true
		},
		{
			"id": "chop_kaldereta",
			"name": "Chop Vegetables",
			"station": "chopping",
			"minigame": "chop",
			"ingredients": ["icon_potato", "icon_carrot", "icon_bellpepper", "icon_onion", "icon_garlic"],
			"instruction": "Chop the potatoes, carrots, and bell peppers!\nBig chunks – this is a hearty stew.",
			"time_limit": 28.0,
			"required": true
		},
		{
			"id": "brown_beef",
			"name": "Brown the Beef",
			"station": "frying",
			"minigame": "fry",
			"ingredients": ["icon_beef_cube"],
			"instruction": "Sear the beef until browned on all sides!\nFlip at the right moment.",
			"time_limit": 30.0,
			"required": true
		},
		{
			"id": "saute_aromatics",
			"name": "Sauté Aromatics",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_garlic", "icon_onion", "icon_tomato"],
			"instruction": "Sauté garlic, onion, and tomatoes!\nKeep stirring so nothing burns.",
			"time_limit": 22.0,
			"required": true
		},
		{
			"id": "stew_kaldereta",
			"name": "Stew Everything",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_beef_cube", "icon_liver_sauce", "icon_potato", "icon_carrot"],
			"instruction": "Add beef, liver sauce, and vegetables!\nSimmer until the beef is tender.",
			"time_limit": 45.0,
			"required": true
		},
		{
			"id": "plate_kaldereta",
			"name": "Plate the Kaldereta",
			"station": "working",
			"minigame": "plate",
			"ingredients": ["icon_bellpepper", "icon_cheese"],
			"instruction": "Top with bell pepper and grated cheese!\nArrange beautifully on the plate.",
			"time_limit": 15.0,
			"required": true
		}
	]
},

# ─────────────────────────────────────────────────────────────────────────────
"halo_halo": {
	"id": "halo_halo",
	"display_name": "Halo-Halo",
	"tagalog_name": "Halo-Halo",
	"description": "The king of Filipino desserts!\nShaved ice with sweet toppings, ube, and leche flan.",
	"icon": "icon_halohalo_glass",
	"color": "8844aa",
	"region": "mindanao",
	"steps": [
		{
			"id": "cook_beans",
			"name": "Cook Sweet Beans",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_sweet_beans"],
			"instruction": "Simmer the sweet beans until soft!\nKeep the heat low and steady.",
			"time_limit": 30.0,
			"required": true
		},
		{
			"id": "make_leche_flan",
			"name": "Prepare Leche Flan",
			"station": "working",
			"minigame": "crack_egg",
			"ingredients": ["icon_egg", "icon_leche_flan"],
			"instruction": "Crack eggs for the leche flan mix!\nCareful – don't get any shell in the bowl.",
			"time_limit": 22.0,
			"required": true
		},
		{
			"id": "shave_ice",
			"name": "Shave the Ice",
			"station": "chopping",
			"minigame": "chop",
			"ingredients": ["icon_ice"],
			"instruction": "Shave the ice block into fine flakes!\nStrike rhythmically for perfect shaved ice.",
			"time_limit": 25.0,
			"required": true
		},
		{
			"id": "mix_halo",
			"name": "Layer Toppings",
			"station": "working",
			"minigame": "mix",
			"ingredients": ["icon_sweet_beans", "icon_jackfruit", "icon_ube", "icon_pinipig"],
			"instruction": "Layer toppings into the glass!\nDrag each topping into the right zone.",
			"time_limit": 28.0,
			"required": true
		},
		{
			"id": "add_ice_milk",
			"name": "Add Ice & Pour Milk",
			"station": "working",
			"minigame": "plate",
			"ingredients": ["icon_ice", "icon_milk_splash", "icon_ube", "icon_leche_flan"],
			"instruction": "Pile the shaved ice high and pour milk!\nTop with ube ice cream and leche flan.",
			"time_limit": 20.0,
			"required": true
		}
	]
},

# ─────────────────────────────────────────────────────────────────────────────
# KULAWONG TALONG — Luzon
# Steps follow the original minigame-file groupings exactly:
#   Dish1Step1  -> poke skin (Work)
#   Dish1Step2  -> grill + turn over (Cook)
#   Dish1Step3  -> coconut / charcoal / vinegar into bowl (Work, 3 actions)
#   Dish1Step4  -> fan and mix (Work)
#   Dish1Step5  -> strain & transfer (Work)
#   Dish1Step6  -> peel skin (Work)
#   Dish1Step7  -> mash with fork (Work)
#   (mince garlic, slice onion, slice chili) -> (Cutting)
#   Dish1Step9  -> pepper/sugar/garlic/onion/chili into bowl (Work, 5 actions)
#   Dish1Step10 -> mix well (Work)
#   Dish1Step11 -> pour over eggplant (Work)
"kulawong_talong": {
	"id": "kulawong_talong",
	"display_name": "Kulawong Talong",
	"tagalog_name": "Kulawong Talong",
	"description": "A smoky grilled eggplant salad from Luzon!\nCharred talong mashed with toasted coconut, garlic, and chili.",
	"icon": "icon_eggplant",
	"color": "5a7a32",
	"region": "luzon",
	"steps": [
		{
			"id": "poke_eggplant",
			"name": "Poke Skin of Eggplant",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_eggplant"],
			"actions": [
				{"label": "Poke the eggplant skin with a fork", "emoji": "🍆"}
			],
			"instruction": "Poke holes all over the eggplant skin\nso it grills evenly!",
			"time_limit": 12.0,
			"required": true
		},
		{
			"id": "grill_eggplant",
			"name": "Grill Eggplants (Turn Over)",
			"station": "cooking",
			"minigame": "simmer",
			"ingredients": ["icon_eggplant"],
			"instruction": "Grill the eggplants over charcoal!\nKeep the heat steady, then turn them over to char both sides.",
			"time_limit": 25.0,
			"required": true
		},
		{
			"id": "bowl_coconut_charcoal_vinegar",
			"name": "Coconut, Charcoal & Vinegar",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_coconut", "icon_charcoal", "icon_vinegar"],
			"actions": [
				{"label": "Put grated coconut in bowl", "emoji": "🥥"},
				{"label": "Put live charcoal in bowl", "emoji": "🔥"},
				{"label": "Pour vinegar", "emoji": "🍶"}
			],
			"instruction": "Add grated coconut, a piece of live charcoal,\nthen pour vinegar — this gives kulawo its smoky flavor!",
			"time_limit": 22.0,
			"required": true
		},
		{
			"id": "fan_and_mix",
			"name": "Fan and Mix",
			"station": "working",
			"minigame": "mix",
			"ingredients": ["icon_coconut"],
			"instruction": "Fan the charcoal and mix!\nRotate clockwise to stir the smoky coconut mixture.",
			"time_limit": 20.0,
			"required": true
		},
		{
			"id": "strain_transfer",
			"name": "Strain and Transfer to Bowl",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_coconut"],
			"actions": [
				{"label": "Strain the mixture and transfer to a clean bowl", "emoji": "🥣"}
			],
			"instruction": "Strain out the charcoal, then transfer\nthe smoky coconut to a clean bowl.",
			"time_limit": 14.0,
			"required": true
		},
		{
			"id": "peel_eggplant",
			"name": "Peel Skin of Eggplants",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_eggplant"],
			"actions": [
				{"label": "Peel the charred skin off the eggplant", "emoji": "🍆"}
			],
			"instruction": "Peel away the charred skin\nto reveal the soft grilled flesh.",
			"time_limit": 14.0,
			"required": true
		},
		{
			"id": "mash_eggplant",
			"name": "Mash Eggplants with Fork",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_eggplant"],
			"actions": [
				{"label": "Mash the peeled eggplant with a fork", "emoji": "🍆"}
			],
			"instruction": "Mash the grilled eggplant with a fork\nuntil soft and well broken up.",
			"time_limit": 14.0,
			"required": true
		},
		{
			"id": "mince_garlic",
			"name": "Mince Garlic",
			"station": "chopping",
			"minigame": "mince",
			"ingredients": ["icon_garlic"],
			"instruction": "Mince the garlic finely!\nMash rapidly for the best result.",
			"time_limit": 20.0,
			"required": true
		},
		{
			"id": "slice_onion_chili",
			"name": "Slice Onion & Green Chili",
			"station": "chopping",
			"minigame": "chop",
			"ingredients": ["icon_onion", "icon_chili"],
			"instruction": "Slice the onion and green chili!\nTime your knife strikes on the beat.",
			"time_limit": 22.0,
			"required": true
		},
		{
			"id": "bowl_seasonings",
			"name": "Add Seasonings to Bowl",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_chili", "icon_cheese", "icon_garlic", "icon_onion", "icon_chili"],
			"actions": [
				{"label": "Add black pepper", "emoji": "🧂"},
				{"label": "Add white sugar", "emoji": "🍚"},
				{"label": "Add minced garlic", "emoji": "🧄"},
				{"label": "Add sliced onions", "emoji": "🧅"},
				{"label": "Add sliced green chilis", "emoji": "🌶️"}
			],
			"instruction": "Add pepper, sugar, minced garlic,\nsliced onions, and sliced chilis to the bowl!",
			"time_limit": 28.0,
			"required": true
		},
		{
			"id": "mix_well",
			"name": "Mix Well",
			"station": "working",
			"minigame": "mix",
			"ingredients": ["icon_garlic"],
			"instruction": "Mix everything well!\nRotate clockwise until evenly combined.",
			"time_limit": 18.0,
			"required": true
		},
		{
			"id": "pour_over_eggplant",
			"name": "Pour Over Peeled Eggplant",
			"station": "working",
			"minigame": "add_to_bowl",
			"ingredients": ["icon_eggplant"],
			"actions": [
				{"label": "Pour the mixture over the mashed eggplant", "emoji": "🍆"}
			],
			"instruction": "Pour the smoky coconut mixture over\nthe mashed eggplant. Kulawo is ready!",
			"time_limit": 14.0,
			"required": true
		}
	]
}

}  # end RECIPES

const REGIONS: Dictionary = {
	"luzon":    {"name": "Luzon",    "recipe_ids": ["kulawong_talong"]},
	"visayas":  {"name": "Visayas",  "recipe_ids": ["sinigang_na_baboy"]},
	"mindanao": {"name": "Mindanao", "recipe_ids": ["kaldereta"]},
}

# ─── API ──────────────────────────────────────────────────────────────────────
func get_recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})

func get_all_recipes() -> Array:
	return RECIPES.values()

func get_step(recipe_id: String, step_index: int) -> Dictionary:
	var recipe = get_recipe(recipe_id)
	var steps = recipe.get("steps", [])
	if step_index < steps.size():
		return steps[step_index]
	return {}

func get_all_regions() -> Array:
	return ["luzon", "visayas", "mindanao"]

func get_region_info(region_id: String) -> Dictionary:
	return REGIONS.get(region_id, {})

func get_recipes_for_region(region_id: String) -> Array:
	var info = get_region_info(region_id)
	var ids = info.get("recipe_ids", [])
	var result = []
	for id in ids:
		var r = get_recipe(id)
		if not r.is_empty():
			result.append(r)
	return result
