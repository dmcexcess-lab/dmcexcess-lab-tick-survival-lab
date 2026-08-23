# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, active system design(s), and `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle: **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current phase

System 00D plus Systems 14–22 and System 00F Slices 001–002 form the current canonical world-planning/materialization/playable path. `game/scripts/reboot/` remains frozen/deprecated reference only.

**System 00D Global World Planning Slices 001–006 are implemented.** The global plan establishes geography, settlements/sites, major roads, hydrology/bridge intent, regional electrical service, potable-water service and wastewater/septic topology before local generation.

**System 19 is finalized.** Current protected building library: Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1, Small Gas Station v1 and Rural Diner v2.

**System 20 has four implemented local profiles:**

- Rural Crossroads Candidate 006 — `rural.crossroads` v5;
- Small-Town Center Candidate 001 — `smalltown.center` v1;
- Rural-Scattered / Hamlet Candidate 001 — `rural.scattered` v1;
- Rural-Open / Countryside Candidate 001 — `rural.open` v1.

All use `temperate.rural` v3.

The first three cover all five current System 00D settlement sites. `rural.open` provides arbitrary dry countryside generation inside the broad global rural-open planning context.

**System 00F Streaming / Materialization Slices 001–002 are implemented.** Technical stream regions drive one-time materialization of stable logical sources while remaining independent from source identity. Materialization is one-way; activation is reversible; inactive facts remain in authoritative WHAT.

Current logical source kinds are:

- `system20_area_site:<site_id>` for the five settlement sites;
- `system20_rural_open:<source_id>` for geography-derived dry countryside fragments.

Countryside source catalog v1 subtracts exact settlement-source bounds and the exact currently unsupported river corridors. Dry land is therefore materializable throughout the rural-open context while river corridor cells remain honestly source-free until physical local hydrology/bridges are implemented.

**Active design:** `SYSTEM_DESIGNS/20D_RURAL_WATERCOURSE_BRIDGE_CANDIDATE_001.md` is **DRAFT**. It proposes the next bounded physical-generation slice: consume existing System 00D river/bridge facts and make them deterministic semantic water/bridge terrain while leaving 00F source discovery for a later 00F Slice 003.

**System 21 Tactical Camera / View Control is implemented.**

**System 22 Large-Area DEV Critique Runtime is implemented.** The live Web build still presents Rural Crossroads Candidate 006.

## 3. Foundation truth

### WHERE
Global integer cells, ~1m planning scale, N/E/S/W facing, whole-cell footprints, structure cells with H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with stable IDs, semantic terrain/entities, WHERE placements and typed mechanic state.

### WHEN
One deterministic integer world tick, variable-duration actions/events, tactical decision pause plus separate hard application pause.

## 4. System 00D current truth

Umbrella: `SYSTEM_DESIGNS/00D_GLOBAL_WORLD_PLANNING.md`.

Current profile: `temperate.rural.region` **v6**.

Current global fixture:

- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse 128-cell geography records with elevation + lowland/rolling/upland/ridge;
- one rural crossroads, one smalltown and three rural hamlets;
- connected primary/secondary major-road network with real gateways;
- one deterministic regional river + explicit bridge intents;
- regional power ingress/substation/settlement service/feed topology;
- municipal small-town + decentralized rural potable-water intent;
- municipal small-town + decentralized rural wastewater/septic intent;
- five 256×256 settlement `area_site` records;
- one broad `region.rural.open.001` planning context with `area_profile_hint = rural.open`;
- no WHAT mutation, renderer, population/outbreak or streaming ownership.

System 00D hydrology already owns river IDs/segments, odd physical widths, exact road/river crossings and bridge intents. Local work must consume those facts rather than reroute them.

Pure source lives under `game/scripts/generation/world/`; downstream projection adapter is `game/scripts/generation/integration/System20AreaRequestProjector.gd`.

Exact-head context: `verify/system00d-global-world`.

## 5. System 20 current truth

Umbrella: `SYSTEM_DESIGNS/20_LOCAL_AREA_PARCEL_GENERATION.md`.

Implemented detailed designs:

- `20A_SMALLTOWN_CENTER_CANDIDATE_001.md`;
- `20B_RURAL_SCATTERED_CANDIDATE_001.md`;
- `20C_RURAL_OPEN_COUNTRYSIDE_CANDIDATE_001.md`.

Active DRAFT:

- `20D_RURAL_WATERCOURSE_BRIDGE_CANDIDATE_001.md`.

### Crossroads 006

Protected live anchor with inherited crossroads + two gravel local roads, gas station/diner/vacancy, residential/farm local-road majority, close setbacks, real primary-door access, real parking frontage and deterministic rural dressing.

### Small-Town 001

Consumes actual System 00D roads + utility/hydrology facts. Uses reusable local infrastructure reservations, semantic town blocks, connected local paved streets, honest current-library commercial occupancy/vacancy and denser residential frontage.

### Rural-Scattered 001

Covers all three hamlets. Preserves exact inherited regional road truth, adds two orientation-independent gravel local lanes, has zero commercial center, exactly four residential + two farmstead occupied opportunities, and consumes decentralized utility service intent without inventing facilities.

### Rural-Open 001

`rural.open` v1 provides arbitrary caller-bounded **dry countryside**.

Public seam:

`System20AreaRequestProjector.project_rural_open_bounds(plan, area_id, bounds)`.

Canonical rules:

1. requested bounds must lie inside the broad System 00D rural-open planning context;
2. bounds may not overlap the five settlement area sites;
3. zero or more inherited regional roads are legal;
4. existing settlement profiles still require inherited roads;
5. clipped global geography must cover every request cell exactly once;
6. intersecting power/water/wastewater corridors are read-only context;
7. any real river/bridge intersection fails with `rural_open_hydrology_not_materializable` until local hydrology exists;
8. no local roads, town blocks, settlement parcels or buildings are produced;
9. lowland/rolling may receive coherent `ground.field_green` agricultural cover; upland/ridge do not;
10. trees/shrubs/rocks use global world seed + absolute global coordinates;
11. natural prop IDs are `rural_open.natural.<x>.<y>`, independent from area/source ID;
12. split-vs-combined dry countryside plans produce identical cell-level landscape truth.

Focused owner:

`game/scripts/generation/areas/RuralOpenLandscapePlanner.gd`.

`AreaGenerationRequest` supports optional `inherited_geography`; base roadlessness is valid, while LocalAreaGenerator enforces profile-specific road requirements.

`GeneratedAreaPlan` permits zero roads only for `rural.open` today.

System 20C did not change System 00D, System 19, area materialization, WHAT/WHEN, runtime physics, presentation or player code. System 00F2 consumes System 20C through its public arbitrary-bounds seam without changing countryside morphology.

Exact-head context: `verify/system20-local-area`.

First green 20C integrated code head: `cbc39f03d3568ca4fcbe7f294e350eb1c507bbda`.

### Proposed 20D Watercourse / Bridge 001

The DRAFT proposes:

- new `rural.watercourse` v1 while preserving every existing profile/version;
- optional explicit inherited hydrology request facts;
- request bounds wholly covered by real System 00D river corridor geometry;
- physical `ground.water_river` terrain;
- bridge-deck road terrain only when an explicit System 00D bridge intent authorizes it;
- explicit hydrology provenance in generated plans;
- no parcels/buildings/local roads/water props;
- split-vs-combined exact global-cell terrain semantics;
- no 00F source-discovery change in the 20D implementation.

The 13 detailed decisions at the end of the DRAFT require explicit user approval before code.

## 6. System 00F current truth

Umbrella: `SYSTEM_DESIGNS/00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md`.

Slice 002 detail: `SYSTEM_DESIGNS/00F2_COUNTRYSIDE_LOGICAL_SOURCE_MATERIALIZATION.md`.

Canonical rule:

> **Materialization is one-way; activation is reversible.**

Implemented owners under `game/scripts/streaming/` include:

- `StreamingRegionGrid.gd`;
- `MaterializationRecord.gd`;
- `MaterializationRegistry.gd`;
- `AreaSiteMaterializationSource.gd`;
- `CountrysideSourceCatalog.gd`;
- `CountrysideMaterializationSource.gd`;
- `WorldMaterializationCoordinator.gd`;
- `WorldStreamingCoordinator.gd`.

Current behavior:

- technical region grid defaults to 256×256 with radius-1 active square;
- region IDs are not logical world/source IDs;
- settlement source keys are `system20_area_site:<site_id>`;
- countryside source keys are `system20_rural_open:<source_id>` from catalog v1;
- countryside source identity derives from System 00D geography parent + final dry global rectangle, not stream-region coordinates;
- exact settlement-source bounds and exact river corridors are excluded from countryside ownership;
- every supported dry non-settlement/non-river cell belongs to exactly one countryside source;
- intersecting virgin settlement/countryside sources materialize exactly once through public System 20/19 materialization paths;
- mixed source batches commit atomically in stable source-key order;
- registry prevents revisit regeneration and remains snapshot schema v1;
- deactivation changes only technical active bookkeeping;
- player/world mutations survive deactivation/revisit;
- no memory eviction exists without an authoritative persistence-backed store;
- river corridor cells remain source-free/unmaterialized.

Exact-head context: `verify/system00f-streaming-materialization`.

Verified pre-promotion 00F2 code head: `abe3d56792b74d5dd08882bd4f06dbd76107f35d`.

## 7. System 21 / 22 presentation truth

System 21 owns camera behavior only. System 22 owns the bounded DEV moving render-window composition only.

The live Web build remains Rural Crossroads Candidate 006.

## 8. Immediate next path

**Active design gate: review/approve or revise System 20D Rural Watercourse / Bridge Candidate 001.**

The DRAFT intentionally separates two future steps:

1. **20D** — prove partition-independent local physical river/bridge terrain from existing System 00D truth;
2. **00F Slice 003 later** — give that proven river corridor stable logical materialization source ownership/activation without changing 00F2 dry-countryside IDs.

This prevents one river task from becoming a hidden System 20 + System 00F rewrite.

Other separate future slices:

- persistence/save owner before true memory eviction;
- sparse isolated rural properties now that dry source-boundary ownership is stable;
- System 00E population/households/jobs/outbreak/player story;
- richer System 19 content;
- parcel addresses/ownership/zoning;
- runtime utilities;
- later water gameplay/presentation after physical river truth exists.

## 9. Invariants

1. Main/root is composition only.
2. Generation creates initial truth; WHAT owns later reality.
3. System 00D owns global coherence.
4. System 20 preserves inherited global facts and creates only profile-authorized local physical facts.
5. System 19 owns building internals.
6. System 00F owns materialization orchestration/technical activation, not morphology.
7. Global planning regions, System 20 planning areas, logical materialization sources and technical stream regions are distinct concepts.
8. **Technical streaming activation is not world existence.**
9. **Materialization is one-way; activation is reversible.**
10. Stream boundaries never invent or redefine roads, rivers, utilities, parcels or landscape.
11. Deactivation never destroys persistent WHAT facts.
12. Rural-open landscape classification and natural identity are global-coordinate stable.
13. Countryside source identity is logical/catalog-versioned and independent from stream-region coordinates.
14. Known river terrain is never silently replaced with grass/fields.
15. Any physical bridge must be authorized by real global bridge intent; road overlap alone is insufficient.
16. Art is presentation truth, not physics.
17. Phone/Safari remains first-class.

## 10. Documentation source order

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
