# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request, not before every edit inside the same coherent batch.

## Identity

Working repo/project name: **Tick Survival Lab**.

GitHub repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

This is an original Godot 4 top-down zombie-apocalypse survival simulation. Project Zomboid is a systemic-scope reference only; do not copy its proprietary code, art, maps, UI, names, text, or content.

First Fire is a same-owner source project. Reusable tactical/physical-world work may be adapted after inspection, but Tick must not inherit First Fire's camp/menu/expedition architecture.

Durable design references: `DESIGN.md`, `ROADMAP.md`, `WORLD_GENERATION.md`, `WORLD_NAVIGATION_AUDIT.md`, `ART_VOCABULARY.md`, and `FIRST_FIRE_REUSE.md`.

## Current milestone / stage

**Milestone 0.2 — Action Execution Model is complete. Milestone 0.3A — Visual Perception is complete. Milestone 0.3B — Weather Foundation is functionally present. The current world/navigation stage now includes a generator-support art vocabulary pass before the next macro geography / chunk-contract expansion or 0.3C Spatial Sound Visualization.**

Canonical source includes authored maps, deterministic 64×64 procedural regions, connected road hierarchy, directional road topology art, follow-camera/zoom, world/scheduler/player/timing-dummy modules, tactical + clutter + world/building-prop atlases, lighting, perception/fog, silent sound helpers, weather state/VFX, tick-driven calendar/day-night cycle, split dev/in-game HUDs, Safari touch suppression, and deterministic map/region/tick/calendar/environment/perception smoke tests.

Ownership:

- `TacticalMapGenerator.gd` — authored initial physical map facts plus the shared ground-query language used by authored and procedural maps.
- `ProceduralRegionGenerator.gd` — deterministic 64×64 local-region biome, road, parcel, structure, clutter and initial-light generation using the shared physical map schema. Current generator version is 3.
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
- `MapPreview.gd` — development input/presentation harness only; it may present debug controls but must not become the permanent owner of simulation rules.

## Timing semantics

The control model is **real time with automatic pause**, represented synchronously in the current developer harness while authoritative outcomes remain discrete.

1. `player_ready == true` while waiting for a player choice.
2. A player action begins with explicit cost, start tick, interruption policy, optional phases, and payload.
3. `player_ready == false` while that action executes.
4. Other scheduled actors whose `next_tick` falls inside the action window execute in deterministic order.
5. The world advances to action completion unless interruption policy ends it early.
6. The scheduler auto-returns to `player_ready == true` when the action completes, interrupts, cancels, or hard-fails.

Implemented interruption policies: committed, resumable, canceled, and forced failure. Tie ordering is earliest `next_tick`, then lexical actor ID. Actors scheduled exactly on the player action end tick execute before the player becomes ready.

`TickSmoke.gd` proves concurrent actors, resumable reload progress, and committed-through-damage behavior.

## Calendar/day-night semantics

World time advances only from authoritative scheduler ticks through `WorldCalendar.gd`.

Current tuning is **7,200 ticks per 24-hour day**: 5 ticks per displayed minute / 12 displayed seconds per tick. This is a gameplay compression ratio, not a claim that one physical action tick literally equals 12 real seconds. Calendar compression remains tunable independently of action costs.

Daylight phases are tick-driven: night → dawn (05:30) → day (07:00) → dusk (18:30) → night (20:00). Pausing does not advance calendar time. Weather VFX may continue animating while paused because they remain presentation-only.

## Mobile/touch semantics

The logical viewport is 640×844. The touch deck is a true three-row layout:

- left column: intentional empty top slot → `TURN L` → `CROUCH`;
- right column: `FORWARD` → `TURN R` → `BACK`;
- both turn controls share exactly the same Y position and height;
- forward/back preserve facing;
- crouch is a timed stance action;
- plus/minus controls change presentation zoom only.

**One physical touch must equal one action.** Mobile Safari may synthesize a mouse click around a touch; `SafariInputGuard.gd` and the local suppression window prevent first-touch and follow-up double-actions. Do not remove these guards or reintroduce double-move / 180-degree-turn behavior.

Map tapping remains available. `MENU`/Escape opens the actual pause menu and Web exit uses same-tab browser navigation.

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

The world-art road vocabulary includes vertical/horizontal paved straights, four corners, four T-junctions, a four-way intersection, directional end caps, plain/wide intersection asphalt, and horizontal/vertical dirt-road presentation. Future macro routing must emit the same road topology contract rather than inventing a second art system.

The current expanded fixture vocabulary includes domestic fixtures/furniture (stove, counters, dresser, nightstand, bath/shower/vanity, dining table, armchair), office/commercial fixtures (filing cabinet, cubicle, computer, checkout, freezer, produce bin), industrial/utility fixtures (pallet rack, tool chest, workbench, locker, utility sink, water heater, exterior AC, electric meter), and exterior/street/rural objects (utility pole, traffic light, stop sign, parking meter, bollard, hedge, flower bed, shed, propane tank), in addition to the earlier clutter atlas.

## Visual/perception semantics

- The survivor has four independent authored facings: north shows the back, south the front, east/west are true side-profile body poses. Sprite facing reads the same `player.facing` used by perception, flashlight, interaction and movement.
- Existing map light markers feed per-cell lighting.
- Ambient light level for procedural regions responds to the biome under each cell instead of treating the whole 64×64 region as an alley.
- Powered sources switch off when power is unavailable.
- Windows transmit sight and daylight.
- Flashlight is directional.
- Walls, closed doors, and tall/opaque props block LOS/light.
- Tall new fixture types such as freezers, filing cabinets, pallet racks, lockers, water heaters, hedges and sheds participate in opacity when designated by perception; lower clutter does not automatically block sight.
- Player visibility requires facing cone + clear LOS + enough light.
- Fog has unseen and remembered states.
- LOS uses a sealed-corner rule so diagonal rays cannot squeeze between two touching opaque orthogonal cells.

Weather VFX are presentation-only real-time animation and may continue while simulation is paused. Rain, snow, fog, wind debris and storm flash must not mutate authoritative weather/world state.

Weather VFX should not visibly pass through interiors or wall tiles. Current presentation filters precipitation/debris by outdoor cell and renders fog/storm effects per outdoor non-wall cell. Weather is drawn beneath fog-of-war so the mask does not reveal hidden room geometry.

## Sound presentation rule

There is **no audible sound playback in Tick Survival Lab**.

Sound still exists as authoritative simulated physical/perception data because zombies, survivors, animals, weather, weapons, doors, vehicles, and environments need to emit and react to sound. The player receives it visually through yellow sound boxes/markers, including uncertain localization.

Do not add music, ambient audio, footsteps, gunshot playback, zombie voices, weather audio, or other actual game sound unless the user explicitly reverses this rule.

## Player/world separation

The persistent world is conceptually separate from the player character. The world/save owns seed, calendar, outbreak history, actors, zombies, structures, construction/destruction, items, corpses, vehicles, crops, settlements, infrastructure, and persistent consequences. The player is one mortal actor record within that world.

On player death, the user can eventually either play a new survivor in the same continuing world or start a new world seed. A later player may encounter the previous player's corpse, base, stash, family, vehicles, and consequences.

## Map/world direction

The imported First Fire map foundation remains an authored-layout catalog of 20×18 physical locations: Back Alley, Gas Station, Residential House, Apartment, Corner Store, Warehouse Yard, and Drainage Wash. Each can describe ground, indoor regions, walls, doors, windows/glass, obstacles, props, barrels, light markers, player spawn, and exits.

The large-map stress slice uses `ProceduralRegionGenerator.gd` to generate a deterministic 64×64 region using the same physical language. The current generator version is **3**.

Current road rules and data contracts:

- biome centers are contiguous seeded fields;
- each non-downtown biome connects toward the nearest main arterial axis;
- developed areas get short local streets, rural gets service roads, woods gets dirt trails;
- a three-tile arterial cross is carved last and connects all four region exits;
- player spawn sits on the arterial crossing;
- validation proves each exit is road-connected to spawn and no generated structure blocks road cells;
- developed buildings require nearby road frontage and orient their door toward the nearest road;
- developed roads receive sidewalk edges, rural roads dirt shoulders;
- `road_class_cells` distinguishes arterial/secondary/local/trail;
- `road_surface_cells` distinguishes paved road from dirt/trail presentation;
- `road_links` is a four-bit N/E/S/W topology mask used by directional road art and is the intended contract for future curved/branching macro road routes;
- `road_ports` establishes a future chunk-edge data shape but is not yet a neighbor-compatible macro road contract;
- procedural buildings now emit `wall_themes`, `door_themes`, and `window_themes` as presentation metadata while physical membership remains walls/doors/glass.

The shared ground language supports rectangle fills plus optional sparse `ground_cells` overrides. Do not replace this with a second incompatible map language. Long-term hierarchy remains:

**tile/object → building/location → local area/block → biome/district → region/chunk → large island world**

The island mixes city/downtown, suburban/residential, commercial/industrial, rural/farm, and woods/wilderness. Destroyed/bombed bridges and failed crossings can show that the playable region once connected to a larger world.

## Clutter / physical-object rule

Visual variety must not blur physical semantics.

A prop may be purely visual, may be included in `obstacles` to block movement, and may separately be treated as opaque by perception. These are distinct questions. Do not infer movement or sight blocking merely because an object has a sprite.

See `ART_VOCABULARY.md` for the full current surface/opening/fixture vocabulary and the generator-facing art contract.

## Current procedural limits / next world work

The 64×64 generator currently proves deterministic biome fields, connected road hierarchy, directional road topology metadata/art, frontage-aware structures, richer floor/material vocabulary, deterministic clutter, camera-local rendering, local lighting/vision and world navigation. It does **not** yet simulate coastline, water/rivers, elevation, neighbor-compatible chunk edge contracts, utility grids, true room-aware building-template libraries, loot economy, populations, outbreak state, or persistence deltas.

The next world-generation-specific step should be **macro geography + chunk-edge contracts**: a seed-driven larger world composed of deterministic chunks, with coastline/water/elevation plus shared road/trail/river/utility ports that neighboring chunks agree on. Road routing should use the existing `road_links`/class/surface vocabulary and generate actual bends, junctions, loops and local street graphs.

A separate near-term building pass can consume the new wall/door/window material metadata to add true building templates and room-specific interiors without another art-schema rewrite.

## Long-term simulation direction

See `DESIGN.md`. Intended systems include persistent infected; visualized spatial sound; deterministic weather; dangerous timing-driven combat; body-region wounds and amputation; hunger/thirst/fatigue; inventory/loot/equipment; use-based skills and learning media; destructible/free-build environments; farming/crafting; autonomous survivors and animals; emergent settlements; patrols and supply routes; vehicles; infrastructure reclamation; and eventual outbreak epicenter/spread/response plus occupation/family starts.

## Near-term scope recommendation

The world/navigation foundation is suitable for the next macro-world experiment now that its art vocabulary can represent horizontal/vertical roads and richer buildings. The next world-scale pass should be seed-driven macro geography + cross-chunk road/terrain contracts if island topology is the priority.

Otherwise the next gameplay-system milestone remains **0.3C Spatial Sound Visualization**: tick-owned silent sound events, propagation/attenuation through physical cells, door/window/wall occlusion, weather masking, uncertain source localization, and yellow visual sound markers. Persistent infected can then consume the same perception + silent-sound model on the scheduler.

Preferred dependency direction:

**map/data → persistent world state → tick scheduler/rules → actor simulation → presentation/input**

Rules get one durable owner. UI must not own simulation state. The map generator must not become a dumping ground for combat, inventory, AI, saves, or social systems.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `DESIGN.md` / `ROADMAP.md` / `WORLD_GENERATION.md` / `WORLD_NAVIGATION_AUDIT.md` / `ART_VOCABULARY.md` / `FIRST_FIRE_REUSE.md`
6. Human `README.md`
7. Conversation memory only as supporting context

## Continuous deployment

`.github/workflows/pages.yml` is the permanent build/deploy gate. It validates canonical files, imports/parses with Godot 4.7.1, runs deterministic authored-map/region/tick/calendar/environment/perception smoke tests, starts the real scene headlessly, exports Web, uploads the artifact, and deploys GitHub Pages.
