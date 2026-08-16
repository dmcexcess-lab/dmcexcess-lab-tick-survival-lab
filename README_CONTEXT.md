# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request, not before every edit inside the same coherent batch.

## Identity

Working repo/project name: **Tick Survival Lab**.

GitHub repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

This is an original Godot 4 top-down zombie-apocalypse survival simulation. Project Zomboid is a systemic-scope reference only; do not copy its proprietary code, art, maps, UI, names, text, or content.

First Fire is a same-owner source project. Reusable tactical/physical-world work may be adapted after inspection, but Tick must not inherit First Fire's camp/menu/expedition architecture.

Durable design references: `DESIGN.md`, `ROADMAP.md`, `WORLD_GENERATION.md`, `WORLD_NAVIGATION_AUDIT.md`, `ART_VOCABULARY.md`, `MINI_WORLD_STREETSCAPE_DESIGN.md`, and `FIRST_FIRE_REUSE.md`.

## Current milestone / stage

**Milestone 0.2 — Action Execution Model is complete. Milestone 0.3A — Visual Perception is complete. Milestone 0.3B — Weather Foundation is functionally present. World/navigation is now pivoting to a mini-world architecture: a deterministic 5×5 macro map of local 64×64 regions, with only the current local region rendered tactically. Streetscape/building coherence is v5.**

Canonical source includes authored maps, deterministic 64×64 procedural regions, connected road hierarchy, larger room-aware procedural buildings, spaced parking stalls, a full-screen mini-world map, directional road topology art, performance-bounded local zoom, world/scheduler/player/timing-dummy modules, tactical + clutter + world/building-prop atlases, lighting, perception/fog, silent sound helpers, weather state/VFX, tick-driven calendar/day-night cycle, split dev/in-game HUDs, Safari touch suppression, and deterministic map/region/mini-world/tick/calendar/environment/perception smoke tests.

Ownership:

- `TacticalMapGenerator.gd` — authored initial physical map facts plus the shared ground-query language used by authored and procedural maps.
- `ProceduralRegionGenerator.gd` — deterministic v4 64×64 physical baseline: biome, road, parcel, structure, clutter and initial-light generation using the shared physical map schema.
- `MiniRegionGenerator.gd` — generator v5 orchestration layer for mini-world local regions; wraps v4 and applies the deterministic streetscape/building-family coherence pass.
- `StreetscapePass.gd` — v5 local-generation pass for traffic controls, street furniture, building families, parking-destination repair and door-run sanitation. It owns generation-time coherence only, not runtime simulation.
- `MiniWorldState.gd` — deterministic 5×5 macro region identity, per-region seed, current region coordinate and world-edge travel bounds.
- `LocalWorldState.gd` — mutable local physical facts such as door state/collision.
- `TickScheduler.gd` — authoritative world tick, active action execution, interruption state, actor ordering, and player-ready state.
- `WorldCalendar.gd` — tick-to-clock/date/daylight-phase mapping.
- `PlayerActor.gd` — current player location/facing/movement/stance state, base survivor HUD fields, and timing modifiers.
- `TimingDummy.gd` — autonomous scheduled actor used only for scheduler proof/tests and diagnostics; not zombie AI.
- `TacticalLighting.gd` — dependency-free lighting math adapted from First Fire.
- `TacticalSound.gd` — silent sound/localization helpers adapted from First Fire; propagation is pending.
- `TacticalWeather.gd` — current weather profile, visibility/light/sound-mask hooks, temperature hook, indoor thermal buffer, and wind display helper. It does not yet simulate weather patterns.
- `TacticalTiles.gd` — Tick-native renderer for the restored First Fire tactical atlas plus Tick's clutter, world-art, building-prop, final-environment and independent player-facing assets.
- `TacticalPerception.gd` — LOS, facing cone, opaque geometry, biome-aware ambient-light selection, light/weather integration, visible cells, and remembered fog state.
- `MapPreview.gd` / `MapPreviewPresentation.gd` — development harness/presentation base only.
- `MiniWorldPresentation.gd` — current playable presentation harness: safe local zoom, macro map, region travel orchestration and far-zoom cosmetic LOD. It owns no simulation rule.

## Timing semantics

The control model is **real time with automatic pause**, represented synchronously in the current developer harness while authoritative outcomes remain discrete.

1. `player_ready == true` while waiting for a player choice.
2. A player action begins with explicit cost, start tick, interruption policy, optional phases, and payload.
3. `player_ready == false` while that action executes.
4. Other scheduled actors whose `next_tick` falls inside the action window execute in deterministic order.
5. The world advances to action completion unless interruption policy ends it early.
6. The scheduler auto-returns to `player_ready == true` when the action completes, interrupts, cancels, or hard-fails.

Implemented interruption policies: committed, resumable, canceled, and forced failure. Tie ordering is earliest `next_tick`, then lexical actor ID. Actors scheduled exactly on the player action end tick execute before the player becomes ready.

Region travel through a local edge road is a real movement action and costs movement ticks. Opening/closing the mini-world map costs zero ticks.

## Calendar/day-night semantics

World time advances only from authoritative scheduler ticks through `WorldCalendar.gd`.

Current tuning is **7,200 ticks per 24-hour day**: 5 ticks per displayed minute / 12 displayed seconds per tick. This is a gameplay compression ratio, not a claim that one physical action tick literally equals 12 real seconds. Calendar compression remains tunable independently of action costs.

Daylight phases are tick-driven: night → dawn (05:30) → day (07:00) → dusk (18:30) → night (20:00). Pausing does not advance calendar time. Weather VFX may continue animating while paused because they remain presentation-only.

## Mobile/touch semantics

The logical viewport is 640×844. The touch deck remains:

- left column: intentional empty top slot → `TURN L` → `CROUCH`;
- right column: `FORWARD` → `TURN R` → `BACK`;
- both turn controls share exactly the same Y position and height;
- forward/back preserve facing;
- crouch is a timed stance action;
- plus/minus controls change presentation zoom only;
- `MAP` opens the full-screen mini-world map.

**One physical touch must equal one action.** Mobile Safari may synthesize a mouse click around a touch; `SafariInputGuard.gd` and the local suppression window prevent first-touch and follow-up double-actions. Do not remove these guards or reintroduce double-move / 180-degree-turn behavior.

Map tapping remains available. `MENU`/Escape opens the actual pause menu and Web exit uses same-tab browser navigation.

## Mini-world / map semantics

The player map is **one full-screen mini-world map only**. `MAP` on touch or keyboard `M` opens it.

Bootstrap world scale:

- 5×5 macro regions;
- each region has a deterministic seed and broad identity: downtown, commercial, residential, rural, or woods;
- the center is downtown and all five identities are guaranteed somewhere in each new world;
- only the current 64×64 region is generated/rendered in tactical detail;
- the red survivor dot is positioned inside the current macro cell according to current local coordinates;
- continuing through a local edge road moves into the adjacent macro region if it is inside world bounds;
- scheduler/calendar/weather/player state persist across transitions;
- local runtime deltas are not yet persisted across unload/reload; deterministic regeneration is the baseline for later delta saves.

There is deliberately no minimap and no second local-area-map mode.

## Tactical zoom / performance rule

The macro map owns broad orientation. Tactical presentation is local-detail only.

Supported local zoom levels:

- 39px / 14×12 — far local overview;
- 44px / 12×10 — default;
- 50px / 10×9 — close detail.

The old 16×14, 18×16 and 20×17 tactical overview modes are intentionally removed from the active mini-world harness because Safari showed visible lag under animated weather. The 14×12 mode uses lower-rate/lower-density cosmetic weather while preserving the same authoritative weather/perception values.

## HUD rule

Keep player-facing information separate from developer controls.

The normal in-game HUD is read-only and currently shows survivor name, health, stamina, carry weight/capacity, in-game time/date, outdoor weather when outside, current local temperature, indoor/outdoor status, outdoor wind speed, and `Looking at:` for the tile/object directly ahead.

The `DEV` overlay contains tick/debug diagnostics plus manual world test controls. Current editable dev fields are HH:MM, MM/DD, and current weather. HH:MM and MM/DD use native Godot `LineEdit` controls so iOS/Safari can summon the keyboard. Developer controls do not cost world ticks.

## Visual / art semantics

**Art is not physics.** A sprite/tile does not become solid, opaque, interactive, searchable or destructible merely because it looks like a physical object. Movement blocking, LOS blocking and runtime interaction remain explicit world data.

**Inventory-art rule:** loose inventory, loot, ammunition, equipment and ordinary pickup items are data/UI only and do not require world sprites. World art represents environment surfaces, structures, fixtures, furniture, vegetation, civic infrastructure, large physical objects and clutter.

Current art sources:

- `tactical_atlas.svg` — restored same-owner First Fire tactical subset for legacy ground/walls/openings/props/barrels;
- `clutter_atlas.svg` — original Tick indoor/outdoor clutter;
- `world_art_atlas.svg` — generator-support road topology, sidewalks/curbs, driveways, parking, crosswalks, exterior surfaces, interior floors, wall materials, door/window materials and utility surfaces;
- `building_props_atlas.svg` — expanded domestic, commercial, office, industrial, street and rural fixtures;
- `final_environment_surfaces_atlas.svg` — final bootstrap terrain/interior/shell expansion;
- `final_environment_props_atlas.svg` — final bootstrap nature, civic, residential, commercial, office and industrial environment/fixture expansion;
- `player_south.svg`, `player_north.svg`, `player_west.svg`, `player_east.svg` — independent upright player poses with no rotation/mirror transform in the runtime draw path.

The current art vocabulary already includes traffic lights, stop signs, street-name signs, hydrants, streetlights and utility poles. Generator v5 now actively places traffic lights and multiple traffic-control/street-furniture objects instead of leaving most of that art unused.

## Streetscape / building-family semantics

V5 generation adds explicit `building_kind` as the sixth `building_rects` field.

Current families include:

- house;
- farmhouse;
- standalone store;
- office;
- warehouse;
- trailer;
- mansion / estate house;
- duplex;
- two- and three-unit strip malls.

All buildings remain single-level.

V5 coherence invariants:

- every parking-lot rectangle overlaps a building destination;
- old parking-only commercial parcels are repaired into attached strip malls;
- every generated v5 local region contains at least one visible stop sign and traffic light;
- developed intersections can receive traffic lights, stop signs, street-name signs, streetlights and hydrants;
- rural/woodland roads bias toward utility poles rather than dense city furniture;
- no horizontal or vertical run of three adjacent door cells may survive generation;
- strip-mall unit doors are intentionally separated by wall/window frontage.

## Visual/perception semantics

- The survivor has four independent authored facings: north shows the back, south the front, east/west are true side-profile body poses. Sprite facing reads the same `player.facing` used by perception, flashlight, interaction and movement.
- Existing map light markers feed per-cell lighting.
- Ambient light level for procedural regions responds to the biome under each cell instead of treating the whole 64×64 region as an alley.
- Powered sources switch off when power is unavailable.
- Windows transmit sight and daylight.
- Flashlight is directional.
- Walls, closed doors, and tall/opaque props block LOS/light.
- Player visibility requires facing cone + clear LOS + enough light.
- Fog has unseen and remembered states.
- LOS uses a sealed-corner rule so diagonal rays cannot squeeze between two touching opaque orthogonal cells.

Weather VFX are presentation-only real-time animation and may continue while simulation is paused. Rain, snow, fog, wind debris and storm flash must not mutate authoritative weather/world state.

Weather VFX should not visibly pass through interiors or wall tiles. Far local zoom may use cheaper cosmetic presentation, but gameplay weather modifiers do not change with zoom.

## Sound presentation rule

There is **no audible sound playback in Tick Survival Lab**.

Sound still exists as authoritative simulated physical/perception data because zombies, survivors, animals, weather, weapons, doors, vehicles, and environments need to emit and react to sound. The player receives it visually through yellow sound boxes/markers, including uncertain localization.

Do not add music, ambient audio, footsteps, gunshot playback, zombie voices, weather audio, or other actual game sound unless the user explicitly reverses this rule.

## Player/world separation

The persistent world is conceptually separate from the player character. The world/save owns seed, calendar, outbreak history, actors, zombies, structures, construction/destruction, items, corpses, vehicles, crops, settlements, infrastructure, and persistent consequences. The player is one mortal actor record within that world.

On player death, the user can eventually either play a new survivor in the same continuing world or start a new world seed. A later player may encounter the previous player's corpse, base, stash, family, vehicles, and consequences.

The current mini-world establishes stable world seed + macro region coordinates for later per-region persistence deltas.

## Current procedural limits / next work

The mini-world now proves deterministic macro regions, deterministic local seeds, region transitions, a central world map, streetscape traffic-control density, family-aware single-story buildings, parking-destination coherence, door-run sanitation, local lighting/vision and mobile-safe tactical zoom.

It does **not** yet simulate coastline, water/rivers, elevation, off-screen region activity, local-region save deltas, loot economy, populations, outbreak state, vehicles or infected.

The preferred next gameplay-system milestone remains **0.3C Spatial Sound Visualization**: tick-owned silent sound events, propagation/attenuation through physical cells, door/window/wall occlusion, weather masking, uncertain source localization, and yellow visual sound markers. Persistent infected can then consume the same perception + silent-sound model on the scheduler.

Preferred dependency direction:

**map/data → persistent world state → tick scheduler/rules → actor simulation → presentation/input**

Rules get one durable owner. UI must not own simulation state. The generator must not become a dumping ground for combat, inventory, AI, saves, or social systems.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This context file
5. Other durable design docs
