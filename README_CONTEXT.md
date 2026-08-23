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

**System 00D Global World Planning Slices 001–006 are implemented.** The global plan establishes geography, settlement/site intent, globally coherent major roads, one deterministic regional river, explicit bridge intents, regional electrical service, potable-water service, and wastewater/septic service topology before System 20 local planning.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 now has three protected local profiles covering all five current System 00D settlement sites:** Rural Crossroads Candidate 006 (`rural.crossroads` v5) remains the accepted live integration anchor; Small-Town Center Candidate 001 (`smalltown.center` v1) is the infrastructure-aware settlement profile; and Rural-Scattered / Hamlet Candidate 001 (`rural.scattered` v1) covers all three planned hamlet sites. All three use `temperate.rural` v3.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; zoom, detached inspection, recenter, focus and scripted seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The live game still materializes/renders Rural Crossroads Candidate 006. Small-Town Candidate 001 and Rural-Scattered Candidate 001 are proven pure/integration profiles, not live critique-world switches.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical stack

Dedicated canonical validation includes WHERE / WHAT / WHEN; collision/movement/locomotion; recovered Art and layer renderers; Door State/System 18; hands/inventory/item transfer; actor stats/status domains; canonical HUD/player shell; run/exertion/encumbrance; finalized System 19 building grammar; System 20 local area/materialization with crossroads, small-town and rural-scattered profiles; System 21 camera; System 22 critique runtime; and **System 00D geography + hydrology + settlements + major roads + bridge intent + regional electrical + potable-water + wastewater/septic infrastructure + read-only System 20 projection seams**.

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

### Global -> local integration

Central site `area.rural.crossroads.001` remains the frozen Candidate 006 anchor. Its projected request and generated semantic signature remain exact and receive no infrastructure-reservation facts.

Small-town site `area.smalltown.center.001` projects successfully to `smalltown.center` v1. Its request consumes normalized regional hydrology/power/potable-water/wastewater facts through `inherited_planning_constraints`, which System 20 converts into reusable facility/corridor reservations before local roads/parcels are planned.

All three hamlet sites now project successfully to `rural.scattered` v1. They retain exact inherited regional-road geometry and consume regional power plus decentralized groundwater/septic service intent without inventing rural substations, wells, septic tanks or drain fields. The existing `potable_source_clearance_required` septic policy remains visible for future parcel-scale placement.

Road projection treats a regional segment lying solely along a local planning area's mathematical boundary as a boundary tangency rather than as an entering inherited road. This prevents false full-width corridors from extending outside the local area while preserving real road crossings/entries.

Read-only seams remain:

- `hydrology_constraints_for_bounds(plan, bounds)` -> clipped river + bridge facts;
- `power_constraints_for_bounds(plan, bounds)` -> clipped feeder + power-node facts;
- `water_constraints_for_bounds(plan, bounds)` -> settlement water-service intent + municipal water nodes/trunks where present;
- `wastewater_constraints_for_bounds(plan, bounds)` -> settlement wastewater-service intent + municipal wastewater nodes/trunk where present.

Exact-head context: `verify/system00d-global-world`.

## 6. System 19 final truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`.

Protected library: Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1, Small Gas Station v1, Rural Diner v2.

## 7. System 20 current truth

Umbrella: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`.

Small-town design: `SYSTEM_DESIGNS/20A_SMALLTOWN_CENTER_CANDIDATE_001.md`.

Rural-scattered design: `SYSTEM_DESIGNS/20B_RURAL_SCATTERED_CANDIDATE_001.md`.

### Rural Crossroads Candidate 006 — protected live anchor

- bounds `Rect2i(1000,2000,256,256)`, seed `20001`;
- `rural.crossroads` v5 + `temperate.rural` v3;
- inherited 5-cell primary + 3-cell secondary road;
- two internal bent gravel roads;
- majority local-road residential/farm frontage;
- gas station + diner + honest vacancy;
- close meaningful setbacks;
- primary-door-aligned approaches;
- road-flush building-owned parking where actually present;
- >=60% non-road area unbuilt;
- deterministic 2D natural dressing;
- no small-town reservations/blocks injected.

### Small-Town Center Candidate 001 — implemented pure/integration profile

- `smalltown.center` v1 + `temperate.rural` v3;
- consumes the actual System 00D v6 small-town inherited roads and regional utility/hydrology planning facts;
- reusable infrastructure facility/corridor reservations protect future utility land without faking final facilities;
- connected internal 3-cell paved `local_town` street network with no unauthorized boundary exits;
- semantic town blocks carved around blocking reservations;
- four center/main-road commercial opportunities: gas station + diner + at least two honest vacancies;
- ten residential opportunities with a majority on `local_town` frontage;
- inherited road frontage is clipped to the actual inherited segment extent;
- straight approaches terminate at real System 19 primary doors;
- existing road-flush building-owned parking rule remains active;
- Candidate 006 request and semantic signature remain exact.

### Rural-Scattered / Hamlet Candidate 001 — implemented three-site profile

- `rural.scattered` v1 + `temperate.rural` v3;
- all three System 00D v6 hamlet sites project/generate through the same profile while varying deterministically from their site seeds/road geometry;
- exact inherited regional-road truth is retained;
- two internal 3-cell gravel `local_rural` lanes branch from a selected cardinal inherited spine without unauthorized boundary exits;
- direct synthetic tests prove both horizontal and vertical inherited spines;
- exactly four residential + two farmstead opportunities, with at least four of six occupied properties on local-lane frontage;
- zero commercial targets and no semantic town blocks;
- only finalized System 19 residential/farmhouse archetypes are used;
- decentralized groundwater and septic service records are consumed as non-blocking intent only, preserving `potable_source_clearance_required` without fake facilities;
- regional power remains source-traceable and no rural substation is invented;
- >=72% of non-road area remains physically unbuilt;
- approaches still terminate at real System 19 primary doors;
- Crossroads 006 and Small-Town 001 remain exact protected regressions.

`AreaMaterializationCoordinator.gd` remains one-time transactional initial WHAT + Door State materialization only. Streaming/save orchestration remains future System 00F.

Exact-head context: `verify/system20-local-area`.

## 8. System 21 / 22 presentation truth

System 21 owns camera behavior only and never mutates simulation. System 22 owns the bounded DEV moving render-window composition only.

The live Web build remains Rural Crossroads Candidate 006. Small-Town Candidate 001 and Rural-Scattered Candidate 001 are deliberately not switched into the live critique runtime by their implementation slices.

## 9. Immediate next path

1. Keep Rural Crossroads Candidate 006 frozen as the central live/local integration anchor.
2. Keep Small-Town Center Candidate 001 and Rural-Scattered Candidate 001 protected as the remaining current System 20 settlement profiles.
3. Keep System 00D Slices 001–006 protected as the global geography/settlement/road/hydrology/utility baseline.
4. The recommended next architecture design is **System 00F streaming/materialization orchestration**, now that every current System 00D settlement site has a real logical local profile and streaming partitions can remain technical only.
5. Richer System 19 settlement content, parcel addresses/ownership/zoning, or System 00E population/household/outbreak/player-story work remain valid alternative next slices, but should be separately designed and approved.
6. Do not turn power facts into tactical electricity, potable-water facts into physical plumbing, or wastewater facts into physical sewer/septic mechanics until downstream owners are explicitly designed.
7. Do not let System 00F redefine roads, rivers, utilities, parcels or settlement morphology; it must consume the logical world truth already established.

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
16. System 20 infrastructure reservations are protected local planning land, not fake final utility facilities.
17. A regional road may terminate inside a local planning window; only actual boundary contact requires an authorized local boundary exit.
18. A regional road lying solely along a local planning-area boundary is tangential context, not an entering inherited road.
19. Rural decentralized water/septic service intent does not authorize System 20 to invent parcel-scale well/septic geometry.

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