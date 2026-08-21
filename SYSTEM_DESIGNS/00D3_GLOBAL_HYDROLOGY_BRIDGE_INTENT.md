# Tick Survival Lab — System 00D Slice 003 Global Hydrology / Bridge Intent

Status: **IMPLEMENTED**

Date: 2026-08-21

## 1. Goal

Add coarse deterministic river truth to System 00D so major roads and settlements react to real world-scale hydrology before local materialization or streaming.

Canonical order for this slice:

`global request -> geography -> hydrology -> settlements/sites -> hydrology-aware major roads -> bridge intents -> planning regions -> validation -> global plan`

The slice preserves the accepted central Rural Crossroads / Candidate 006 integration anchor and does not tactically materialize water or bridges yet.

## 2. Non-goals

Slice 003 does not implement:

- lakes, ponds, wetlands, floodplains or seasonal flow;
- tactical water terrain, swimming, drowning or movement costs;
- bridge art, bridge collision or bridge construction/destruction;
- culverts, ferries, tunnels or fords;
- water utilities;
- weather/rainfall-driven river simulation;
- erosion or detailed drainage physics;
- System 20 river materialization;
- WHAT writes, streaming, population or outbreak simulation.

A bridge intent is a global planning fact, not a finished physical bridge entity.

## 3. Owners

Pure System 00D owners under `game/scripts/generation/world/`:

- `GlobalHydrologyPlanner.gd` — deterministic coarse river route generation from geography;
- `GlobalHydrologyQuery.gd` — read-only river intersection/clearance queries;
- `GlobalBridgeIntentPlanner.gd` — converts valid road/river crossings into explicit bridge-intent records;
- existing `GlobalSettlementPlanner.gd` — consumes river clearance through the public hydrology query;
- existing `GlobalMajorRoadPlanner.gd` — consumes river crossing cost while routing;
- existing `GeneratedGlobalWorldPlan.gd`, `GlobalWorldPlanner.gd`, `GeneratedGlobalWorldValidator.gd`, `GlobalWorldProfileCatalog.gd` — extended only for the new plan facts.

The existing `System20AreaRequestProjector.gd` remains the only 00D-adjacent integration owner. It exposes clipped hydrology/bridge facts through a read-only projector query, while the existing System 20 `AreaGenerationRequest` contract remains unchanged.

## 4. Public plan contract additions

`GeneratedGlobalWorldPlan` contains:

- `river_segments: Array[Dictionary]`;
- `bridge_intents: Array[Dictionary]`.

### River segment record

Each segment stores:

- unique `segment_id`;
- stable `river_id` shared by all segments in one river;
- cardinal `start` and `end` in global tactical-cell coordinates;
- odd physical `width`;
- ordered `ordinal` along downstream flow.

Segment order is upstream -> downstream. The current slice uses one primary regional river but the contract supports multiple rivers later.

### Bridge intent record

Each intent stores:

- unique `id`;
- `road_id` of the intersecting road segment;
- `route_id` of the road family;
- `river_id`;
- `river_segment_id`;
- exact global crossing `cell`;
- `bridge_axis` (`horizontal` or `vertical`) matching the road axis;
- road and river widths for later local materialization planning.

The intent does not store art, collision, condition, owner, traffic rules or runtime state.

## 5. Temperate rural profile v3

`temperate.rural.region` is v3 because same-seed global output now includes hydrology and hydrology-aware road/settlement behavior.

Current Slice 003 profile parameters include:

- one primary river with odd width;
- hydrology exclusion around the protected central integration cross;
- high but finite road river-crossing cost;
- settlement/site river-clearance distance;
- deterministic hydrology meander/noise cost and uphill penalty.

## 6. Hydrology generation rules

1. Geography is generated first.
2. The canonical primary river connects one real regional boundary to the opposite boundary, making it a globally coherent watercourse rather than a local decorative line.
3. The seed chooses whether the river uses the west or east side of the protected central area.
4. The route is planned on the same coarse geography lattice used by Slice 002 roads.
5. Candidate route steps prefer lower elevation and strongly penalize uphill movement while allowing bounded coarse simplification; this is a drainage heuristic, not a fluid simulation.
6. The river may not enter the protected central integration cross or the immediately protected Candidate 006/adjacent-window zone.
7. The coarse path is converted into ordered cardinal tactical-coordinate segments and collinear sections are merged.
8. Same request/profile version produces identical river geometry; different seeds may change side/meander while preserving validity.
9. River segments do not know about rendering, System 20, WHAT or streaming.

## 7. Settlement hydrology rules

1. The protected central crossroads remains unchanged and hydrology is forbidden from its protected zone.
2. Non-central settlement candidates must still satisfy Slice 002 lowland/rolling geography rules.
3. Their local 256x256 site rectangle must also clear the river corridor by the profile-defined margin.
4. Bounded deterministic snapping searches for the nearest candidate satisfying both geography and hydrology constraints.
5. If no legal site exists within the approved search radius, world generation fails rather than placing a settlement on top of a river.

## 8. Major-road hydrology rules

1. Existing landform costs remain in force: lowland cheapest, rolling mild, upland expensive, ridge forbidden.
2. River-centerline coarse cells add a large crossing cost.
3. This makes roads avoid unnecessary river crossings but still permits a crossing when network topology requires one.
4. A road may not run collinearly along a river centerline through a shared segment.
5. A road/river crossing must be perpendicular and resolve to a single crossing cell at the global centerline level.
6. The canonical boundary-to-boundary primary road and boundary-to-boundary river make at least one crossing topologically unavoidable outside the protected central area.
7. Road routing itself does not create bridge entities; it only creates road geometry.

## 9. Bridge intent rules

1. `GlobalBridgeIntentPlanner` runs after roads and rivers exist.
2. Every perpendicular road/river centerline intersection produces exactly one bridge intent.
3. Collinear road/river overlap is invalid and cannot be converted into bridge intents.
4. Duplicate intents for one route/river/cell crossing are invalid.
5. Every actual road/river crossing must have a corresponding bridge intent.
6. Every bridge intent must correspond to a real road/river crossing.
7. The canonical fixture contains at least one bridge intent.

## 10. System 20 projection seam

The existing local-area request remains unchanged in Slice 003 so Candidate 006 does not acquire fake tactical water support.

`System20AreaRequestProjector` exposes:

`hydrology_constraints_for_bounds(plan, bounds)`

which returns clipped river centerline segments and bridge intents inside a requested global planning window.

This is an integration seam for a future explicitly designed System 20 hydrology/materialization profile. `project_site()` does not silently inject unsupported water into `AreaGenerationRequest`.

For the accepted central Candidate 006 bounds and its immediately adjacent protected windows, the hydrology query returns no river or bridge facts.

## 11. Validation

`GeneratedGlobalWorldValidator` independently verifies:

- river stable IDs and segment IDs;
- cardinal non-zero river segments with odd positive widths;
- river endpoints inside global bounds;
- the primary river has real boundary endpoints and one connected ordered route;
- no river segment enters the protected central hydrology-exclusion zone;
- settlement sites clear the river corridor;
- no road and river overlap collinearly;
- every road/river crossing is perpendicular and has exactly one bridge intent;
- every bridge intent references existing road and river segment IDs and the exact real crossing cell;
- no orphan/duplicate bridge intents;
- at least one bridge intent exists for the canonical regional fixture;
- all existing Slice 002 geography/road/settlement rules remain true.

## 12. Acceptance tests

Dedicated `verify/system00d-global-world` proves:

1. `temperate.rural.region` records v3;
2. same-seed replay includes identical rivers and bridge intents;
3. different seed changes legal hydrology outside the protected anchor;
4. at least one boundary-to-boundary primary river exists;
5. river geometry is connected, cardinal and outside the protected center;
6. settlement sites do not intersect the river-clearance corridor;
7. canonical major roads still avoid ridge geography;
8. at least one road/river crossing is unavoidable and produces a bridge intent;
9. every crossing has exactly one intent and every intent maps to a crossing;
10. no road runs collinearly with a river;
11. the central Candidate 006 System 20 projected request remains semantically unchanged at its existing road contract;
12. System 20 still produces the accepted Candidate 006 local plan from that request;
13. central and immediately adjacent hydrology projection windows are empty by design;
14. an outer window containing a canonical bridge exposes the river + bridge facts through the projector query;
15. pure 00D source still imports no System 19/20, WHAT, renderer, camera, UI, player or streaming owner.

## 13. Performance

Hydrology uses the existing small coarse global lattice and bounded deterministic graph search at world creation only. Bridge-intent discovery compares the small global road/river segment sets. No per-frame work is introduced.

## 14. Failure behavior

Generation fails honestly on unresolved river routing, illegal settlement/river overlap, road/river collinear overlap, missing/duplicate/orphan bridge intents, or any regression of the existing global/local integration anchor.

No renderer trick or local deletion pass may hide invalid hydrology.

## 15. Future extension seams

Later approved slices may add:

- tributaries and multiple rivers;
- lakes/wetlands/floodplains;
- detailed local water surfaces;
- bridge archetype/materialization selection;
- bridge condition/destruction and alternate crossings;
- water utilities;
- precipitation/flood consequences;
- travel/vehicle bridge restrictions.

Those later systems consume the stable river/bridge planning facts rather than redefining the global watercourse.

## 16. North-star fit

The North Star explicitly requires rivers and other world-spanning structures to be coherent in global coordinates before streaming boundaries are considered. Slice 003 adds the smallest causal model that creates meaningful consequences: settlements avoid water corridors, road topology pays for crossings, and crossings become explicit infrastructure facts rather than accidental geometry.

## 17. Approved decisions

Approved by the user on 2026-08-21:

1. Proceed from Slice 002 into hydrology/rivers plus real bridge-crossing intent.
2. Keep this inside System 00D rather than starting streaming.
3. Preserve Candidate 006 and the protected central integration zone.
4. Do not fake tactical water/bridge behavior before a downstream owner is designed.

## 18. Implementation result

Slice 003 is implemented under `game/scripts/generation/world/` with focused hydrology/query/bridge-intent owners and is verified through the existing exact-head `verify/system00d-global-world` contract.

The canonical seed now produces a deterministic boundary-to-boundary river outside the protected central local-area corridor. Non-central settlement sites clear that river, road routing pays a crossing penalty while retaining ridge avoidance, and every real perpendicular road/river crossing is represented by exactly one independently validated bridge intent.

`System20AreaRequestProjector.hydrology_constraints_for_bounds()` exposes those global facts without changing `AreaGenerationRequest`. The accepted Candidate 006 center and its immediately adjacent windows remain hydrology-free and its System 20 semantic output is unchanged.
