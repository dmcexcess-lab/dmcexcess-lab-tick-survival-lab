# 14 Canonical Playable Demo Integration

Status: **IMPLEMENTED**

Approved by the user on 2026-08-16 with the explicit request to build the demo as a small sample map containing one controllable survivor and no NPCs.

## 1. Goal

Replace the deprecated Reboot entry point with the smallest real canonical playable build: one survivor can walk and turn around a small authored map using the already-implemented WHERE / WHAT / WHEN, Collision, Movement, Locomotion, Art Catalog, and Ground / Structure / Prop / Living Actor renderers.

This is an integration system. It does not replace or reimplement those owners.

## 2. Player-visible v1

- one 13 x 13 authored sample area;
- one controlled `actor.survivor` and no NPC survivors or infected;
- recovered canonical ground, wall, prop, and player art through the existing renderers;
- forward, backward, turn-left, and turn-right actions;
- keyboard controls: W/Up = forward, S/Down = backward, A/Left = turn left, D/Right = turn right;
- large Godot `Button` controls for touch/Safari using the same semantic intents;
- synchronous turn-based presentation: an accepted intent submits the existing timed Movement action and runs WHEN until the next player decision;
- blocked/invalid actions leave the survivor in place and are reported by the small demo status label.

The full authored area fits inside the 640 x 844 virtual viewport, so v1 deliberately has no camera or zoom owner.

## 3. Authored sample content

`CanonicalDemoFixture` creates real canonical WHAT facts rather than a fake display map.

- every cell in `(0,0)..(12,12)` has terrain;
- default terrain is `ground.grass_lush`;
- row 6 and column 6 use `ground.road`, forming a visible cross-road;
- a small `wall.house` shell sits in the northwest with a walkable gap rather than a fake interactive door;
- a few real OBJECT entities use recovered art: trees, bench, mailbox, and streetlight;
- player begins at `(6,10)`, facing north;
- terrain outside the authored area is absent, therefore existing fail-closed movement naturally prevents leaving the demo map.

Demo collision/traversal configuration is explicit:

- actor, walls, trees, bench, mailbox, and streetlight block movement;
- `ground.grass_lush` and `ground.road` are traversable;
- both use the existing recovered walking baseline of 10 ticks;
- turns retain the existing 3-tick Movement baseline.

## 4. Owners

### `game/scripts/app/CanonicalDemoMain.gd`
Composition/bootstrap only. Constructs canonical state/services, asks the fixture to populate the world, enrolls the player in Locomotion, connects input intents to the player-action coordinator, configures the renderer stack, and prints the canonical boot token.

It owns no map drawing, button geometry, key mapping, collision rule, movement rule, or world-generation logic.

### `game/scripts/demo/CanonicalDemoFixture.gd`
Owns only the authored sample-world fixture and demo-specific static Collision / Traversal registrations.

It is not a procedural generator and does not become persistent-world generation architecture.

### `game/scripts/render/TacticalRendererStack.gd`
Orchestrates the already-implemented render layers only:

`Ground -> Structure -> Prop -> Living Actor`

No new draw implementation or art lookup belongs here. Held-item layers are omitted in v1 because the demo actor has no equipped objects.

### `game/scripts/input/PlayerActionIntent.gd`
Defines the narrow semantic intent vocabulary for this demo slice.

### `game/scripts/input/KeyboardInputAdapter.gd`
Owns keyboard-to-intent translation only.

### `game/scripts/ui/DemoMovementControls.gd`
Owns touch-button/UI geometry and emits the same semantic intents. Uses native Godot Controls/Buttons so no manual Safari touch hit-testing or synthetic mouse compatibility shim is introduced.

### `game/scripts/player/DemoPlayerActionController.gd`
Owns only intent-to-existing-Movement-action coordination. It asks `MovementActionService` to start an action, runs `TickKernel` until the next stop, observes the existing movement committed/failed signals, and reports the result to presentation.

It does not calculate destinations, collision, facing changes, or movement duration.

## 5. Public contracts

### Fixture
- `build(world, world_mutations, collision_catalog, traversal_policy) -> bool`
- constants for map origin/size, player ID, and recovered base walk ticks.

### Renderer stack
- `configure(world, art_catalog, door_state, controlled_actor_id) -> bool`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `layer_command_counts() -> Dictionary` for deterministic integration diagnostics/tests.
- `planned_diagnostic_counts() -> Dictionary` for fixture-level art/presentation validation.

### Input adapters
- signal `action_intent(intent: StringName)`

### Player action controller
- `submit_intent(intent: StringName) -> void`
- signal `action_resolved(intent, success, reason, world_tick)`

## 6. Data ownership / dependencies

The demo reads/writes only through existing public contracts:

- WHAT through `WorldMutationService`;
- Collision through `CollisionCatalog` / `SpatialQueryService`;
- actor stance/capability through System 03;
- movement through System 02;
- time through WHEN;
- presentation through Art Catalog + existing layer renderers.

No canonical production state is copied into a second demo-only truth.

## 7. Forbidden scope

V1 does **not** add:

- NPCs, infected, AI, combat, or perception;
- camera or zoom;
- procedural generation or streaming;
- inventory/item interaction UI;
- Stats/Needs HUD beyond the tiny action/tick feedback label;
- doors/open-close interactions;
- lighting/weather/sound;
- save/load UI;
- new movement or collision semantics;
- temporary adapters into `game/scripts/reboot/`.

The deprecated Reboot scripts remain untouched as recovery/reference code, but `main.tscn` no longer launches them.

## 8. Safari/mobile

- use normal Godot `Button` controls;
- each press emits exactly one semantic intent;
- buttons have keyboard focus disabled so keyboard and touch paths do not fight;
- no hover requirement;
- no manual touch rectangle or synthetic mouse/touch duplication logic;
- virtual viewport remains 640 x 844 with the authored map above the controls.

## 9. Acceptance tests

Dedicated demo smoke/CI proves:

1. project parses in Godot 4.7.1;
2. `main.tscn` launches canonical demo code and not `RebootMain.gd`;
3. fixture contains exactly one living actor and it is the controlled survivor;
4. no NPC or infected actor is created;
5. all 169 map cells have real terrain;
6. collision coverage is explicit for every placed STRUCTURE / OBJECT / ACTOR;
7. renderer stack produces 169 ground commands, 11 structure commands, 6 prop commands, and exactly one actor command with zero planned diagnostics;
8. forward movement is accepted, advances WHEN by the recovered 10-tick walking duration, and commits `(6,10) -> (6,9)`;
9. turn-right uses the existing 3-tick turn duration and commits EAST facing;
10. an authored wall cell is collision-blocked;
11. keyboard/touch owners depend only on semantic intent, not world/movement internals;
12. protected WHAT/WHEN/Collision/Movement/Locomotion/Art/renderer regressions remain green;
13. startup prints `CANONICAL_DEMO_BOOT_OK`;
14. exact-final-SHA Web export and GitHub Pages deploy succeed.

Initial complete integration head `41ccfedd658082f5d249b5107363658705ea4b03` passed dedicated **Canonical Playable Demo contract** run `31993465800` with no production repair after the complete candidate reached CI. Final promotion-head validation is recorded by the exact-SHA workflow runs.

## 10. Future seams

This integration intentionally leaves room to add, independently:

- a real tactical camera/zoom owner when the world view exceeds one screen;
- the already-planned `Looking at:` / Stats / Inventory / Menu UI;
- held-item visuals by inserting existing System 10 BACK/FRONT layers;
- authored or generated larger world content without rewriting Movement or render layers;
- mobile lifecycle hard-pause handling.

## 11. North-star fit

The demo proves the actual architectural spine of **Ultima-style turn-based mini Zomboid** instead of preserving a visually playable deprecated runtime. The scope is intentionally tiny, but every visible movement and map fact is owned by the real canonical systems.