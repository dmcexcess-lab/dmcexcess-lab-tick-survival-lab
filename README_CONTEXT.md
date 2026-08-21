# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

Systems 14–22 form the current canonical playable/planning path. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 Rural Crossroads Candidate 005 is the active area baseline.** Current profiles are `rural.crossroads` v4 + `temperate.rural` v3 over the same 256×256 global critique area and existing System 19 building library.

Candidate 005 preserves the accepted Candidate 004 roads, farms, parcel distribution, setbacks, building envelopes, vegetation and zero-fake-parking rule. It fixes the remaining property-access critique: each occupied parcel now aligns its road/sidewalk/driveway approach axis directly to the **actual generated System 19 primary exterior door**, so the path no longer reaches the facade and turns sideways at the last moment.

The alignment uses only public System 19 plan facts. Saved prefab internals are untouched.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; five discrete zoom levels, detached inspection, recenter, focus and scripted/cutscene seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The canonical live game materializes and renders the generated Rural Crossroads area.

The immediate active work remains **user visual/playable critique of System 20 rural morphology/property access/environmental dressing**.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical stack

Dedicated canonical validation includes:

- WHERE / WHAT / WHEN;
- collision / movement / locomotion;
- recovered Art + ground/structure/prop/living-actor/hand renderers;
- prop orientation;
- Door State + System 18 passage/manual close;
- hands / inventory / item transfer;
- health / needs / skills / physical weight / carry / moodlets;
- canonical HUD / player shell;
- run / interruptible walk / exertion / encumbrance / run impact;
- System 19 finalized building grammar;
- System 20 local area/parcel planning + initial materialization;
- System 21 tactical camera/view control;
- System 22 bounded large-area critique runtime.

Art remains presentation truth; generation stores semantic IDs/facing only. Art is not physics.

## 5. System 19 final truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`

Stable building pipeline:

`request -> pure semantic building plan -> structural/profile validation -> initial WHAT + CLOSED Door State -> generation relinquishes ownership`

Protected library:

- `residential.trailer.singlewide` v2;
- `residential.house.farm_small` v2;
- `residential.house.farm_large` v4;
- `residential.house.compact_laundry` v1;
- `commercial.gas_station.small` v1;
- `commercial.diner.rural_small` v2.

System 20 uses System 19 only through public placement/generation/validation/materialization contracts.

## 6. System 20 current truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

Pure plan:

`AreaGenerationRequest -> inherited roads + profile-authorized local roads -> intersections -> parcels -> land use -> access -> System 19 placement requests -> primary-entry alignment -> straight approaches -> outdoor dressing -> GeneratedAreaValidator -> GeneratedAreaPlan`

Current Candidate 005:

- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- `rural.crossroads` v4 + `temperate.rural` v3;
- inherited 5-cell primary E/W road preserved exactly;
- inherited 3-cell secondary N/S road preserved exactly;
- central signalized crossing `(1128,2128)`;
- two internal 3-cell gravel `local_rural` roads with bends and uncontrolled junctions;
- local roads have no boundary exits and do generate parcel frontage;
- inherited paved corridors use `ground.road_plain` plus one center-path yellow line;
- 3 commercial opportunities: gas station + diner + one vacancy;
- 6 residential parcels;
- 4 farmsteads;
- at least 6/10 residential+farmstead properties on local roads, including >=3 houses and >=3 farmsteads;
- residential/commercial average facade setback <=5 cells;
- farmstead average setback > residential and <=8 cells;
- zero generated parking cells;
- every occupied approach starts at the road-access anchor, remains perpendicular to frontage, and ends at the real generated primary exterior door with no lateral hook;
- >=60% non-road area remains unbuilt;
- deterministic tree/shrub/rock dressing uses low-frequency smooth 2D density noise plus independent per-cell coordinate hashing;
- no fake barns/stores, actors, vehicles, loot or outbreak scenes.

Pure-plan workflow/context: `verify/system20-local-area`.

### Initial materialization

`AreaMaterializationCoordinator.gd` consumes the validated plan, validates/regenerates all System 19 subplans, snapshots WHAT + Door State, writes terrain/outdoor props/buildings, initializes building doors CLOSED, rolls back on failure, and relinquishes generation ownership after success.

This is initial world creation only. Long-term save/streaming partition architecture remains future work.

## 7. System 21 camera truth

Design: `SYSTEM_DESIGNS/21_TACTICAL_CAMERA_VIEW_CONTROL.md`

Modes:

- `FOLLOW_PLAYER` default;
- `DETACHED` inspect/pan;
- `FOCUS_CELL`;
- `FOCUS_ACTOR`;
- `SCRIPTED` presentation transition.

Zoom presets:

1. Very Close — 1.75×;
2. Close — 1.35×;
3. Normal — 1.00× default;
4. Far — 0.75×;
5. Area — 0.50×.

Desktop: wheel zoom, middle-drag pan, Home recenter. Right-click stays reserved for future interaction UI.

Mobile: two-finger pan/pinch plus explicit `ZOOM - / CENTER / ZOOM +` controls.

Safari correction: explicit camera buttons activate directly on touch release and suppress the immediate synthetic mouse release. CENTER displays `FOLLOW`/`INSPECT` state and reliably returns to player follow.

Exact-head context: `verify/system21-camera-view`.

## 8. System 22 live critique truth

Design: `SYSTEM_DESIGNS/22_LARGE_AREA_CRITIQUE_RUNTIME.md`

Owners:

- `RuralCrossroadsCritiqueFixture.gd` — generates/materializes the current Rural Crossroads candidate, derives critique physics registrations from public plan facts, places player outside generated diner;
- `LargeAreaRenderWindowController.gd` — presentation-only moving renderer window.

Live behavior:

- logical world is the real 256×256 System 20 area;
- all 12 existing-library buildings exist together in WHAT;
- player starts one cell outside the generated diner primary door and normal movement/System 18 doors work immediately;
- renderer draws an 80×96-cell window at 24 px/cell rather than scanning 65,536 cells every frame;
- renderer window shifts near its edge while preserving stable global world-cell positions;
- System 21 camera follows/pans/zooms independently of simulation.

Exact-head context: `verify/system22-area-critique`.

## 9. Current live demo

The live Web build is the generated **Rural Crossroads Candidate 005** after deployment of the current exact head.

This remains a DEV critique world: no zombies, population, loot, vehicles or outbreak layer is invented merely to make the area look busy.

Use the build to judge local-road shape/frontage, interior development, residential/farm spacing, facade setbacks, fields, straight door approaches, commercial-center composition, and environmental noise distribution.

## 10. Immediate next path

1. User playtests/visually critiques Candidate 005 property-door alignment.
2. Fix any remaining System 20 rural morphology/environment rules while preserving accepted System 19 baselines.
3. Once rural morphology is accepted, add new System 19 profiles freely as content or test another area/environment combination.
4. Design global world planning / long-term streaming-save architecture only when the next world-scale requirement demands it.

## 11. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholders/fake completion.
4. Generation creates initial truth; WHAT owns subsequent reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. Cross-region infrastructure is globally coordinated.
9. Inherited regional roads are preserved; System 20 may add profile-authorized local roads that do not invent boundary exits.
10. Local roads may own parcel frontage when their area profile explicitly permits it.
11. System 20 areas are planning domains, not streaming chunks.
12. System 19 owns building internals; accepted baselines remain protected.
13. System 20 may read public generated primary-entry facts to align parcel access without reaching into prefab internals.
14. Settlement morphology and ecological environment stay separate.
15. Open space is legitimate output but may receive environment-appropriate natural dressing.
16. Natural environmental sampling must be genuinely two-dimensional.
17. Large building setbacks require an explicit land-use purpose; empty grass is not implicit parking.
18. System 21 camera never mutates simulation.
19. System 22 is DEV presentation/integration, not a new world-planning owner.

## 12. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context;
8. IMPLEMENTED/APPROVED system designs;
9. DRAFT designs;
10. compatible master design;
11. golden/same-owner history.
