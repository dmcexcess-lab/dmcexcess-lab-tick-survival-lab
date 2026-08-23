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

**System 00D Global World Planning Slices 001–006 are implemented.** The global plan now establishes geography, settlement/site intent, globally coherent major roads, one deterministic regional river, explicit bridge intents, regional electrical service, potable-water service, and wastewater/septic service topology before System 20 local planning.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 Rural Crossroads Candidate 006 is the accepted local-area integration anchor.** Current profiles remain `rural.crossroads` v5 + `temperate.rural` v3. Its roads, local frontage, farms, setbacks, door-aligned approaches, ecological noise and road-flush building-owned parking frontage remain protected.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; zoom, detached inspection, recenter, focus and scripted seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The live game still materializes/renders Candidate 006. System 00D infrastructure remains upstream/headless planning truth.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical stack

Dedicated canonical validation includes WHERE / WHAT / WHEN; collision/movement/locomotion; recovered Art and layer renderers; Door State/System 18; hands/inventory/item transfer; actor stats/status domains; canonical HUD/player shell; run/exertion/encumbrance; finalized System 19 building grammar; System 20 local area/materialization; System 21 camera; System 22 critique runtime; and **System 00D geography + hydrology + settlements + major roads + bridge intent + regional electrical + potable-water + wastewater/septic infrastructure + read-only System 20 projection seams**.

Art remains presentation truth; generation stores semantic IDs/facing only. Art is not physics.

## 5. System 00D current truth

Umbrella: `SYSTEM_DESIGNS/00D_GLOBAL_WORLD_PLANNING.md`

Hydrology: `SYSTEM_DESIGNS/00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`

Electrical: `SYSTEM_DESIGNS/00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`

Potable water: `SYSTEM_DESIGNS/00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`

Wastewater/septic: `SYSTEM_DESIGNS/00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md`

Current pure order:

`GlobalWorldGenerationRequest -> geography -> hydrology -> settlements/sites -> hydrology-aware major roads -> bridge intents -> regional electrical infrastructure -> potable water infrastructure -> wastewater/septic infrastructure -> planning regions -> validation -> GeneratedGlobalWorldPlan`

Current global fixture:

- profile `temperate.rural.region` **v6**;
- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse 128-cell geography records with lowland/rolling/upland/ridge;
- five settlements: one rural crossroads, one smalltown, three rural hamlets;
- connected primary/secondary major-road network with real gateways and protected central 640-cell half-span;
- one deterministic boundary-to-boundary primary river outside the protected central corridor;
- settlement river clearance, high road crossing cost, no road/river collinear overlap, and one explicit bridge intent per real perpendicular crossing;
- one deterministic regional electrical ingress, one small-town substation, five electrical settlement-service nodes, and one connected road-following feeder network;
- five potable-water services: small-town municipal groundwater plus decentralized groundwater-source intent for crossroads + three hamlets;
- three small-town municipal water planning anchors and two road-contained municipal trunk segments;
- five wastewater services: small-town municipal treatment plus decentralized septic intent for crossroads + three hamlets;
- every rural septic service carries `potable_source_clearance_required`;
- two small-town wastewater anchors (`settlement_collection`, `treatment_disposal`) and one road-contained municipal collection trunk;
- wastewater corridor selection excludes the potable-water source direction and positive-length potable-water trunk overlap;
- broad rural-open background plus settlement influence regions and five local-area site records;
- no WHAT materialization, streaming, population, outbreak, renderer, camera or UI ownership.

Pure source lives under `game/scripts/generation/world/` and imports no System 19/20 owner. The separate integration adapter is `game/scripts/generation/integration/System20AreaRequestProjector.gd`.

### Global -> local integration anchor

Central site remains `area.rural.crossroads.001`, bounds `Rect2i(1000,2000,256,256)`, seed `20001`, using inherited roads `road.region.primary.001` + `road.region.secondary.001`, `rural.crossroads` + `temperate.rural`.

`project_site()` still produces the exact accepted System 20 request shape and Candidate 006 semantic output. Slices 003–006 do not inject unsupported tactical bridge/power/water/wastewater content into `AreaGenerationRequest`.

Read-only seams:

- `hydrology_constraints_for_bounds(plan, bounds)` -> clipped river + bridge facts;
- `power_constraints_for_bounds(plan, bounds)` -> clipped feeder + power-node facts;
- `water_constraints_for_bounds(plan, bounds)` -> settlement water-service intent + municipal water nodes/trunks where present;
- `wastewater_constraints_for_bounds(plan, bounds)` -> settlement wastewater-service intent + municipal wastewater nodes/trunk where present.

Candidate 006 exposes decentralized groundwater-source intent and decentralized-septic intent only: no municipal water/wastewater nodes or trunks and no visible well/septic infrastructure. The future small-town site already exposes both municipal water and wastewater planning anchors/trunks even though `smalltown.center` remains unsupported.

Exact-head context: `verify/system00d-global-world`.

## 6. System 19 final truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`.

Protected library: Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1, Small Gas Station v1, Rural Diner v2.

## 7. System 20 current truth

Design: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`.

Candidate 006 remains bounds `Rect2i(1000,2000,256,256)`, seed `20001`, `rural.crossroads` v5 + `temperate.rural` v3; inherited 5-cell primary + 3-cell secondary road; two internal bent gravel roads; majority local-road residential/farm frontage; gas station + diner + honest vacancy; close meaningful setbacks; primary-door-aligned approaches; road-flush building-owned parking where actually present; >=60% non-road area unbuilt; deterministic 2D natural dressing.

`AreaMaterializationCoordinator.gd` remains one-time transactional initial WHAT + Door State materialization only. Streaming/save orchestration remains future System 00F.

Exact-head context: `verify/system20-local-area`.

## 8. System 21 / 22 presentation truth

System 21 owns camera behavior only and never mutates simulation. System 22 owns the bounded DEV moving render-window composition only.

The live Web build remains Candidate 006. Global river/bridge, electrical, potable-water and wastewater/septic facts are currently headless semantic planning truth by design.

## 9. Immediate next path

1. Keep Candidate 006 frozen as the central local integration anchor.
2. Keep System 00D Slices 001–006 protected as the current global geography/settlement/road/hydrology/utility baseline.
3. **Move next into the real System 20 `smalltown.center` profile.** The regional utility skeleton is now stable enough that small-town parcels, civic/service opportunities and local streets can consume it rather than redefine it.
4. Follow `smalltown.center` with the `rural.scattered` / hamlet profile needed by the remaining global sites.
5. Do not turn power facts into tactical electricity, potable-water facts into physical plumbing, or wastewater facts into physical sewer/septic mechanics until downstream owners are explicitly designed.
6. Design System 00F streaming only after logical places/local profiles are stable enough that partitions are technical only.
7. Design System 00E population/outbreak/player story after stable world places provide real homes/workplaces/properties.

## 10. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state or fake completion.
3. Generation creates initial truth; WHAT owns subsequent reality.
4. Rendering presents truth; input submits semantic intent; Art is not physics.
5. Phone/Safari is first-class.
6. System 00D owns cross-region geography, hydrology, settlement, major-road and regional infrastructure coherence.
7. Global planning cells/regions are logical facts, never streaming chunks.
8. Pure System 00D does not import System 20; the projector is the downstream adapter.
9. System 20 preserves inherited regional facts and adds only profile-authorized local content.
10. System 19 owns building internals; System 21 owns camera; System 22 is DEV presentation.
11. Streaming consumes global logical truth; streaming boundaries never invent roads, rivers or infrastructure.
12. Bridge intent is global planning truth, not tactical bridge implementation.
13. Regional power nodes/feeders are planning truth, not tactical poles/wires or energized state.
14. Potable-water services/anchors/trunks are planning truth, not literal wells/towers/pipes, plumbing, pressure or runtime water state.
15. Wastewater services/anchors/trunk are planning truth, not literal septic/sewer/treatment geometry or runtime sanitation state.

## 11. Documentation source order

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
