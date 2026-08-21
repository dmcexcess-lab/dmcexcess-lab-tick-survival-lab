# Tick Survival Lab — System 00D Global World Planning

Status: **IMPLEMENTED — REGIONAL SKELETON SLICE 001**

Date: 2026-08-20

## 1. Goal

System 00D creates the deterministic **large-scale semantic plan** that must exist before local areas, streaming partitions, population or outbreak simulation can be coherent.

Its job is to answer global questions such as:

- where are broad rural/settlement planning regions;
- where are settlements and rural crossroads;
- which major roads connect them and cross the wider world;
- which local planning sites should later be refined by System 20;
- which inherited major-road facts must a local System 20 request preserve.

System 00D is a pure planning system. It does not materialize WHAT and does not render anything.

Canonical hierarchy:

`world seed -> System 00D global plan -> System 20 local area plan -> System 19 building plan -> initial WHAT -> persistent runtime mutation`

Streaming/storage remains a later consumer of this logical world plan, never its owner.

## 2. Approved first implementation slice

Slice 001 implements one deterministic **temperate rural regional skeleton** large enough to prove the upstream/downstream contract without pretending to finish all world generation.

The slice contains:

- one global planning request and pure generated plan;
- broad rural + settlement influence regions;
- one central rural crossroads;
- one small-town anchor;
- several rural hamlet anchors;
- one connected major-road network using globally stable cardinal road segments;
- local-area site records with future System 20 profile hints;
- a separate System 20 projection adapter;
- deterministic validation and CI;
- a hard integration proof that the accepted Rural Crossroads Candidate 005 can be produced from global facts without changing its local semantic signature.

The current accepted rural crossroads is intentionally used as the Slice 001 integration anchor. The global fixture is centered so that the central 256x256 local site is exactly:

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

## 3. Non-goals

System 00D Slice 001 does **not** own or implement:

- local/minor roads;
- parcels, driveways, sidewalks or parking;
- building envelopes/interiors/furniture;
- local vegetation/clutter;
- detailed elevation, rivers or hydrology;
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

## 4. Ownership / modules

Pure System 00D owners live under `game/scripts/generation/world/`:

- `GlobalWorldSeed.gd` — stable named global sub-seeds;
- `GlobalWorldGenerationRequest.gd` — caller world constraints;
- `GeneratedGlobalWorldPlan.gd` — immutable-by-convention pure semantic result + signature;
- `GlobalWorldProfileCatalog.gd` — global planning profiles/versions;
- `GlobalSettlementPlanner.gd` — settlement anchors and local-area site intent;
- `GlobalMajorRoadPlanner.gd` — major-road segment network;
- `GlobalPlanningRegionPlanner.gd` — broad rural/settlement influence regions;
- `GeneratedGlobalWorldValidator.gd` — generic full-plan correctness;
- `GlobalWorldPlanner.gd` — coordinator only.

The narrow downstream adapter lives separately under `game/scripts/generation/integration/`:

- `System20AreaRequestProjector.gd` — reads public global-plan facts and produces an existing System 20 `AreaGenerationRequest`.

The adapter is not the owner of either system.

## 5. Public contract

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
- `regions: Array[Dictionary]`;
- `settlements: Array[Dictionary]`;
- `road_segments: Array[Dictionary]`;
- `area_sites: Array[Dictionary]`;
- `failure_reason`;
- deterministic `signature()`.

All coordinates are canonical global `Vector2i`/`Rect2i` facts.

### Settlement record

Slice 001 records:

- stable `id`;
- semantic `kind` (`rural_crossroads`, `smalltown`, `rural_hamlet`);
- global `center`;
- coarse influence radius;
- associated local-area site ID where applicable.

A settlement is not yet a population, government or business simulation.

### Global road-segment record

Slice 001 records:

- stable `road_id`;
- semantic `road_class` (`primary` or `secondary`);
- cardinal global `start` / `end`;
- odd physical width;
- optional route-family ID.

A road segment is a global topology edge. Named routes may later group many segments without changing the local clipping contract.

### Planning-region record

Slice 001 uses broad semantic influence regions:

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

## 6. System 20 projection seam

`System20AreaRequestProjector` is the only Slice 001 code allowed to import System 20 request/profile types.

For a supported site it:

1. reads the site bounds/profile hints;
2. clips every intersecting global cardinal major-road segment to those bounds;
3. preserves the global road segment's stable ID, class and width;
4. marks only real clipped boundary endpoints as allowed boundary cells;
5. constructs the existing `AreaGenerationRequest`;
6. returns failure instead of inventing a local profile or silently dropping an unsupported global geometry case.

Pure files under `generation/world/` do not import System 20.

Slice 001 deliberately keeps the central integration road segments straight through the accepted crossroads site so the current System 20 inherited-road contract can represent them exactly.

## 7. Slice 001 regional profile

Initial global profile:

`temperate.rural.region` v1

The profile produces a connected regional skeleton around the request center:

- one central `rural_crossroads` settlement fixed to the request center;
- one `smalltown` anchor along the primary regional corridor;
- multiple `rural_hamlet` anchors on secondary corridors;
- one boundary-to-boundary primary corridor;
- one boundary-to-boundary secondary corridor;
- additional secondary branches connecting off-axis hamlets;
- broad `rural_open` background plus settlement influence regions.

Non-central settlement distances/branch positions vary deterministically by seed while respecting bounded spacing and world edges.

There are no unbounded reroll loops.

## 8. Determinism / identity

Same request + profile version must produce the same plan signature.

Different seeds must change at least some non-central settlement/branch geometry while keeping all validation rules true.

Named global sub-seeds isolate unrelated planning domains.

Stable IDs derive from semantic role/ordinal, never array address, Node identity or renderer state.

Intentional same-seed output changes require a global-profile version bump.

## 9. Validation

`GeneratedGlobalWorldValidator` must independently verify:

- provenance;
- all stable IDs are non-empty and unique within their namespace/plan;
- regions/sites are inside global bounds;
- settlements are inside bounds and not collapsed onto one another;
- all major-road segments are non-zero cardinal lines with odd width;
- road endpoints are inside bounds;
- the road-segment network is connected;
- every settlement center lies on a global major-road segment;
- every non-boundary road endpoint is justified by a settlement or intersection with another road segment;
- the network exposes real regional boundary gateways;
- every area site contains its associated settlement center;
- no system/presentation/runtime fact is embedded in the plan.

The validator owns correctness, not generation strategy.

## 10. Slice 001 acceptance tests

Dedicated CI must prove:

1. same-seed deterministic replay;
2. different-seed legal variation;
3. central rural crossroads site exactly matches the accepted Candidate 005 bounds/ID/seed/profile hints;
4. global central primary/secondary road segments clip to the exact current Candidate 005 inherited-road constraints;
5. projected central `AreaGenerationRequest` is semantically identical to `RuralCrossroadsPlanFixture.request(20001)`;
6. existing System 20 generates the projected request successfully;
7. its resulting semantic signature equals the current Candidate 005 signature from the existing fixture request;
8. adjacent arbitrary projection windows observe matching shared boundary crossings from the same global road segments;
9. all settlements connect through one global major-road network;
10. boundary gateways are preserved;
11. unsupported future local-profile sites fail projection honestly;
12. pure 00D source imports no System 19/20, WHAT mutation, renderer, camera, UI, player, streaming or reboot owner.

## 11. Data ownership

System 00D owns only the generated **initial global plan**.

It does not mutate WHAT and does not own later runtime changes.

Future save/world-creation orchestration may persist the generated global plan as immutable world provenance or reconstruct it deterministically, but gameplay never asks System 00D to overwrite a location already owned by persistent world state.

## 12. Performance

Slice 001 operates on a small number of semantic records, not every tactical cell in the world.

Roads are line segments, settlements are points, regions/sites are rectangles. No per-frame work exists.

Future much larger worlds must preserve this coarse-plan property; global planning must not require materializing every tactical cell merely to know where towns and highways are.

## 13. Safari/mobile

No direct input/UI exists in Slice 001.

The system must remain presentation-free so mobile performance is affected only when a later viewer or materializer consumes its output.

## 14. Forbidden dependencies

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

## 15. Future extension seams

Without rewriting the Slice 001 plan contract, later 00D work may add focused owners/records for:

- geography/elevation/biomes;
- rivers/hydrology;
- richer settlement hierarchy/districts;
- road-route grouping and more varied cardinal topology;
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

## 16. North-star fit

The North Star requires one logically continuous persistent world whose major roads/infrastructure are globally coherent before local detail or streaming boundaries are considered.

System 00D provides exactly that upstream semantic truth while remaining small enough to replace independently. It does not build a strategic-map game layer, does not reintroduce raid maps, and does not confuse planning regions with streaming chunks.

## 17. Approved decisions

Approved by the user on 2026-08-20:

1. System 20 Candidate 005 is accepted enough to stop polishing the isolated rural test and move upstream.
2. Global World Planning is the next major system before streaming.
3. The first implementation slice is a deterministic regional skeleton: settlements/rural regions + coherent major roads + System 20 projection seam.
4. No streaming, population, utilities, outbreak or new local building content is bundled into Slice 001.
5. The accepted Candidate 005 rural crossroads is used as a hard integration anchor so global planning extends the world around proven local work rather than invalidating it.

## 18. Implementation result

Slice 001 is implemented and independently verified.

Current canonical fixture:

- world bounds `Rect2i(232,1232,1792,1792)`;
- world seed `20001`;
- five settlement anchors: one rural crossroads, one smalltown, three rural hamlets;
- one connected primary/secondary regional-road network with four global road segments and real boundary gateways;
- one broad rural-open background plus five settlement influence regions;
- five local-area site records.

The central site projects through `System20AreaRequestProjector` into an `AreaGenerationRequest` semantically identical to the existing Candidate 005 fixture request. System 20 then produces the exact same Candidate 005 semantic plan signature. Adjacent projection windows preserve continuous shared primary/secondary road crossings.

Dedicated exact-head context: `verify/system00d-global-world`.
