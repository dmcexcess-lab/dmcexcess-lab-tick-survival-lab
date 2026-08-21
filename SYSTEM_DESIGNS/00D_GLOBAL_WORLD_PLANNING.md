# Tick Survival Lab — System 00D Global World Planning

Status: **SLICE 001 + SLICE 002 + SLICE 003 IMPLEMENTED**

Date: 2026-08-21

## 1. Goal

System 00D owns deterministic **large-scale semantic world truth** before local planning, materialization, population, outbreak simulation or streaming.

Canonical hierarchy:

`world seed -> geography -> hydrology -> settlements/regions -> major roads + infrastructure intent -> System 20 local area -> System 19 buildings -> initial WHAT -> persistent runtime mutation`

System 00D is pure planning. It never materializes WHAT and never owns rendering, camera, local building layout or streaming partitions.

## 2. Current implemented slices

### Slice 001 — Regional Skeleton

Established:

- global request/plan/profile contracts;
- broad rural + settlement planning regions;
- one central rural crossroads, one smalltown and three rural hamlets;
- globally coherent primary/secondary road families with real boundary gateways;
- local-area site records carrying downstream profile hints;
- separate `System20AreaRequestProjector` integration owner;
- exact proof that the accepted central rural-crossroads area can be derived from global facts without changing the local inherited-road contract.

### Slice 002 — Geography / Landform Constraints

Added:

- 128-cell coarse geography lattice;
- deterministic planning elevation `0..100`;
- `lowland`, `rolling`, `upland`, `ridge` landforms;
- settlement placement limited to lowland/rolling geography;
- geography-aware cardinal major-road routing;
- lowland preference, rolling penalty, upland strong penalty, ridge prohibition;
- protected central lowland/rolling cross with `protected_cross_half_span = 640`, keeping geography-aware bends outside the accepted center and its immediately adjacent 256×256 planning windows.

### Slice 003 — Global Hydrology / Bridge Intent

Detailed design: `00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`.

Added:

- deterministic boundary-to-boundary regional river planning over the coarse geography lattice;
- hydrology clearance for settlement sites;
- hydrology-aware major-road crossing cost;
- prohibition on roads running collinearly along river centerlines;
- explicit global bridge-intent records for every real perpendicular road/river crossing;
- independent validation that crossings and bridge intents correspond exactly;
- read-only `System20AreaRequestProjector.hydrology_constraints_for_bounds()` seam for future local hydrology work;
- preserved Candidate 006 and its four immediately adjacent protected windows as hydrology-free integration anchors.

## 3. Current canonical fixture

Profile: `temperate.rural.region` **v3**.

Global fixture:

- bounds `Rect2i(232,1232,1792,1792)`;
- seed `20001`;
- 14×14 = 196 coarse geography cells;
- five settlement anchors;
- connected primary/secondary regional road network;
- one deterministic primary regional river outside the protected center;
- at least one topologically required road/river crossing represented by explicit bridge intent;
- broad rural-open region plus settlement influence regions;
- five local-area site records.

The protected central site remains:

- ID `area.rural.crossroads.001`;
- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- area profile `rural.crossroads`;
- environment profile `temperate.rural`;
- inherited road IDs `road.region.primary.001` and `road.region.secondary.001`.

Its projected System 20 request remains semantically identical to the current `RuralCrossroadsPlanFixture.request(20001)` request, and System 20 still produces the accepted Candidate 006 semantic output from those facts.

## 4. Owners

Pure owners under `game/scripts/generation/world/`:

- `GlobalWorldSeed.gd` — stable named sub-seeds and coordinate hashing;
- `GlobalWorldGenerationRequest.gd` — world constraints;
- `GeneratedGlobalWorldPlan.gd` — pure semantic result/signature;
- `GlobalWorldProfileCatalog.gd` — planning profiles/versions;
- `GlobalGeographyPlanner.gd` / `GlobalGeographyQuery.gd` — coarse landform truth;
- `GlobalHydrologyPlanner.gd` / `GlobalHydrologyQuery.gd` — river planning and read queries;
- `GlobalSettlementPlanner.gd` — geography/hydrology-constrained settlement/site intent;
- `GlobalMajorRoadPlanner.gd` — geography/hydrology-aware regional roads;
- `GlobalBridgeIntentPlanner.gd` — explicit bridge crossing intent;
- `GlobalPlanningRegionPlanner.gd` — broad planning regions;
- `GeneratedGlobalWorldValidator.gd` — independent full-plan correctness;
- `GlobalWorldPlanner.gd` — orchestration only.

Separate downstream adapter:

- `game/scripts/generation/integration/System20AreaRequestProjector.gd`.

Pure System 00D source does not import System 19, System 20, WHAT mutation, renderer/art, camera/input/UI/player, reboot code or future streaming ownership.

## 5. Public plan contract

`GeneratedGlobalWorldPlan` exposes semantic global-coordinate collections:

- provenance: world ID, seed, bounds, profile ID/version;
- `geography_cells`;
- `river_segments`;
- `regions`;
- `settlements`;
- `road_segments`;
- `bridge_intents`;
- `area_sites`;
- deterministic `signature()`;
- failure reason.

### Geography record

- stable ID;
- coarse grid coordinate;
- global `Rect2i`;
- planning elevation;
- semantic landform.

### River segment record

- stable segment ID and river ID;
- cardinal start/end;
- odd physical width;
- downstream ordinal.

### Settlement/site records

Settlements own stable semantic place identity and center; area-site records provide bounded downstream local-planning intent and profile hints. They are not population records or streaming chunks.

### Road segment record

- stable road ID;
- primary/secondary class;
- cardinal start/end;
- odd width;
- stable route-family ID.

A route may contain several segments to react to geography/hydrology.

### Bridge intent record

- stable ID;
- road/route IDs;
- river/river-segment IDs;
- exact crossing cell;
- bridge axis;
- road/river widths.

A bridge intent is **planning infrastructure intent**, not art, collision, a runtime entity or a completed tactical bridge.

## 6. Generation order and rules

1. Validate the global request/profile.
2. Generate coarse geography.
3. Generate global hydrology from geography.
4. Place/snap settlements and area sites against geography + river clearance.
5. Generate major roads against geography + river crossing cost.
6. Derive explicit bridge intents from actual road/river intersections.
7. Generate broad planning regions.
8. Independently validate the whole plan.
9. Return pure semantic global truth.

No unbounded reroll loops are permitted. Unsupported topology fails honestly.

## 7. Geography rules

- Geography cells are planning resolution, not streaming partitions.
- Elevation is deterministic 2D seeded planning data, not tactical slope physics.
- Settlements require lowland/rolling terrain.
- Major roads may use lowland/rolling/upland with increasing cost; ridge is forbidden.
- The protected central cross remains capped to legal low/rolling terrain to preserve the accepted integration anchor.

## 8. Hydrology rules

- The current slice creates one globally coherent north/south boundary-to-boundary primary river.
- The seed chooses a legal west/east side outside the protected central corridor.
- Routing uses coarse geography and prefers lower elevation while strongly penalizing uphill movement.
- The model is deliberately a drainage heuristic rather than geological/fluid simulation.
- River geometry is cardinal, ordered and globally stable for a seed/profile version.
- River centerline may not enter the protected central Candidate 006 corridor.
- Settlement site rectangles must clear the river corridor by profile-defined margin.

## 9. Major-road / bridge rules

- Existing landform costs remain active.
- River cells add a high but finite road cost so unnecessary crossings are avoided but required connectivity remains possible.
- Roads may not share a positive-length collinear centerline segment with a river.
- Every valid road/river intersection is perpendicular at one global crossing cell.
- Every actual route/river/cell crossing has exactly one bridge intent.
- Every bridge intent must map back to an actual crossing.
- Missing, duplicate or orphan bridge intent is a validation failure.

## 10. System 20 projection seam

`System20AreaRequestProjector.project_site()` remains unchanged at the local request contract: it clips supported global major roads into `AreaGenerationRequest`. Slice 003 does **not** inject tactical rivers/bridges into a System 20 request before a local hydrology/materialization design exists.

The separate read-only query:

`hydrology_constraints_for_bounds(plan, bounds)`

returns clipped river facts plus bridge intents for a global planning window. This creates a future seam without fake local implementation.

## 11. Validation / exact-head acceptance

`verify/system00d-global-world` protects:

- deterministic geography, hydrology, roads and bridge intents;
- legal alternate-seed variation;
- full geography tiling and meaningful landform classes;
- settlement geography + hydrology clearance;
- ridge-free road centerlines;
- connected major-road network and real world-boundary gateways;
- boundary-to-boundary connected river route;
- no road/river collinear overlap;
- at least one real crossing/bridge intent in the canonical regional fixture;
- exact one-to-one crossing/bridge-intent correspondence;
- protected central Candidate 006 road projection unchanged;
- accepted System 20 Candidate 006 output unchanged;
- clean adjacent central road continuity;
- hydrology-free center/adjacent protected windows;
- outer bridge window exposing river + bridge facts;
- pure-owner dependency boundaries.

## 12. Non-goals / future ownership

System 00D still does not own:

- local/minor roads, parcels, driveways, sidewalks or parking;
- building layouts/interiors;
- tactical water terrain/physics;
- bridge art/collision/destruction;
- lakes/wetlands/floodplains;
- detailed terrain slopes;
- utilities;
- addresses/population/jobs/households;
- outbreak simulation;
- WHAT materialization;
- save/streaming partition strategy;
- renderer/camera/UI/input/player gameplay.

Future global extensions may add tributaries/lakes, richer settlement hierarchy, utilities/infrastructure, zoning/addresses and broader land-use constraints. Streaming remains downstream of logical world truth.

## 13. North-star fit

The North Star requires geography, rivers, settlements, roads and other world-spanning structures to be coherent in global coordinates **before** streaming/local partitions are considered. Slices 001–003 now establish that hierarchy while deliberately stopping before tactical water, population or streaming behavior that belongs to later systems.
