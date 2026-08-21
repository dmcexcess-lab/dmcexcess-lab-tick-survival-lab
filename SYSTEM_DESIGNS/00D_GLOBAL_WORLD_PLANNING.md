# Tick Survival Lab — System 00D Global World Planning

Status: **SLICE 001 + SLICE 002 IMPLEMENTED**

Date: 2026-08-21

## 1. Goal

System 00D creates the deterministic **large-scale semantic plan** that must exist before local areas, streaming partitions, population or outbreak simulation can be coherent.

Its job is to answer global questions such as:

- where are broad geography/landform facts;
- where are rural/settlement planning regions;
- where are settlements and rural crossroads;
- which major roads connect them and cross the wider world;
- which local planning sites should later be refined by System 20;
- which inherited major-road facts must a local System 20 request preserve.

System 00D is a pure planning system. It does not materialize WHAT and does not render anything.

Canonical hierarchy:

`world seed -> System 00D global plan -> System 20 local area plan -> System 19 building plan -> initial WHAT -> persistent runtime mutation`

Streaming/storage remains a later consumer of this logical world plan, never its owner.

## 2. Slice 001 — regional skeleton

Slice 001 implemented one deterministic **temperate rural regional skeleton** large enough to prove the upstream/downstream contract without pretending to finish all world generation.

It contains:

- one global planning request and pure generated plan;
- broad rural + settlement influence regions;
- one central rural crossroads;
- one small-town anchor;
- several rural hamlet anchors;
- one connected major-road network using globally stable cardinal road segments;
- local-area site records with future System 20 profile hints;
- a separate System 20 projection adapter;
- deterministic validation and CI;
- a hard integration proof that the accepted Rural Crossroads local area can be produced from global facts without changing its inherited-road request seam.

The accepted rural crossroads is intentionally used as the integration anchor. The global fixture is centered so that the central 256x256 local site is exactly:

`Rect2i(1000, 2000, 256, 256)`

with center:

`Vector2i(1128, 2128)`

and the projected request preserves:

- area ID `area.rural.crossroads.001`;
- seed `20001`;
- primary road ID `road.region.primary.001`;
- secondary road ID `road.region.secondary.001`;
- existing `rural.crossroads` / `temperate.rural` profile selection.

This is an integration anchor, not a permanent requirement that every future world contain this exact location.

## 3. Slice 002 — geography / landform constraints

Slice 002 is implemented as the approved next bounded System 00D extension.

The purpose is to stop placing settlements and routing major roads across abstract empty space. The regional skeleton now reacts to coarse physical landform facts while preserving the proven central System 20 integration anchor.

### 3.1 Slice 002 adds

- deterministic coarse **global geography cells** covering the full System 00D bounds;
- an integer coarse elevation value and semantic landform class for each geography cell;
- landform classes `lowland`, `rolling`, `upland`, and `ridge`;
- one broad protected central lowland/rolling basin/cross around the accepted rural-crossroads anchor;
- settlement placement that starts from the Slice 001 desired anchors but snaps non-central settlements to nearby legal lowland/rolling geography;
- major-road routing over the coarse geography lattice;
- deterministic cardinal route segments that prefer lowland/rolling terrain, penalize upland, and refuse ridge cells;
- a protected straight central road cross that spans the accepted center, all four immediately adjacent 256x256 local windows, **and one additional 256-cell safety width beyond them** before geography-aware bends may begin;
- independent validation that settlements occupy legal landform and that major-road centerlines do not cross ridge geography;
- seed replay/variation tests proving geography, settlements and route topology are deterministic and terrain-constrained.

### 3.2 Slice 002 deliberately does not add

- rivers, lakes or hydrology;
- detailed heightmaps or per-tactical-cell elevation;
- slopes/physics or movement penalties;
- bridges/tunnels;
- utilities;
- population;
- streaming;
- tactical rendering of the global geography;
- local System 20 terrain overrides based on elevation.

Hydrology is the next natural geography extension after this slice, but it is not faked here.

## 4. Non-goals

System 00D does **not** own or implement:

- local/minor roads;
- parcels, driveways, sidewalks or parking;
- building envelopes/interiors/furniture;
- local vegetation/clutter;
- detailed tactical elevation;
- rivers/hydrology in Slice 002;
- utilities/infrastructure beyond the major-road seam;
- addresses;
- households, businesses as social actors, population or jobs;
- vehicles;
- outbreak/infection/emergency simulation;
- player identity/story selection;
- WHAT materialization;
- save-file format;
- streaming/materialization partition size;
- camera, rendering, UI or strategic-map presentation;
- travel-time/gameplay rules.

Those remain future systems or downstream owners.

## 5. Ownership / modules

Pure System 00D owners live under `game/scripts/generation/world/`:

- `GlobalWorldSeed.gd` — stable named global sub-seeds and coordinate hashing;
- `GlobalWorldGenerationRequest.gd` — caller world constraints;
- `GeneratedGlobalWorldPlan.gd` — immutable-by-convention pure semantic result + signature;
- `GlobalWorldProfileCatalog.gd` — global planning profiles/versions;
- `GlobalGeographyPlanner.gd` — coarse deterministic elevation/landform cells;
- `GlobalGeographyQuery.gd` — read-only geography lookup and route/settlement suitability queries;
- `GlobalSettlementPlanner.gd` — settlement anchors and local-area site intent constrained by geography;
- `GlobalMajorRoadPlanner.gd` — geography-aware major-road route network;
- `GlobalPlanningRegionPlanner.gd` — broad rural/settlement influence regions;
- `GeneratedGlobalWorldValidator.gd` — generic full-plan correctness;
- `GlobalWorldPlanner.gd` — coordinator only.

The narrow downstream adapter lives separately under `game/scripts/generation/integration/`:

- `System20AreaRequestProjector.gd` — reads public global-plan facts and produces an existing System 20 `AreaGenerationRequest`.

The adapter is not the owner of either system.

## 6. Public contract

### `GlobalWorldGenerationRequest`

Required fields:

- `world_id: String`;
- `seed: int`;
- `bounds: Rect2i` in canonical global tactical-cell coordinates;
- `profile_id: StringName`.

The request does not contain streaming/chunk size.

### `GeneratedGlobalWorldPlan`

Public semantic collections:

- provenance: world ID, seed, bounds, profile ID/version;
- `geography_cells: Array[Dictionary]`;
- `regions: Array[Dictionary]`;
- `settlements: Array[Dictionary]`;
- `road_segments: Array[Dictionary]`;
- `area_sites: Array[Dictionary]`;
- `failure_reason`;
- deterministic `signature()`.

All coordinates are canonical global `Vector2i`/`Rect2i` facts.

### Geography-cell record

Slice 002 records:

- stable `id`;
- coarse grid coordinate;
- `rect` covering part of the global request bounds;
- integer `elevation` in `0..100` as a planning value, not tactical physics;
- semantic `landform` (`lowland`, `rolling`, `upland`, `ridge`).

Geography cells tile the global bounds without overlap. Their size is profile-controlled and is a **planning resolution, not a streaming partition size**.

### Settlement record

Records:

- stable `id`;
- semantic `kind` (`rural_crossroads`, `smalltown`, `rural_hamlet`);
- global `center`;
- coarse influence radius;
- associated local-area site ID where applicable.

The central rural-crossroads center remains fixed for the integration anchor. Non-central desired anchors may move to a nearby legal geography cell through bounded deterministic search.

A settlement is not yet a population, government or business simulation.

### Global road-segment record

Records:

- stable `road_id`;
- semantic `road_class` (`primary` or `secondary`);
- cardinal global `start` / `end`;
- odd physical width;
- route-family ID.

A named route may contain several road segments. Slice 002 bends routes around landform by composing multiple cardinal segments while preserving the existing local clipping contract.

### Planning-region record

Uses broad semantic influence regions:

- stable `id`;
- `kind` (`rural_open`, `rural_crossroads`, `smalltown`, `rural_settlement`);
- `rect`;
- priority;
- downstream area/environment profile hints.

These are **logical planning regions, not streaming/storage chunks**. Overlap is legal when higher-priority settlement influence sits inside a broad rural background region.

### Local-area site record

A site records a location that a later local planner may refine:

- stable `id`;
- associated settlement ID;
- bounds;
- deterministic local seed;
- area-profile hint;
- environment-profile hint.

A profile hint may name a future not-yet-implemented local profile. That is planning intent, not fake local content. The System 20 adapter must reject unsupported hints rather than fabricate a substitute.

## 7. System 20 projection seam

`System20AreaRequestProjector` remains the only System 00D-adjacent code allowed to import System 20 request/profile types.

For a supported site it:

1. reads the site bounds/profile hints;
2. clips every intersecting global cardinal major-road segment to those bounds;
3. ignores zero-length tangent contacts that do not place a road segment inside the requested area;
4. preserves the global road segment's stable ID, class and width;
5. marks only real clipped boundary endpoints as allowed boundary cells;
6. constructs the existing `AreaGenerationRequest`;
7. returns failure instead of inventing a local profile or silently accepting substantial global geometry that the current inherited-road contract cannot represent.

Pure files under `generation/world/` do not import System 20.

Slice 002 preserves a straight protected central cross with `protected_cross_half_span = 640`. Relative to the 256x256 central site, this covers the center, each immediately adjacent critique window, and another full local-area width before an outer geography-aware route is permitted to bend. This was required because an earlier 384-cell half-span let the first coarse-lattice bend begin inside an adjacent local window even though the center itself remained correct.

The correction was made in the **global planner**, not by weakening the projector. The central local site therefore continues to receive exactly one `road.region.primary.001` and one `road.region.secondary.001` constraint with the same IDs, widths and geometry as the accepted local inherited-road baseline; adjacent windows receive clean continuous inherited segments; outer routes may bend only farther away.

## 8. Temperate rural regional profile

Profile:

`temperate.rural.region` v2

The profile produces:

- one central `rural_crossroads` settlement fixed to the request center;
- one `smalltown` desired anchor generally east of center;
- multiple `rural_hamlet` desired anchors;
- a 128-cell coarse geography lattice across the whole region;
- a protected central basin/cross around the local integration anchor;
- settlement snapping to nearby lowland/rolling geography;
- one connected primary route and secondary route family;
- geography-aware secondary branches connecting off-axis hamlets;
- broad `rural_open` background plus settlement influence regions.

Non-central settlement desired positions and geography vary deterministically by seed. There are no unbounded reroll loops.

## 9. Geography generation rules

1. Geography is generated before settlements and roads.
2. Coarse cells are aligned to the global request bounds, not to streaming partitions.
3. Elevation comes from deterministic mixed-coordinate 2D value noise plus a smaller secondary noise component and bounded peak boosts.
4. Elevation is clamped into `0..100`.
5. Landform bands are profile thresholds over elevation.
6. Cells intersecting the protected central integration basin/cross are capped to lowland/rolling terrain so the protected road geometry remains legal.
7. Same request + profile version yields identical geography.
8. Different seeds alter geography outside the protected integration anchor.

## 10. Settlement geography rules

1. The central rural crossroads remains exactly at the global request center.
2. Its site bounds remain exactly the accepted System 20 integration bounds.
3. Other settlement roles first compute the same semantic desired direction/distance as Slice 001.
4. Each non-central settlement performs a bounded search over nearby geography cells.
5. Settlement-legal cells are `lowland` or `rolling` only.
6. Selection minimizes distance from the desired anchor, with deterministic grid-coordinate tie-breaking.
7. The resulting 256x256 local site must still fit inside global bounds.
8. No reroll loops are permitted.

## 11. Major-road geography rules

1. Roads remain semantic cardinal global segments.
2. Named routes may contain multiple segments.
3. Routing uses the coarse geography lattice only; it does not materialize tactical cells.
4. `lowland` is cheapest, `rolling` mildly penalized, `upland` strongly penalized, and `ridge` is forbidden for Slice 002 roads.
5. Route search is deterministic four-neighbor A* over the coarse geography lattice.
6. Route path cells are converted into cardinal tactical-coordinate segments and collinear sections are merged.
7. The central protected primary and secondary segments are emitted first with their existing stable IDs.
8. Geography-aware outer route segments connect those protected segments to boundary gateways and settlement anchors.
9. Every settlement center lies on at least one major-road segment.
10. All road segments belong to one connected network.
11. Real boundary gateways remain present.
12. No bridge/tunnel exception exists in Slice 002; ridge crossings are validation failures.

## 12. Determinism / identity

Same request + profile version must produce the same plan signature.

Different seeds must change at least some geography plus non-central settlement/route geometry while keeping all validation rules true.

Named global sub-seeds isolate unrelated planning domains.

Stable IDs derive from semantic role/route/ordinal, never array address, Node identity or renderer state.

Intentional same-seed output changes require a global-profile version bump.

## 13. Validation

`GeneratedGlobalWorldValidator` independently verifies:

- provenance;
- all stable IDs are non-empty and unique within the plan;
- geography cells tile the global bounds without overlap/gaps;
- geography elevations are `0..100` and landform values are valid;
- regions/sites are inside global bounds;
- settlements are inside bounds and not collapsed onto one another;
- settlements occupy legal lowland/rolling geography;
- all major-road segments are non-zero cardinal lines with odd width;
- road endpoints are inside bounds;
- major-road centerlines do not intersect `ridge` geography;
- the road-segment network is connected;
- every settlement center lies on a global major-road segment;
- every non-boundary road endpoint is justified by a settlement or intersection with another road segment;
- the network exposes real regional boundary gateways;
- every area site contains its associated settlement center;
- no system/presentation/runtime fact is embedded in the plan.

The validator owns correctness, not generation strategy.

## 14. Slice 002 acceptance tests

Dedicated CI now proves:

1. same-seed deterministic replay including geography;
2. different-seed legal geography variation outside the protected central anchor;
3. geography cells fully tile the global bounds;
4. the world contains multiple landform classes rather than one flat label;
5. settlements occupy lowland/rolling cells;
6. at least one outer major route bends for the canonical seed rather than every road remaining one straight axis;
7. no major-road centerline crosses a ridge cell;
8. the major-road network remains connected and exposes boundary gateways;
9. the central rural-crossroads site exactly preserves the accepted local bounds/ID/seed/profile hints;
10. projected central `AreaGenerationRequest` remains semantically identical to the current `RuralCrossroadsPlanFixture.request(20001)` inherited-road request;
11. System 20 still generates successfully from the projected request and matches the current local fixture output;
12. west/east/north/south adjacent central projection windows observe continuous shared `road.region.primary.001` / `road.region.secondary.001` segments;
13. unsupported future local-profile sites still fail projection honestly;
14. pure 00D source imports no System 19/20, WHAT mutation, renderer, camera, UI, player, streaming or reboot owner.

## 15. Data ownership

System 00D owns only the generated **initial global plan**.

It does not mutate WHAT and does not own later runtime changes.

Future save/world-creation orchestration may persist the generated global plan as immutable world provenance or reconstruct it deterministically, but gameplay never asks System 00D to overwrite a location already owned by persistent world state.

## 16. Performance

Slice 002 remains coarse planning.

For the canonical regional fixture, the 1792x1792 global bounds produce a 14x14 lattice: **196 geography records**, not millions of tactical cells. Route search runs only at world creation and uses bounded deterministic graph work. No per-frame work exists.

Future much larger worlds must preserve this coarse-plan property; global planning must not require materializing every tactical cell merely to know where towns, ridges and highways are.

## 17. Safari/mobile

No direct input/UI exists in Slice 002.

The system remains presentation-free so mobile performance is affected only when a later viewer or materializer consumes its output.

## 18. Forbidden dependencies

Pure `generation/world/` code must not import:

- `generation/areas/` or `generation/buildings/`;
- WHAT mutation/materialization owners;
- WHEN;
- render/art;
- camera;
- input/UI/player;
- reboot/reference runtime;
- future streaming implementation.

Only the separate System 20 projection adapter may import the public System 20 request/profile contract.

## 19. Future extension seams

Without rewriting the Slice 002 plan contract, later 00D work may add focused owners/records for:

- rivers/hydrology and bridge crossing intent;
- richer biome/climate facts;
- richer settlement hierarchy/districts;
- road-route grouping refinements;
- utilities/infrastructure;
- zoning/addresses;
- world-scale land-use constraints.

Downstream future systems may consume the global plan for:

- System 20 local refinement;
- System 00F streaming/materialization orchestration;
- System 00E households/population/jobs/player story;
- vehicle/travel networks;
- utility and outbreak simulation.

Those consumers must not move ownership of global coherence out of 00D.

## 20. North-star fit

The North Star requires top-down generation to establish geography before settlements/roads/local detail and requires roads/infrastructure to be globally coherent before streaming boundaries are considered.

Slice 002 advances exactly that hierarchy: coarse physical landform is upstream truth, settlements react to it, and major roads route through it. The slice stays deliberately simpler than a terrain simulator because its purpose is to preserve believable world-scale constraints and future consequences, not to simulate geology.

## 21. Approved decisions

Approved by the user on 2026-08-21:

1. System 00D remains the active major system before streaming.
2. Slice 002 adds coarse deterministic elevation/landform constraints before richer global topology.
3. Settlement placement and major-road routing must react to those landforms.
4. Rivers/hydrology are deferred rather than faked inside Slice 002.
5. The accepted central rural crossroads remains the protected local integration anchor while the larger world becomes geography-aware.
6. In parallel as a small System 20 refinement, a commercial prefab whose real road-facing edge is parking/paved frontage must have that paved frontage meet the road directly; this does not authorize a System 19 prefab rewrite.

## 22. Implementation result

Slice 001 and Slice 002 are implemented and independently verified.

Current canonical global fixture:

- world bounds `Rect2i(232,1232,1792,1792)`;
- world seed `20001`;
- profile `temperate.rural.region` v2;
- **196** coarse 128-cell geography records forming a 14x14 lattice;
- deterministic elevation and `lowland` / `rolling` / `upland` / `ridge` classes;
- real ridge constraints in the canonical seed;
- five settlement anchors: one rural crossroads, one smalltown, three rural hamlets, all on legal lowland/rolling geography;
- one connected primary/secondary regional-road network with geography-aware outer bends and real boundary gateways;
- no major-road centerline crossing a ridge;
- one broad rural-open background plus five settlement influence regions;
- five local-area site records;
- protected central straight-road half-span of **640 cells**, keeping geography-aware bends outside the center and its immediately adjacent 256x256 windows.

The central site projects through `System20AreaRequestProjector` into an `AreaGenerationRequest` semantically identical to the current rural-crossroads fixture request at the inherited-road seam. System 20 generates the current Candidate 006 local area from those facts. Adjacent central projection windows preserve continuous shared primary/secondary road crossings, while unsupported future local profiles still fail honestly.

Dedicated exact-head context: `verify/system00d-global-world`.
