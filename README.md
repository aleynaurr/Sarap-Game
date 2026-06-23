# Kusina Mama 🍳
*A Filipino Cooking Game — Cooking Mama gameplay meets Overcooked-style kitchen navigation*

## How to Run
1. Install **Godot Engine 4.2+** (standard, not .NET build) from https://godotengine.org
2. Open Godot → "Import" → select the `project.godot` file in this folder
3. Press **F5** (or the Play button) to run. Main scene is `scenes/MainMenu.tscn`.

## Controls
| Action | Key |
|---|---|
| Move | `W` `A` `S` `D` |
| Interact / Enter Minigame | `E` |
| Minigame actions | `SPACE` / `E` / arrow-equivalents (`WASD`) / `1` `2` `3` (plating) |
| Quit to recipe select (in-kitchen) | `ESC` |

## Gameplay Loop
1. **Main Menu** → Play → **Recipe Select**: choose one of 5 Filipino dishes.
2. **Kitchen** (Overcooked-style top-down room): walk with WASD between 5 stations:
   - **Sink** (top-left) — wash ingredients
   - **Chopping Board** (top-middle) — chop / mince
   - **Frying Pan** (top-right) — fry
   - **Cooking Pot** (right side) — simmer / boil
   - **Work Table** (bottom) — crack eggs, mix, roll, plate
3. Walking near a station with a pending step shows a **floating "E" key prompt**. Press `E` to enter the **Cooking-Mama-style minigame** for that step.
4. Each minigame is skill-based (timing, rhythm, accuracy) and contributes to that step's score.
5. Complete all steps before the **5-minute recipe timer** runs out.
6. **Results screen**: shows total score, letter grade (S/A/B/C/D), 0–3 stars, and a per-step breakdown.

## Recipes & Their Steps
- **Tortang Talong** — Wash → Grill/Peel Eggplant → Crack & Beat Eggs → Fry → Plate
- **Lumpiang Shanghai** — Wash Veggies → Mince Filling → Mix → Roll → Deep Fry
- **Sinigang na Baboy** — Wash Pork → Chop Veggies → Boil Pork → Add Tamarind/Veggies → Plate
- **Kaldereta** — Wash Beef → Chop Veggies → Brown Beef → Sauté Aromatics → Stew → Plate
- **Halo-Halo** — Cook Sweet Beans → Prepare Leche Flan → Shave Ice → Layer Toppings → Add Ice & Milk

## Minigame Types
| Minigame | Mechanic |
|---|---|
| Wash | Alternate ← / → to scrub clean |
| Chop | Tap on the rhythm beat |
| Mince | Rapid-mash for speed |
| Fry | Manage heat (↑/↓), flip at the right doneness |
| Simmer | Hold heat in the sweet spot over time, avoid boil-over |
| Crack Egg | Time a tap to a swinging pendulum for a clean crack |
| Mix | Rotate WASD clockwise (W→D→S→A) repeatedly |
| Roll | Quick-time arrow-key sequence |
| Plate | Place each ingredient in the correct numbered zone |

## Scoring
Each step's score = **60% skill performance + 40% time remaining**, scaled to 100 points/step.
Total recipe score → letter grade and star rating shown on the Results screen.

## Project Structure
```
project.godot              — Godot project config (incl. WASD/E input map)
scenes/                    — MainMenu, RecipeSelect, Kitchen, Results (.tscn)
scripts/
  autoload/                — GameManager, RecipeData, ScoreManager, AudioManager (singletons)
  ui/                      — MainMenu.gd, RecipeSelect.gd, Results.gd
  stations/                — KitchenStation.gd (base class for all 5 stations)
  minigames/               — MinigameBase.gd + 9 minigame implementations
  Player.gd, Kitchen.gd, MinigameHost.gd
assets/sprites/            — All pixel-art PNGs (player, stations, ingredients, tiles, UI)
art_gen/                   — Python/PIL scripts used to generate the pixel art (for reference/regeneration)
```

## Notes
- All art is **original pixel art**, procedurally generated for this project (no external assets).
- No audio files are included; `AudioManager.gd` has named hook functions (`play_sfx`, `play_music`) ready for you to wire up your own sound files later — calls are currently silent no-ops.
- Built for **Godot 4.2+** using GDScript 2.0 syntax.
