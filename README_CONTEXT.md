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

**System 19 is finalized.** New building profiles are normal content work by default.

**System 20 Candidate 001 is implemented through both pure planning and a separate one-time transactional initial-materialization owner.** The current profile is `rural.crossroads + temperate.rural`, 256×256 global cells, existing System 19 building library only.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; five discrete zoom levels, detached inspection, recenter, focus and scripted/cutscene seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The canonical live game now materializes and renders the generated rural crossroads rather than the old isolated diner fixture.

The immediate active work is **user visual/playable critique of System 20 Candidate 001**.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical stack

Dedicated canonical validation now includes:

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

`AreaGenerationRequest -> inherited roads/intersection -> parcels -> land use -> access -> System 19 placement requests -> driveways -> outdoor dressing -> GeneratedAreaValidator -> GeneratedAreaPlan`

Current Candidate 001:

- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- `rural.crossroads` v1 + `temperate.rural` v1;
- one inherited 5-cell primary E/W road;
- one inherited 3-cell secondary N/S road;
- central crossing `(1128,2128)`;
- exactly one signalized crossroads;
- zero local road spurs;
- 3 commercial opportunities: gas station + diner + one vacancy;
- 6 residential parcels;
- 4 farmsteads;
- remaining frontage agricultural/vacant/wilderness;
- >=60% non-road area unbuilt;
- no fake barns/stores, actors, vehicles, loot or outbreak scenes.

Pure-plan workflow/context: `verify/system20-local-area`.

### Initial materialization

`AreaMaterializationCoordinator.gd` separately consumes the validated plan, validates/regenerates all System 19 subplans, snapshots WHAT + Door State, writes terrain/outdoor props/buildings, initializes building doors CLOSED, rolls back on failure, and relinquishes generation ownership after success.

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

- `RuralCrossroadsCritiqueFixture.gd` — generates/materializes Candidate 001, derives critique physics registrations from public plan facts, places player outside generated diner;
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

The live Web build is now the **generated Rural Crossroads Candidate 001**, not the standalone diner.

This is intentionally still a DEV critique world: no zombies, population, loot, vehicles or outbreak layer has been invented merely to make the area look busy.

Use the build to judge roads, scale, parcel spacing, farms, driveways, building orientation, density gradient, commercial-center composition and outdoor dressing.

## 10. Immediate next path

1. User playtests/visually critiques Candidate 001.
2. Fix area/profile rules that look wrong while preserving accepted building baselines.
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
9. System 20 areas are planning domains, not streaming chunks.
10. System 19 owns building internals; accepted baselines remain protected.
11. Settlement morphology and ecological environment stay separate.
12. Open space is legitimate output.
13. System 21 camera never mutates simulation.
14. System 22 is DEV presentation/integration, not a new world-planning owner.

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
