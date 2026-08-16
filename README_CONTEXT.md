# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request.

## Identity

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Tick Survival Lab is an original Godot 4 top-down zombie-apocalypse survival/extraction simulation.

## Current architectural status

The project is entering a **full modular rebuild**.

The currently deployed clean-reboot runtime under `game/scripts/reboot/` is **frozen/deprecated reference code**. It remains playable and may be mined for useful recent generation/door/prefab lessons, but it is not the architecture to extend.

The canonical implementation target is:

**`MODULAR_REBUILD_MASTER_DESIGN.md`**

Do not add new systems to `RebootMain.gd`. Do not treat the clean-reboot renderer/art catalog as the authentic pre-rewrite graphics implementation.

## Golden recovery baseline

The last mature pre-clean-rewrite visual/system baseline is commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Title: `Document focused raid interiors v6`.

This commit is an **archaeology/recovery source**, not architecture to restore wholesale.

The old visuals came from `TacticalTiles.gd` combining multiple art sources, not from one atlas. Recover its semantic art-selection/draw behavior into modular art/render scripts.

### Preserved art baseline

These current asset files are byte-identical to the golden commit and must be preserved unless an explicit art-change prompt says otherwise:

- `tactical_atlas.svg` — `a031ac456a7d92b7fbf2d6e4d625c3a30e749a4f`
- `clutter_atlas.svg` — `966c9de04ad84d05d6203cc4e078f2fad07c03d4`
- `world_art_atlas.svg` — `995e52973e14db0ef60f3562c1cfa5ae342d62d2`
- `building_props_atlas.svg` — `856be2fc90d009d1b4bcc565990b9428323bb4d6`
- `final_environment_surfaces_atlas.svg` — `a42607858bae04f25fb1c6621a6d9262e81550b1`
- `final_environment_props_atlas.svg` — `7714d8c95833e20ebca20cfa1374f23eaa5509f1`
- `player_north.svg` — `dfeb5be1c9cc0b66aec842d969b60b485d3a4f99`
- `player_east.svg` — `76c3e7e1a3b07712c65b385f1d80e131b45d90b3`
- `player_south.svg` — `a2e358fd8fe15d497bf9559ae89835af0331d10f`
- `player_west.svg` — `c2cc192efed4c4a81905eb0d8100cd4776d4731b`

The graphics regression after the clean rewrite was caused by replacing the old semantic renderer/catalog behavior, not by losing the asset files.

## Non-negotiable modular rule

The root/main script is **composition only**.

Main may:

- obtain child/service references;
- inject dependencies/configuration;
- connect high-level signals;
- select initial controller/mode;
- do minimal lifecycle bookkeeping.

Main may not own drawing, input handling, button geometry, zoom/camera math, generation, player movement, collision, strategic-map presentation, prefab logic, persistence, extraction, weather, lighting, perception, sound, validation, or subsystem UI.

Every named system belongs in its own standalone script/module. Prefer small replaceable composition over inheritance chains or god objects.

The architectural success criterion is that a subsystem can be deleted and rewritten behind a stable data/API contract without modifying unrelated modules.

## Stable world-data rule

Generation outputs **semantic world data**, never atlas indices or draw calls.

Example semantic IDs:

- `ground.grass_lush`
- `ground.gravel_driveway`
- `wall.house_siding`
- `door.house`
- `fixture.kitchen_sink`
- `prop.utility_pole`

A separate recovered `ArtCatalog` decides which asset/source/index represents each semantic ID.

**Art is not physics.** Blocking, opacity, door state, interaction and later search/destruction/persistence facts are explicit world data separate from sprites.

This boundary is what must allow the random generator to be completely rewritten without losing graphics/player/input/map behavior.

## Current game direction

The strategic world is a **static map image/background with interactive destination nodes**, not a generated seamless tactical world.

Progression moves geographically:

**BASE / RURAL EDGE → SMALL TOWNS → SUBURBS → CITY EDGE → CITY CENTER**

The survivor starts with limited foot travel. Vehicles later act primarily as strategic gateway/stair transitions to farther travel depths/anchors. They can gain fuel/damage/storage/driving mechanics later without changing that navigation model.

Core loop:

**STATIC STRATEGIC MAP → REACHABLE DESTINATION → GENERATED TACTICAL RAID → PHYSICAL EXTRACTION → RETURN TO STAGING → EXPAND ROAMING RANGE.**

A deeper raid returns to the staging anchor that launched it, such as a parked vehicle later, rather than magically returning all the way home.

## Tactical raid rule

A tactical map represents **one coherent sample of a place**. It must not try to show every biome or spend most of its space on roads/filler.

Roads serve the site. Properties/buildings/vegetation define the site.

The first rebuild target is **Rural Edge**. Do not implement Small Town until Rural Edge repeatedly looks authored and believable.

### Rural Edge direction

Typical rural sample qualities:

- one two-lane main road;
- road topology varies among straight, bend/curve-like, crossroads, later T/offset variants;
- narrow dirt/gravel roads and driveways branch from it;
- lots of grass, trees, bushes, scrub, weeds and rural open land;
- frequent utility poles/power lines along developed road frontage;
- sparse stop signs;
- few/no traffic lights;
- 3–4-ish residential properties as a normal scale, not a rigid quota;
- property mix may include a farm complex, substantial rural houses, trailers and double-wides;
- zero or one small gas/convenience/corner store normally, never a rural strip mall; up to two only when a composition intentionally supports it.

Examples are grammar, not hardcoded quotas.

### Rural buildings/interiors

- functional rooms normally at least 3x3 usable cells;
- public spaces such as a storefront generally 5x5–7x7;
- support rooms generally around 3x3;
- multiple believable rooms rather than giant empty interiors;
- sinks/stoves/refrigerators/bathroom fixtures placed against sensible wall/plumbing planes;
- beds/desks/shelves/counters placed with usable circulation;
- retail shelving creates aisles;
- stockroom/service clutter stays clear of entrances.

Door geometry is a hard physical rule: every door has a wall axis, perpendicular approaches stay clear, same-axis structural neighbors remain, and a door cannot occupy a wall cross/T-junction.

## Prefab direction

Prefab authoring remains part of the game/dev tooling, but it will be rebuilt modularly.

A prefab is semantic data, not code and not atlas indices. It can carry:

- ground/structure/prop data;
- door axes;
- footprint;
- frontage/entrance anchors;
- building/site tags;
- allowed biome tags;
- room metadata;
- road/drive requirements;
- allowed rotations/mirroring.

Builder controller, builder view, palette, preview renderer, validator, serializer and storage must be separate scripts.

The builder must use the same canonical renderer/art catalog as tactical gameplay so it cannot develop a second visual language.

Maximum authored footprint should be approximately one far-zoom tactical window; resolve exact dimensions from the canonical zoom module during implementation rather than pinning a stale number in multiple places.

## Recovered systems to preserve for later

From the golden pre-rewrite build, inspect/port rather than casually reinvent:

- `TacticalTiles.gd` semantic art behavior — recover now, split into modules;
- `LocalWorldState.gd` — mutable door/collision ideas;
- `PlayerActor.gd` — useful movement/facing semantics;
- `SafariInputGuard.gd` — Safari de-duplication;
- `TickScheduler.gd` — authoritative tick/action system, deferred but already substantially solved;
- `WorldCalendar.gd` — deferred;
- `TacticalLighting.gd` — deferred, user wants lighting later;
- `TacticalPerception.gd` — deferred, user wants vision cone later;
- `TacticalWeather.gd` — deferred, user wants weather later;
- `TacticalSound.gd` — deferred silent spatial sound system;
- `ExtractionRaidState.gd` — mine extraction state semantics;
- old generation/street/interior passes — mine rules/algorithms only, do not recreate old patch-chain architecture.

The game remains intentionally **silent** unless explicitly changed: sound is simulation data communicated visually (for example yellow spatial/noise markers), not audible playback.

## Initial modular rebuild sequence

1. **Do not start with random generation.**
2. Build bootstrap-only Main plus semantic data records.
3. Recover exact golden art mappings into standalone `ArtCatalog`.
4. Split tactical rendering into ground/structure/prop/player renderers.
5. Restore the old rich visuals on a tiny authored test map and verify them visually.
6. Build separate player state/movement/facing/collision modules.
7. Build separate camera/zoom modules.
8. Build separate touch/keyboard/Safari input modules and tactical controls view.
9. Build separate static strategic map state/view/input.
10. Only after the old visual baseline is visibly restored, build the new modular Rural Edge generator.
11. Rebuild prefab tooling on top of the shared semantic data/renderer.
12. Add travel/extraction state.
13. Recover tick/perception/lighting/weather/sound one subsystem at a time later.

## Current deployed runtime

The live build at the web preview still runs the clean-reboot code until the modular foundation replaces it. It is useful only for reference/playtesting and should not be mistaken for the target architecture.

Do not delete it during a design-only prompt. Git history plus the golden commit are the rollback/recovery sources.

## Source-of-truth order

1. Newest explicit user instruction
2. Current repository state
3. `README_SOPS.md`
4. This context file
5. **`MODULAR_REBUILD_MASTER_DESIGN.md`**
6. Golden recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe` for exact old code/art archaeology
7. `TRAVEL_DEPTH_VEHICLE_GATEWAY_DESIGN.md` where compatible with the newer static strategic-map direction
8. Older design docs only where they do not conflict

If a user requests a destructive rewrite and the scope is genuinely ambiguous, ask a targeted clarifying question before crossing subsystem boundaries.
