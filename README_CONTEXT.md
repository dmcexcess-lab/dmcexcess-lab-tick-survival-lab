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

**System 00D Global World Planning — Geography / Landform Slice 002 is implemented.** `temperate.rural.region` v2 now creates deterministic coarse geography before settlements and major roads. The canonical 1792x1792 regional fixture contains 196 coarse 128-cell geography records with elevation and `lowland` / `rolling` / `upland` / `ridge` landforms. Non-central settlements snap to legal low/rolling geography; outer major roads route through the geography lattice, penalize upland and refuse ridge cells.

The central rural-crossroads integration anchor remains `Rect2i(1000,2000,256,256)` with seed `20001`. Its protected primary/secondary straight-road cross now uses a **640-cell half-span**, keeping geography-aware bends outside the center and its immediately adjacent 256x256 critique windows. The separate `System20AreaRequestProjector` remains strict: zero-length tangent contacts are ignored, but substantial unsupported internal road geometry still fails rather than being hidden.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 Rural Crossroads Candidate 006 is the current local-area integration anchor.** Current profiles are `rural.crossroads` v5 + `temperate.rural` v3. Candidate 006 preserves the accepted roads, farms, compact setbacks, straight primary-door approaches and ecological noise while adding one generic morphology rule: if a generated System 19 building exposes a real `ground.parking*` semantic on its road-facing edge, System 20 extends that same paved surface to the road. No parking is invented for buildings without a real parking frontage.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; five discrete zoom levels, detached inspection, recenter, focus and scripted/cutscene seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The canonical live game materializes and renders the current Rural Crossroads local plan. System 00D remains pure upstream planning rather than a fake strategic/world viewer.

Immediate active work remains **upstream world planning/design**, not streaming yet.

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
- **System 00D global geography + settlement + geography-aware major-road planning + System 20 projection seam**;
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

`GlobalWorldGenerationRequest -> coarse geography -> settlement anchors/sites -> geography-aware global major-road network -> broad planning regions -> GeneratedGlobalWorldValidator -> GeneratedGlobalWorldPlan`

Current Slice 002:

- profile `temperate.rural.region` v2;
- fixture bounds `Rect2i(232,1232,1792,1792)`;
- seed `20001`;
- 14x14 = **196** coarse geography records at 128-cell planning resolution;
- deterministic elevation `0..100` plus `lowland`, `rolling`, `upland`, `ridge`;
- protected low/rolling central basin/cross;
- five settlements: one fixed rural crossroads, one smalltown, three rural hamlets;
- non-central settlements use bounded deterministic snapping to low/rolling geography;
- one connected primary/secondary road network with outer cardinal bends selected by deterministic four-neighbor geography routing;
- lowland cheapest, rolling mildly penalized, upland strongly penalized, ridge forbidden;
- no major-road centerline through ridge geography;
- real regional boundary gateways;
- broad rural-open background plus five settlement influence regions;
- five local-area site records with area/environment profile hints;
- no WHAT materialization, streaming, population, outbreak, renderer, camera or UI ownership.

Pure 00D source lives under `game/scripts/generation/world/` and does not import System 20.

The only downstream bridge is `game/scripts/generation/integration/System20AreaRequestProjector.gd`, which clips global road segments into an existing `AreaGenerationRequest` and rejects unsupported future local profiles or substantial unsupported inherited-road geometry instead of fabricating substitutes.

Integration anchor:

- global site `area.rural.crossroads.001`;
- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- road IDs `road.region.primary.001` + `road.region.secondary.001`;
- `rural.crossroads` + `temperate.rural`;
- protected central cross half-span **640**;
- projected request equals the current Rural Crossroads fixture request semantically at the inherited-road seam;
- System 20 generates current Candidate 006 from that request;
- adjacent west/east/north/south windows preserve continuous primary/secondary inherited segments before geography-aware bends begin farther out.

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

System 20 uses System 19 only through public placement/generation/validation/materialization contracts. Candidate 006 additionally reads public generated semantic ground facts; it does not inspect or modify prefab internals.

## 7. System 20 current truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`

Pure plan:

`AreaGenerationRequest -> inherited roads + profile-authorized local roads -> intersections -> parcels -> land use -> access -> System 19 placement requests -> primary-entry alignment -> real parking-frontage discovery -> straight approaches -> paved-frontage connection -> outdoor dressing -> GeneratedAreaValidator -> GeneratedAreaPlan`

Current Candidate 006:

- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- `rural.crossroads` v5 + `temperate.rural` v3;
- inherited 5-cell primary E/W road and 3-cell secondary N/S road supplied by System 00D global facts;
- central signalized crossing `(1128,2128)`;
- two internal 3-cell gravel `local_rural` roads with bends and uncontrolled junctions;
- at least 6/10 residential+farmstead properties on local roads, including >=3 houses and >=3 farmsteads;
- 3 commercial opportunities: gas station + diner + one vacancy;
- residential/commercial average facade setback <=5 cells;
- farmstead average setback > residential and <=8 cells;
- every occupied approach remains perpendicular to frontage and ends at the real generated primary exterior door;
- gas-station `ground.parking_faded` frontage is physically continued to the road because the generated building exposes parking on its actual road-facing edge;
- diner/houses receive no fake parking apron because they expose no qualifying parking frontage;
- empty grass is still **not implicit parking**;
- >=60% non-road area remains unbuilt;
- deterministic 2D tree/shrub/rock dressing;
- no fake barns/stores, actors, vehicles, loot or outbreak scenes.

Exact-head context: `verify/system20-local-area`.

### Initial materialization

`AreaMaterializationCoordinator.gd` consumes the validated local plan, validates/regenerates all System 19 subplans, snapshots WHAT + Door State, writes terrain/outdoor props/buildings including real parking-apron ground, initializes building doors CLOSED, rolls back on failure, and relinquishes generation ownership after success.

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

- `RuralCrossroadsCritiqueFixture.gd` — materializes the current Rural Crossroads plan and places the player outside its generated diner;
- `LargeAreaRenderWindowController.gd` — presentation-only moving renderer window.

Live behavior:

- logical world currently shown is the 256×256 Candidate 006 local area;
- all 12 existing-library buildings exist together in WHAT;
- player starts one cell outside the generated diner primary door;
- renderer draws an 80×96-cell moving window at 24 px/cell;
- System 21 camera follows/pans/zooms independently of simulation.

System 22 does not yet render the whole 00D regional plan; no fake strategic/world viewer was added to make global planning appear more complete than it is.

Exact-head context: `verify/system22-area-critique`.

## 10. Current live demo

The live Web build materializes the current **Rural Crossroads Candidate 006** local plan.

System 00D wraps that area in a verified larger geography-aware logical regional plan without pretending that multiple regions are already streamed/rendered. This is intentional: world planning is upstream truth, while presentation/streaming of multiple local areas remains future work.

## 11. Immediate next path

1. Keep Candidate 006 frozen as the current local integration anchor unless a new live critique reveals a bounded defect.
2. The next natural **System 00D design slice** is hydrology/rivers plus explicit bridge-crossing intent; design/approval comes before implementation and no river behavior should be faked into the current landform slice.
3. Add new System 20 profiles such as `smalltown.center` / `rural.scattered` when we are ready to materialize the other real 00D settlement sites.
4. Design System 00F streaming/materialization only after logical global geography/roads/places are stable enough that partition boundaries are purely technical.
5. Design System 00E population/households/outbreak/player story after stable world places exist for people to inhabit.

## 12. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state.
3. No placeholders/fake completion.
4. Generation creates initial truth; WHAT owns subsequent reality.
5. Rendering presents truth; input submits semantic intent.
6. Art is not physics.
7. Phone/Safari is first-class.
8. **System 00D owns cross-region geography/settlement/major-road coherence.**
9. System 00D geography is upstream of settlement placement and major-road routing.
10. Major roads may not cross `ridge` geography until a future explicitly designed bridge/tunnel/hydrology rule authorizes a real exception.
11. System 00D planning regions/geography cells are logical planning facts, never streaming/storage chunks.
12. Pure System 00D code does not import System 20; the separate projector is the only downstream adapter.
13. System 20 preserves inherited regional roads and may add profile-authorized local roads that do not invent boundary exits.
14. Local roads may own parcel frontage when their area profile explicitly permits it.
15. System 20 areas are planning domains, not streaming chunks.
16. System 19 owns building internals; accepted baselines remain protected.
17. System 20 may read public generated primary-entry and semantic ground facts without reaching into prefab internals.
18. A System 20 paved commercial apron may exist only when a generated building exposes a real road-facing `ground.parking*` edge; empty setback space never becomes implicit parking.
19. Settlement morphology and ecological environment stay separate.
20. Open space is legitimate output but may receive environment-appropriate natural dressing.
21. Natural environmental sampling must be genuinely two-dimensional.
22. Large building setbacks require an explicit land-use purpose.
23. System 21 camera never mutates simulation.
24. System 22 is DEV presentation/integration, not a world-planning owner.
25. Streaming consumes global logical truth; streaming boundaries never invent world geometry.

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
