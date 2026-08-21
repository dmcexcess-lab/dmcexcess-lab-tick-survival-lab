# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

System 00D plus Systems 14–22 form the current canonical world-planning/playable path. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 00D Global World Planning — Regional Skeleton Slice 001 is implemented.** `temperate.rural.region` v1 now creates a pure global semantic regional plan containing settlement anchors, broad planning regions, a connected major-road network and local-area site records before System 20 is invoked.

The first global fixture uses bounds `Rect2i(232,1232,1792,1792)` and seed `20001`. Its central rural-crossroads site is deliberately the already accepted Candidate 005 location. The separate `System20AreaRequestProjector` clips global major-road segments into the existing System 20 request contract. The central projection is semantically identical to the existing Candidate 005 request and produces the exact same System 20 plan signature. Adjacent arbitrary projection windows preserve continuous shared road exits.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 Rural Crossroads Candidate 005 is accepted as the current local-area integration anchor.** Current profiles are `rural.crossroads` v4 + `temperate.rural` v3. Roads, local-road frontage, farms, close setbacks, straight door-aligned approaches and ecological noise remain the protected downstream baseline for 00D integration.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; five discrete zoom levels, detached inspection, recenter, focus and scripted/cutscene seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The canonical live game still materializes and renders Candidate 005; System 00D is currently verified as pure planning rather than replacing the live scene.

Immediate active work moves **upstream inside System 00D**, not into streaming yet.

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
- **System 00D global regional skeleton planning + System 20 projection seam**;
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

## 5. System 00D current truth

Design: `SYSTEM_DESIGNS/00D_GLOBAL_WORLD_PLANNING.md`

Pure plan:

`GlobalWorldGenerationRequest -> settlement anchors/sites -> global major-road network -> broad planning regions -> GeneratedGlobalWorldValidator -> GeneratedGlobalWorldPlan`

Current Slice 001:

- profile `temperate.rural.region` v1;
- fixture bounds `Rect2i(232,1232,1792,1792)`;
- seed `20001`;
- five settlements: one rural crossroads, one smalltown, three rural hamlets;
- one boundary-to-boundary primary corridor;
- one boundary-to-boundary secondary corridor;
- two additional secondary settlement branches;
- one connected global road network with real boundary gateways;
- broad rural-open background plus five settlement influence regions;
- five local-area site records with area/environment profile hints;
- no WHAT materialization, streaming, population, outbreak, renderer, camera or UI ownership.

Pure 00D source lives under `game/scripts/generation/world/` and does not import System 20.

The only downstream bridge is `game/scripts/generation/integration/System20AreaRequestProjector.gd`, which clips global road segments into an existing `AreaGenerationRequest` and rejects unsupported future local profiles instead of fabricating substitutes.

Integration anchor:

- global site `area.rural.crossroads.001`;
- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- road IDs `road.region.primary.001` + `road.region.secondary.001`;
- `rural.crossroads` + `temperate.rural`;
- projected request equals the accepted Candidate 005 fixture request semantically;
- projected System 20 plan signature equals Candidate 005 exactly.

Exact-head context: `verify/system00d-global-world`.

## 6. System 19 final truth

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

## 7. System 20 current truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

Pure plan:

`AreaGenerationRequest -> inherited roads + profile-authorized local roads -> intersections -> parcels -> land use -> access -> System 19 placement requests -> primary-entry alignment -> straight approaches -> outdoor dressing -> GeneratedAreaValidator -> GeneratedAreaPlan`

Current Candidate 005:

- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- `rural.crossroads` v4 + `temperate.rural` v3;
- inherited 5-cell primary E/W road and 3-cell secondary N/S road now provably supplied by System 00D global facts;
- central signalized crossing `(1128,2128)`;
- two internal 3-cell gravel `local_rural` roads with bends and uncontrolled junctions;
- at least 6/10 residential+farmstead properties on local roads, including >=3 houses and >=3 farmsteads;
- 3 commercial opportunities: gas station + diner + one vacancy;
- residential/commercial average facade setback <=5 cells;
- farmstead average setback > residential and <=8 cells;
- zero generated parking cells;
- every occupied approach remains perpendicular to frontage and ends at the real generated primary exterior door;
- >=60% non-road area remains unbuilt;
- deterministic 2D tree/shrub/rock dressing;
- no fake barns/stores, actors, vehicles, loot or outbreak scenes.

Exact-head context: `verify/system20-local-area`.

### Initial materialization

`AreaMaterializationCoordinator.gd` consumes the validated local plan, validates/regenerates all System 19 subplans, snapshots WHAT + Door State, writes terrain/outdoor props/buildings, initializes building doors CLOSED, rolls back on failure, and relinquishes generation ownership after success.

This remains initial world creation only. Long-term save/streaming partition architecture is future System 00F ownership.

## 8. System 21 camera truth

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

## 9. System 22 live critique truth

Design: `SYSTEM_DESIGNS/22_LARGE_AREA_CRITIQUE_RUNTIME.md`

Owners:

- `RuralCrossroadsCritiqueFixture.gd` — materializes Candidate 005 and places the player outside its generated diner;
- `LargeAreaRenderWindowController.gd` — presentation-only moving renderer window.

Live behavior:

- logical world currently shown is the accepted 256×256 Candidate 005 local area;
- all 12 existing-library buildings exist together in WHAT;
- player starts one cell outside the generated diner primary door;
- renderer draws an 80×96-cell moving window at 24 px/cell;
- System 21 camera follows/pans/zooms independently of simulation.

System 22 does not yet render the whole 00D regional plan; no fake strategic/world viewer was added to make Slice 001 appear more complete than it is.

Exact-head context: `verify/system22-area-critique`.

## 10. Current live demo

The live Web build remains the accepted **Rural Crossroads Candidate 005**.

System 00D currently wraps that accepted area in a verified larger logical regional plan without changing the playable local result. This is intentional: world planning is now upstream truth, while presentation/streaming of multiple local areas remains future work.

## 11. Immediate next path

1. Keep Candidate 005 frozen as the accepted local integration anchor.
2. Continue System 00D with a bounded **geography / landform constraints** slice so future settlements and major roads must react to real world-scale terrain rather than abstract open space.
3. Expand major-road topology/routing only through those geography constraints, preserving the existing global->System20 clipping contract.
4. Add new System 20 profiles such as `smalltown.center` / `rural.scattered` when we are ready to materialize the other 00D settlement sites.
5. Design System 00F streaming/materialization only after logical global geography/roads/places are stable enough that partition boundaries are purely technical.
6. Design System 00E population/households/outbreak/player story after stable world places exist for people to inhabit.

## 12. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholders/fake completion.
4. Generation creates initial truth; WHAT owns subsequent reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. **System 00D owns cross-region geography/settlement/major-road coherence.**
9. System 00D planning regions are logical semantic regions, never streaming/storage chunks.
10. Pure System 00D code does not import System 20; the separate projector is the only downstream adapter.
11. System 20 preserves inherited regional roads and may add profile-authorized local roads that do not invent boundary exits.
12. Local roads may own parcel frontage when their area profile explicitly permits it.
13. System 20 areas are planning domains, not streaming chunks.
14. System 19 owns building internals; accepted baselines remain protected.
15. System 20 may read public generated primary-entry facts to align parcel access without reaching into prefab internals.
16. Settlement morphology and ecological environment stay separate.
17. Open space is legitimate output but may receive environment-appropriate natural dressing.
18. Natural environmental sampling must be genuinely two-dimensional.
19. Large building setbacks require an explicit land-use purpose; empty grass is not implicit parking.
20. System 21 camera never mutates simulation.
21. System 22 is DEV presentation/integration, not a world-planning owner.
22. Streaming consumes global logical truth; streaming boundaries never invent world geometry.

## 13. Documentation source order

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
