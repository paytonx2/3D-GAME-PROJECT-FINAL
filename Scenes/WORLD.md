# World (Just go up!!)

Flow: F5 → `main_menu.tscn` (poster `Assets/BUTTON/Just_GO_UP.png` + image buttons) → **START** → `story.tscn` (Space/click = next, Esc = skip) → `world.tscn`.
**CONTINUE** resumes at the last Uncle Oli save point (saved to `user://save.cfg`, cleared by START or by finishing). **OPTION** = volume, mouse sensitivity, fullscreen and controls (`user://settings.cfg`). `StartButtonHOVER_alpha.png` is a copy of `StartButtonHOVER.png` with its baked-in checkerboard removed.

## Layout

| Zone | Height | Look | Climbable objects |
|---|---|---|---|
| Start (Earth) | 0 m | KayKit City Builder plaza on a wide green ground | parked taxi |
| 1 · เมืองลอยฟ้า | 0–75 m | clear blue sky | cars, pipes, tables, sofa, train, building, tank |
| 2 · ทะเลเมฆ | 75–147 m | sunset clouds, pink fog | cloud puffs plus town objects |
| 3 · ห้วงอวกาศ | 147–222 m | black sky, star field | asteroids, saucers, spaceships, pipes, cars – all floating; planets/moon are fixed backdrop |
| Summit | 222 m | – | Star of Wishes + Star Keeper (`Assets/model/StarKeeper`) → ending and credits |

50 generated main steps per zone (153 in `Platforms`) plus about 77 side stones in `SidePlatforms`: they sit left, right, behind or diagonally off the main path (sometimes two in a row) and each jumps on to a main step 1–2 ahead, so there are several ways up and some steps can be skipped. Objects face random directions; gaps are computed along the real jump direction including the space a moving object sweeps, so nothing moving hits its neighbours. Train 12 m. Floating objects lean a few degrees (edges rise at most `TILT_EDGE`), unrelated objects keep `SPACING` of air, and the route starts at the plaza's north road so it never cuts through the plaza buildings. The tank and motorcycle are scenery only (Aof could get stuck on them); a crate replaces them. Flips take 2.4–3.2 s with a sine ease. Identical objects share one collision shape. Non-solid scenery: floating city islands, tumbling junk (cars, sofas, trains), clouds, and space rocks/ships/planets. Motion gets more frequent and harder further into each zone: slide, bob, spin, orbit, seesaw (`rock`), and `flip` (rests ~3 s, then somersaults 360° and throws Aof off). Space objects float and many also seesaw or flip.

Each zone has one save point: Uncle Oli greets Aof and saves when Aof stands next to him. Falling 14 m below the active save point (or pressing R) returns Aof there. Every main step rises 1.2–1.9 m, so most jumps need a double or triple jump. The third chained jump plays a somersault. The food pickups (Kenney Food Kit) give ×1.35 jump power for 10 s, then grow back after 20 s.

## Regenerating

The layout is generated in `build()` / `build_side_routes()` / `pick_motion()` in `tools/build_world.gd` from `KINDS` and `STEPS_PER_ZONE` (fixed seeds, so rebuilds are identical); zone texts live in `ZONES`. Regenerating replaces direct edits to `world.tscn`:

    godot --headless --path . --script res://tools/build_world.gd

`tests/world_layout.json` records every platform. Runtime behaviour: `Scripts/World.gd` (HUD, save points, zone atmosphere, pause, ending), `MovingPlatform.gd`, `FoodPickup.gd`, `OliCheckpoint.gd`, `WishStar.gd`. Menu, story and credits: `MainMenu.gd`, `StoryIntro.gd`, `UiKit.gd` (team list in `UiKit.TEAM`).

## Tests

    godot --headless --path . --scene res://tests/world_test.tscn
    godot --headless --path . --script res://tests/menu_flow_test.gd

`world_test` simulates Aof's real capsule and movement on every main step and on every side stone (getting on and jumping back to the main path), with moving platforms frozen at their placed pose and without food. It also checks the save points, falling, food, the 3rd-jump somersault and the ending. Screenshots for visual review: `tools/screenshot_world.gd` and `tools/screenshot_ui.gd` (run without `--headless`, pass an output folder after `--`).

## Admin fly mode (for demos)

In game press **Insert** to toggle No Clip: WASD flies where the camera looks, Space up, Ctrl (or C) down, Shift fast, keys **1–3** jump to each zone's Uncle Oli and **4** to the summit. Falls are not counted while flying and save points do not trigger.

## Repairing jumps after a test run

`world_test` writes `tests/world_failures.json`. Put the failing main steps into `tests/world_fixes.json` under `rise_cut` (metres to lower that step; it also shortens its gap) and rebuild — this shifts the layout above it, so test again. Failing side stones can be listed under `drop_side`; they are removed after generation, so nothing else changes.

## Pause menu

Esc opens the PAUSED panel built from `Assets/Paused Button/` (Resume, Restart Checkpoint, Setting, Main Menu). The button images are normalized copies in `Assets/Paused Button/ui/` (all 672×148, `_hover` = selected), so every button is the same size and only the selected one is highlighted.
