# GPT CODING / GITHUB SOP — TICK SURVIVAL LAB

> **MANDATORY ENTRY CONDITION FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread this file and `README_CONTEXT.md` from current `main`, then inspect the current files relevant to that prompt. Refresh once per prompt/change request, not before every edit.

## 1. Current architectural status

Tick Survival Lab is entering a **full modular rebuild**.

The currently deployed `game/scripts/reboot/` runtime is **frozen/deprecated reference code**. Do not extend `RebootMain.gd` or treat the clean-reboot architecture as the target merely because it is currently playable.

Canonical target architecture:

`MODULAR_REBUILD_MASTER_DESIGN.md`

Golden recovery baseline for the mature pre-clean-rewrite visual/system implementation:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Use that commit for exact archaeology when recovering old graphics/behavior. Do not restore its old presentation inheritance stack wholesale.

## 2. Core operating rules

1. **Current repo beats memory.** Fetch first.
2. **Newest explicit user instruction beats older design.**
3. **Canonical Godot source is `game/`.**
4. **Direct `main` is normal** unless the user asks for a branch/PR workflow.
5. **Batch coherent changes.**
6. **One named system = one standalone owning script/module at minimum.**
7. **Main is composition only.** Never put a temporary subsystem in Main.
8. **Prefer composition and narrow data/API contracts over deep inheritance.**
9. **A subsystem rewrite must not opportunistically rewrite neighboring systems.**
10. **Do not describe an approximation as recovered old behavior.** Inspect the actual golden code/assets first.
11. **Do not claim a build works without exact-SHA Godot/Pages validation.**
12. **Keep simulation testable without presentation.**
13. **Ask a targeted clarification before destructive cross-module work when the requested scope or historical visual target is genuinely ambiguous.**

## 3. Required pre-code checklist — once per prompt

Before changing code or repository behavior:

1. Fetch/read current `README_SOPS.md`.
2. Fetch/read current `README_CONTEXT.md`.
3. Fetch current `main` SHA.
4. Read `MODULAR_REBUILD_MASTER_DESIGN.md` when the task touches architecture, generation, rendering, player/input, strategic map, prefabs, extraction, or recovery work.
5. Inspect the actual current files relevant to the requested subsystem.
6. If recovering anything described as old/previous/better/last build, inspect the relevant file(s) at golden commit `1763958f44eb7f855fd49944c00d1ffe608c0abe` before making claims or edits.
7. Identify the stable data/API boundary of the requested subsystem.
8. Identify exactly which standalone owner(s) should change and which neighboring modules must remain untouched.
9. Fetch current blob SHAs for files that will be replaced.
10. Check whether tests need a contract/architecture guard update.

Do not ask the user to repeat information already present in current repo context or the current conversation. Ask only when a material ambiguity cannot be resolved by inspection.

## 4. Non-negotiable Main/root rule

The future `Main.gd` / root scene script is a **bootstrap and wiring layer only**.

Allowed responsibilities:

- get references to child/services;
- construct/inject dependencies;
- connect high-level signals;
- select the initial top-level controller/mode;
- minimal lifecycle startup/shutdown bookkeeping.

Forbidden responsibilities:

- `_draw()` game/presentation implementation;
- `_unhandled_input()` gameplay/control implementation;
- touch hit testing;
- keyboard mappings;
- button rectangles/UI geometry;
- tactical rendering;
- strategic-map rendering;
- HUD rendering;
- camera origin/viewport math;
- zoom rules;
- map/raid generation;
- road/property/building generation;
- prefab placement/editor implementation;
- player movement/facing rules;
- collision/door rules;
- extraction/travel rules;
- art/atlas selection;
- persistence/serialization;
- ticks/calendar;
- lighting/perception/weather/sound;
- validation/quality rules.

If a behavior can be given a system name, it belongs in its own script.

Never justify putting functionality in Main because it is temporary, small, convenient, or only used by DEV.

## 5. Replaceability rule

The architecture must permit literal subsystem replacement.

These statements must remain true:

- `generation/` can be deleted and rewritten without modifying art/render/player/input/camera/strategic modules;
- `render/` can be deleted and rewritten without modifying generation, physics, player state, or strategic state;
- `input/` can be replaced without changing simulation/action rules;
- `strategic/` can be replaced without changing tactical raid generation;
- `prefabs_dev/` can be replaced without changing normal tactical rendering or generation contracts;
- perception/lighting/weather/sound can be added or replaced without the generator knowing how those systems render.

If a requested change crosses one of these boundaries, stop and determine whether the shared contract is actually insufficient. Do not simply edit both sides to make it work.

## 6. Stable semantic data contract

Generation and simulation use **semantic world data**, not atlas indices or renderer calls.

Examples:

- `ground.grass_lush`
- `ground.gravel_driveway`
- `wall.house_siding`
- `door.house`
- `fixture.kitchen_sink`
- `prop.utility_pole`

Generator code must not reference texture paths, atlas coordinates, drawing functions, UI geometry, player sprites, or presentation colors.

The art catalog maps semantic IDs to exact visual resources.

### Art is not physics

A visual ID/sprite does not decide:

- movement blocking;
- opacity/LOS;
- door state;
- interaction;
- destructibility;
- searchability;
- loot contents;
- persistence.

Those are explicit world/simulation facts.

### Inventory-art boundary

Preserve the mature art rule: ordinary inventory items do not need loose tactical floor sprites. Tactical world art depicts terrain, structures, furniture, fixtures, vegetation, civic infrastructure, environmental clutter, and large physical objects.

## 7. Golden art recovery contract

The richer pre-rewrite graphics were produced by a **multi-atlas semantic renderer**, not one tile sheet.

Golden `TacticalTiles.gd` at commit `1763958...` combined:

- `tactical_atlas.svg`;
- `clutter_atlas.svg`;
- `world_art_atlas.svg`;
- `building_props_atlas.svg`;
- `final_environment_surfaces_atlas.svg`;
- `final_environment_props_atlas.svg`;
- four directional player SVGs.

The current asset files are byte-identical to the golden baseline. Preserve these exact blob hashes until an explicit art-change prompt:

- tactical: `a031ac456a7d92b7fbf2d6e4d625c3a30e749a4f`
- clutter: `966c9de04ad84d05d6203cc4e078f2fad07c03d4`
- world art: `995e52973e14db0ef60f3562c1cfa5ae342d62d2`
- building props: `856be2fc90d009d1b4bcc565990b9428323bb4d6`
- final surfaces: `a42607858bae04f25fb1c6621a6d9262e81550b1`
- final props: `7714d8c95833e20ebca20cfa1374f23eaa5509f1`
- player N: `dfeb5be1c9cc0b66aec842d969b60b485d3a4f99`
- player E: `76c3e7e1a3b07712c65b385f1d80e131b45d90b3`
- player S: `a2e358fd8fe15d497bf9559ae89835af0331d10f`
- player W: `c2cc192efed4c4a81905eb0d8100cd4776d4731b`

Recover golden `TacticalTiles.gd` semantics into modular `ArtCatalog` + layer renderers. Do not copy its responsibilities into Main.

## 8. Target module boundaries

`MODULAR_REBUILD_MASTER_DESIGN.md` contains the detailed folder plan. At minimum keep these domains separate:

- `app/` — bootstrap + high-level flow;
- `data/` — stable semantic data records;
- `art/` — semantic art catalog/source resolution;
- `render/` — tactical layer renderers;
- `camera/` — view window and zoom;
- `input/` — touch, keyboard, Safari de-duplication, semantic action intents;
- `player/` — player state/facing/movement;
- `world/` — collision, mutable local world/doors;
- `strategic/` — static map state/view/input and travel reachability;
- `raid/` — raid session/deployment/extraction;
- `generation/` — replaceable procedural generation modules;
- `prefabs_dev/` — authoring UI/storage/validation;
- `ui/` — HUD/control views;
- later `time/` and `perception/` modules.

Avoid inheritance chains where one presentation class inherits another presentation class to gain unrelated behavior. Prefer controller/view composition and signals.

## 9. Rendering rules

Rendering consumes semantic `RaidMapSpec`/world state and never mutates simulation.

Split at least:

- ground layer;
- walls/doors/windows layer;
- props/fixtures/vegetation layer;
- player layer;
- power-line/static infrastructure overlay;
- extraction markers;
- later lighting/perception/weather overlays.

A tactical renderer may orchestrate these layers, but must not own generator/player/input logic.

### Performance baseline

Preserve the best clean-reboot performance lessons:

- no idle full tactical redraw when nothing animated is active;
- draw only camera-visible cells;
- use sparse O(1)-style lookup structures;
- animated overlays later should have bounded redraw cadence and should not force unrelated systems to recompute every frame;
- mobile/Safari remains first-class.

## 10. Player/camera/input rules

Player state, movement, facing, camera, zoom, touch input, keyboard input, Safari suppression, and control rendering are separate owners.

Input adapters emit semantic intents such as `MOVE_FORWARD`, `TURN_LEFT`, `OPEN_MAP`; they do not mutate player state directly.

Movement consumes player state + collision query. It does not know button rectangles or sprites.

Proven local zoom targets to re-evaluate during recovered-renderer work:

- 14x12 @ ~39 px;
- 12x10 @ ~44 px;
- 10x9 @ ~50 px.

Do not duplicate zoom preset values across multiple scripts. One zoom owner supplies them.

## 11. Strategic-world rules

The macro world is a **static authored image/background with interactive semantic nodes**, not a seamless generated tactical surface.

Geographic progression:

**BASE / RURAL EDGE -> SMALL TOWNS -> SUBURBS -> CITY EDGE -> CITY CENTER**

Foot travel initially limits reachability. Vehicles later act primarily as strategic gateway/stair transitions to farther travel anchors/depths. Travel state/range is simulation/state, not map-view logic.

A strategic view renders state; a strategic input module emits selection/travel/deploy intents; travel rules decide reachability.

## 12. Generator rules

The tactical generator outputs one coherent raid/site sample.

Generator coordinator must call replaceable modules; it must not become a new god script.

Separate responsibilities should include at least:

- biome rule selection;
- broad site composition;
- main-road topology;
- side roads/driveways;
- property/parcel planning;
- prefab selection/placement;
- room/layout generation where needed;
- door planning/validation;
- fixtures;
- furniture;
- clutter;
- vegetation;
- utility networks;
- civic props;
- extraction placement;
- independent validation.

Do not use a chain of corrective passes that repeatedly deletes/rebuilds previous generator output as the primary architecture. Plan semantic composition first; validate after.

### Rural Edge — first biome only

Before Small Town, Rural Edge must consistently look believable across many seeds.

Current direction:

- one two-lane rural main road;
- weighted straight, bend/curve-like, crossroads; later T/offset options;
- small dirt/gravel side roads and drives;
- broad grass/open rural land;
- lots of trees/bushes/scrub/weeds;
- frequent utility poles/power-line runs along developed frontage;
- sparse stop signs;
- few/no traffic lights;
- roughly 3–4 residential properties as a normal scale, not a rigid quota;
- mix may include one farm complex, substantial country houses, small trailers and double-wides;
- normally zero/one gas-convenience-corner store, maximum two only when intentional;
- no rural strip malls.

Examples describe weighted grammar, not a fixed list every seed.

### Rooms/furniture/clutter

- functional procedural rooms normally >= 3x3 usable cells;
- storefront/public rooms commonly ~5x5–7x7;
- support/back rooms commonly ~3x3;
- sinks/ranges/fridges/bath fixtures against plausible walls/plumbing planes;
- beds/TV/seating/desks/shelves arranged with usable circulation;
- retail shelves create aisles;
- checkout respects entrance flow;
- stock/service clutter stays clear of doors;
- clutter never blindly scatters after layout without reservations.

### Door invariant

Every door has a wall axis.

- horizontal wall door: north/south approaches clear, left/right remain structural;
- vertical wall door: east/west approaches clear, up/down remain structural;
- no door at perpendicular wall crosses/T-junctions;
- door/approach reservation cannot later receive wall/window/prop/clutter.

If generation violates this, change the layout. Do not cosmetically erase geometry to hide the bug or weaken validation just to pass CI.

## 13. Prefab rules

Prefab authoring remains a first-class developer tool, but rebuild it on the shared semantic data/art contracts.

A prefab is data, not code and not atlas indices.

Prefab data should support:

- semantic ground/structures/props;
- door axes;
- trimmed footprint;
- entrance/frontage anchors;
- site/building tags;
- allowed biome tags;
- room metadata;
- road/drive relation;
- allowed rotation/mirroring.

Separate owners:

- builder controller;
- builder view;
- palette/tools;
- preview renderer using canonical tactical renderer/art catalog;
- validator;
- serializer;
- local storage;
- later import/export.

Do not let the prefab builder invent its own art mapping.

## 14. Recovered/deferred systems

These old systems are **deferred, not discarded**. Inspect/port from golden commit when reintroduced:

- `TickScheduler.gd` — authoritative discrete time/action execution/interruption;
- `WorldCalendar.gd`;
- `TacticalLighting.gd`;
- `TacticalPerception.gd` — vision cone/LOS/fog memory;
- `TacticalWeather.gd` — separate state from VFX when ported;
- `TacticalSound.gd` — silent spatial sound/localization;
- `LocalWorldState.gd`;
- `SafariInputGuard.gd`.

The user wants vision cone, lighting and weather restored later, after the modular generator/player/render/input/map foundation.

The game remains **silent** unless explicitly reversed. Sound is simulated data communicated visually; do not add audible game audio by default.

## 15. Modular rebuild implementation sequence

Follow this order unless the user explicitly changes it:

### Phase 0 — design/freeze

- master design/context/SOP;
- pin golden recovery commit and art hashes;
- leave current live reboot as reference;
- do not extend it.

### Phase 1 — recovered graphics + modular foundation

1. bootstrap-only Main;
2. semantic data records;
3. exact golden art mapping into standalone ArtCatalog;
4. split ground/structure/prop/player renderers;
5. tiny authored visual test map;
6. verify visually that the mature old graphics are actually back;
7. separate player state/facing/movement/collision;
8. separate camera/zoom;
9. separate touch/keyboard/Safari input and control view;
10. separate static strategic map state/view/input.

**Do not write the new random generator until the recovered graphics are visibly verified.**

### Phase 2 — Rural Edge generator

Build modular semantic generator and polish many seeds.

### Phase 3 — prefab tooling

Rebuild semantic prefab authoring on the shared renderer/data contracts.

### Phase 4 — travel/extraction

Static strategic reachability, deployment, physical extraction, return to staging.

### Phase 5 — recover simulation systems individually

Ticks/calendar -> perception cone -> lighting -> weather -> silent sound -> infected -> loot/inventory -> extraction stakes -> combat/body -> richer vehicles.

## 16. Validation / architecture guards

Meaningful modular-rebuild code changes must eventually pass exact final SHA through:

1. canonical source checks;
2. Godot 4.7.1 import/parse;
3. module contract/smoke tests relevant to changed subsystem;
4. main scene startup;
5. Web export;
6. Pages artifact/deploy.

Add architecture CI as the modular shell lands. It should fail if Main gains forbidden responsibilities such as `_draw`, `_unhandled_input`, atlas references, button geometry, generator logic, or simulation data.

Add an art-baseline hash guard while recovered visuals are frozen.

Renderer tests should prove semantic IDs resolve to the same golden atlas source/index behavior.

Generator tests should validate semantic/physical quality, not renderer details.

A mock generator should be swappable without changing renderer/player/input code. A mock renderer should be swappable without changing generator/simulation code.

## 17. Legacy/current code policy

- `game/scripts/reboot/` = deprecated/frozen reference until modular shell replaces it.
- golden pre-rewrite code = archaeology source for exact solved behavior.
- neither should be blindly copied into new architecture.
- do not delete historical/current reference code during a design-only change.
- Git history is the ultimate rollback source.

When the modular shell is proven, remove/deprecate superseded runtime code in a separate intentional cleanup pass.

## 18. Communication / clarification

- State when something is recovered exactly versus reimplemented approximately.
- If the user says “the old graphics,” inspect the golden implementation before claiming what that means.
- If a destructive rewrite could mean either “replace one module” or “replace adjacent systems too,” ask which scope is intended unless the stable module contract makes the answer unambiguous.
- Spelling/typos are not themselves a reason to ask questions when intent is clear from context.
- Prefer a targeted question over a guessed destructive change.
- Do not repeatedly ask for confirmation once the requested scope is clear.

## 19. Final self-check

Before calling a repo task done:

- Did I reread current SOP/context once for this prompt?
- Did I inspect current relevant source?
- If recovering old behavior, did I inspect the actual golden code/assets?
- Did I change only the owning subsystem(s)?
- Did I preserve stable contracts and sibling modules?
- Did I keep Main as composition only?
- Did generation remain renderer/art-index independent?
- Did art remain separate from physics?
- Did I add/update subsystem tests where appropriate?
- Did exact final SHA pass required Godot/Pages gates for code/runtime changes?
- Did I avoid claiming approximation = recovery?

## 20. Required footer after repository changes

When a prompt changes this repository, end with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
