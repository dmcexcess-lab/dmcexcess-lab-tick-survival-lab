# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

System 00D plus Systems 14–22 and System 00F Slice 001 form the current canonical world-planning/materialization/playable path. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 00D Global World Planning Slices 001–006 are implemented.** The global plan establishes geography, settlement/site intent, globally coherent major roads, hydrology/bridge intent, regional electrical service, potable-water service and wastewater/septic service topology before System 20 local planning.

**System 19 is finalized.** New building profiles are ordinary content work unless the frozen grammar contract proves insufficient.

**System 20 has three protected local profiles covering all five current System 00D settlement sites:** Rural Crossroads Candidate 006 (`rural.crossroads` v5), Small-Town Center Candidate 001 (`smalltown.center` v1), and Rural-Scattered / Hamlet Candidate 001 (`rural.scattered` v1). All use `temperate.rural` v3.

**System 00F Streaming / Materialization Slice 001 is implemented.** Technical stream regions now drive on-demand one-time materialization of current logical area sites without becoming world identity. Materialization is one-way; activation is reversible; inactive facts remain in authoritative WHAT.

**System 21 Tactical Camera / View Control is implemented.** Player-follow is default; zoom, detached inspection, recenter, focus and scripted seams are presentation-only.

**System 22 Large-Area DEV Critique Runtime is implemented.** The live Web build still presents Rural Crossroads Candidate 006; 00F did not switch presentation targets.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. Implemented canonical stack

Dedicated canonical validation includes WHERE / WHAT / WHEN; collision/movement/locomotion; recovered Art and layer renderers; Door State/System 18; hands/inventory/item transfer; actor stats/status domains; canonical HUD/player shell; run/exertion/encumbrance; finalized System 19 building grammar; System 20 crossroads/small-town/rural-scattered local planning and one-area materialization; **System 00F one-way materialization + reversible technical activation**; System 21 camera; System 22 critique runtime; and System 00D global geography/hydrology/settlement/road/utility planning.

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

- profile `temperate.rural.region` v6;
- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse 128-cell geography records;
- one rural crossroads, one smalltown, three rural hamlets;
- connected primary/secondary road network with real gateways;
- one deterministic regional river and explicit bridge intents;
- regional electrical ingress/substation/service/feed topology;
- mixed municipal/decentralized potable-water intent;
- mixed municipal/decentralized wastewater/septic intent;
- five 256×256 logical local-area site records;
- no WHAT mutation, rendering, population/outbreak or streaming ownership.

Pure source lives under `game/scripts/generation/world/`; the separate downstream adapter is `game/scripts/generation/integration/System20AreaRequestProjector.gd`.

### Global -> local integration

- `area.rural.crossroads.001` -> protected `rural.crossroads` v5 Candidate 006;
- `area.smalltown.center.001` -> `smalltown.center` v1;
- `area.rural.scattered.001/.002/.003` -> `rural.scattered` v1.

Small-town consumes normalized power/water/wastewater/hydrology planning constraints. Rural hamlets consume exact inherited roads plus regional power and decentralized groundwater/septic service intent without fake utility facilities.

Read-only 00D -> downstream seams remain hydrology, power, potable water and wastewater constraint queries.

Exact-head context: `verify/system00d-global-world`.

## 6. System 19 final truth

Design: `SYSTEM_DESIGNS/19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md`.

Protected library: Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1, Small Gas Station v1, Rural Diner v2.

Exact-head context: `verify/system19-local-building`.

## 7. System 20 current truth

Umbrella: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`.

Small-town: `SYSTEM_DESIGNS/20A_SMALLTOWN_CENTER_CANDIDATE_001.md`.

Rural-scattered: `SYSTEM_DESIGNS/20B_RURAL_SCATTERED_CANDIDATE_001.md`.

### Rural Crossroads Candidate 006 — protected live anchor

- bounds `Rect2i(1000,2000,256,256)`, seed `20001`;
- inherited primary/secondary roads + two bent local gravel roads;
- gas station + diner + honest vacancy;
- six residential + four farmstead occupied opportunities;
- majority local-road residential/farm frontage;
- close meaningful setbacks and primary-door-aligned approaches;
- real road-flush building-owned parking only where exposed;
- >=60% non-road area unbuilt;
- deterministic 2D natural dressing.

### Small-Town Center Candidate 001

- `smalltown.center` v1 + `temperate.rural` v3;
- consumes actual System 00D v6 road/utility/hydrology facts;
- reusable infrastructure reservations + semantic town blocks;
- connected internal paved `local_town` network;
- four commercial opportunities: gas station + diner + honest vacancies;
- ten residential opportunities favoring local-town frontage;
- real System 19 door alignment and parking rules preserved.

### Rural-Scattered / Hamlet Candidate 001

- `rural.scattered` v1 + `temperate.rural` v3;
- all three current hamlet sites supported;
- exact inherited road truth + two internal 3-cell gravel `local_rural` lanes;
- zero commercial, four residential, two farmstead occupied targets;
- >=4/6 occupied properties on local lanes;
- >=72% non-road area unbuilt;
- decentralized groundwater/septic remain service intent only;
- real System 19 primary-door approaches preserved.

`AreaMaterializationCoordinator.gd` remains the lower-level transactional one-area initial WHAT + Door State writer. It is composed by 00F rather than rewritten.

Exact-head context: `verify/system20-local-area`.

## 8. System 00F current truth

Design: `SYSTEM_DESIGNS/00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md`.

Implemented owners under `game/scripts/streaming/`:

- `StreamingRegionGrid.gd`;
- `MaterializationRecord.gd`;
- `MaterializationRegistry.gd`;
- `AreaSiteMaterializationSource.gd`;
- `WorldMaterializationCoordinator.gd`;
- `WorldStreamingCoordinator.gd`.

Canonical Slice 001 rules:

1. **Logical source != technical stream region.** Current source keys are `system20_area_site:<site_id>` and never depend on stream-grid coordinates.
2. Default technical grid is injected 256×256 regions, origin at global world bounds, radius-1 active square. The current fixture happens to be 7×7; that is technical only.
3. If any active technical region intersects a virgin current area site, 00F materializes the entire logical site exactly once through the public 00D -> System20 -> System19 -> WHAT/Door pipeline.
4. Materialization Registry prevents every later revisit from rerunning generation/materialization.
5. Deactivation changes only ephemeral active-region bookkeeping. It never deletes terrain/entities, unregisters doors, consumes ticks or resets persistent state.
6. Multi-source initial writes snapshot WHAT + Door State + registry and roll all three back if any requested missing source fails.
7. Registry has deterministic schema-v1 snapshot/restore but is not a save-file codec.
8. Source-free active regions are valid and create no fake countryside.
9. Real memory eviction is deferred until an authoritative persistence-backed inactive-world store exists.
10. 00F imports no player, renderer, camera, AI, collision or WHEN owner.

Verification explicitly proves a real generated Crossroads door remains OPEN after deactivation/revisit, all five sites coexist in one WHAT, an induced future-site stable-ID collision rolls back exactly, registry round-trips, and out-of-world focus cannot mutate state.

First green integrated code head: `1841dc99e9f6731388dc9b730bb2959e38d575ba`.

Exact-head context: `verify/system00f-streaming-materialization`.

## 9. System 21 / 22 presentation truth

System 21 owns camera behavior only and never mutates simulation. System 22 owns the bounded DEV moving render-window composition only.

The live Web build remains Rural Crossroads Candidate 006. System 00F Slice 001 is independently proven orchestration and does not yet replace the presentation/composition path.

## 10. Immediate next path

1. Keep System 00D Slices 001–006 and all three current System 20 profiles protected.
2. Keep System 00F Slice 001's one-way materialization / reversible activation contract protected.
3. **Recommended next logical-world slice: design arbitrary rural-open/countryside local materialization** so the broad world between the five settlement sites can become real detailed WHAT instead of remaining source-free planning space.
4. A later persistence/save owner is required before 00F may implement true inactive-region memory eviction.
5. System 00E population/household/outbreak/player-story work remains a valid separate major design after enough logical homes/workplaces/world coverage exist.
6. Richer System 19 settlement content and parcel addresses/ownership/zoning remain separately designable content/system work.
7. Do not turn planned regional utilities into runtime utility mechanics without their own approved downstream owners.

## 11. Invariants

1. Main/root is composition only.
2. Focused owners/public contracts; no god state or fake completion.
3. Generation creates initial truth; WHAT owns subsequent reality.
4. Rendering presents truth; input submits semantic intent; Art is not physics.
5. Phone/Safari is first-class.
6. System 00D owns cross-region geography/hydrology/settlement/major-road/infrastructure coherence.
7. Global planning regions and System 20 areas are logical facts, never streaming chunks.
8. System 20 preserves inherited regional facts and adds only profile-authorized local content.
9. System 19 owns building internals; System 21 owns camera; System 22 is DEV presentation.
10. **Technical streaming activation is not world existence.**
11. **Materialization is one-way; activation is reversible.**
12. A materialized source is never regenerated merely because it left/reentered the active set.
13. Stream boundaries never invent, clip or redefine roads, rivers, utilities, parcels or buildings.
14. Deactivation alone never destroys or removes persistent WHAT facts.
15. Memory eviction requires an authoritative backing-store design first.
16. Source-free technical regions may exist honestly until a logical countryside source is designed.

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
