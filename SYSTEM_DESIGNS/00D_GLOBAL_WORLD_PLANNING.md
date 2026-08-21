# Tick Survival Lab — System 00D Global World Planning

Status: **SLICES 001–004 IMPLEMENTED**

Date: 2026-08-21

## 1. Goal

System 00D owns deterministic **large-scale semantic world truth** before local planning, materialization, population, outbreak simulation or streaming.

Canonical hierarchy:

`world seed -> geography -> hydrology -> settlements/regions -> major roads + bridge intent -> regional infrastructure -> System 20 local area -> System 19 buildings -> initial WHAT -> persistent runtime mutation`

System 00D is pure planning. It never materializes WHAT and never owns rendering, camera, local building layout or streaming partitions.

## 2. Implemented slices

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
- protected central lowland/rolling cross with `protected_cross_half_span = 640`, keeping geography-aware bends outside the accepted center and immediately adjacent 256×256 planning windows.

### Slice 003 — Global Hydrology / Bridge Intent

Detailed design: `00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`.

Added:

- deterministic boundary-to-boundary regional river planning over the coarse geography lattice;
- hydrology clearance for settlement sites;
- hydrology-aware major-road crossing cost;
- prohibition on roads running collinearly along river centerlines;
- explicit global bridge-intent records for every real perpendicular road/river crossing;
- independent validation that crossings and bridge intents correspond exactly;
- read-only `System20AreaRequestProjector.hydrology_constraints_for_bounds()` seam;
- preserved Candidate 006 and its four immediately adjacent protected windows as hydrology-free integration anchors.

### Slice 004 — Regional Electrical Infrastructure

Detailed design: `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`.

Added:

- one deterministic regional electrical-grid ingress at a real road boundary gateway;
- one small-town-associated substation/distribution hub;
- one settlement service node for each of the five current settlements;
- one connected regional feeder network derived from the already valid major-road graph;
- feeder segments that carry stable source-road/source-route provenance rather than inventing independent off-road utility geometry;
- independent `GlobalPowerInfrastructureValidator` proof of one ingress, one substation, complete settlement service, road containment, ridge avoidance, boundary discipline and connectivity;
- read-only `System20AreaRequestProjector.power_constraints_for_bounds()` seam;
- Candidate 006 local request/materialization/render output unchanged: global power facts are queryable but tactical poles/wires/electricity are not faked.

## 3. Current canonical fixture

Profile: `temperate.rural.region` **v4**.

Global fixture:

- bounds `Rect2i(232,1232,1792,1792)`;
- seed `20001`;
- 14×14 = 196 coarse geography cells;
- five settlement anchors;
- connected primary/secondary regional road network;
- one deterministic primary regional river outside the protected center;
- at least one topologically required road/river crossing represented by explicit bridge intent;
- one regional power ingress;
- one small-town substation;
- five settlement service nodes;
- one connected road-following regional feeder network;
- broad rural-open region plus settlement influence regions;
- five local-area site records.

The protected central site remains:

- ID `area.rural.crossroads.001`;
- bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- area profile `rural.crossroads`;
- environment profile `temperate.rural`;
- inherited road IDs `road.region.primary.001` and `road.region.secondary.001`.

Its projected System 20 request remains semantically identical to `RuralCrossroadsPlanFixture.request(20001)`, and System 20 still produces the accepted Candidate 006 semantic output from those facts.

## 4. Owners

Pure owners under `game/scripts/generation/world/`:

- `GlobalWorldSeed.gd` — stable named sub-seeds and coordinate hashing;
- `GlobalWorldGenerationRequest.gd` — world constraints;
- `GeneratedGlobalWorldPlan.gd` — pure semantic result/signature;
- `GlobalWorldProfileCatalog.gd` — planning profiles/versions;
- `GlobalGeographyPlanner.gd` / `GlobalGeographyQuery.gd` — coarse landform truth;
- `GlobalHydrologyPlanner.gd` / `GlobalHydrologyQuery.gd` — river planning/read queries;
- `GlobalSettlementPlanner.gd` — geography/hydrology-constrained settlement/site intent;
- `GlobalMajorRoadPlanner.gd` — geography/hydrology-aware regional roads;
- `GlobalBridgeIntentPlanner.gd` — explicit bridge crossing intent;
- `GlobalPowerInfrastructurePlanner.gd` / `GlobalPowerInfrastructureQuery.gd` — regional electrical topology/read queries;
- `GlobalPowerInfrastructureValidator.gd` — focused independent electrical-topology validation;
- `GlobalPlanningRegionPlanner.gd` — broad planning regions;
- `GeneratedGlobalWorldValidator.gd` — independent Slices 001–003 full-plan correctness;
- `GlobalWorldPlanner.gd` — orchestration plus composition of base/power validation only.

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
- `power_nodes`;
- `power_segments`;
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

### Bridge intent record

- stable ID;
- road/route IDs;
- river/river-segment IDs;
- exact crossing cell;
- bridge axis;
- road/river widths.

A bridge intent is planning infrastructure intent, not art/collision/runtime bridge state.

### Power node record

- stable ID;
- regional network ID;
- semantic kind (`regional_ingress`, `substation`, `settlement_service`);
- global cell;
- optional settlement association.

### Power segment record

- stable ID/network ID;
- `regional_feeder` class;
- cardinal start/end;
- deterministic ordinal;
- source major-road ID and route ID.

A power segment is regional corridor truth, not a tactical pole/wire or energized runtime entity.

## 6. Generation order

1. Validate global request/profile.
2. Generate coarse geography.
3. Generate global hydrology from geography.
4. Place/snap settlements and area sites against geography + river clearance.
5. Generate major roads against geography + river crossing cost.
6. Derive explicit bridge intents from actual road/river intersections.
7. Derive regional electrical nodes/feeders from the connected major-road graph.
8. Generate broad planning regions.
9. Independently validate the base global plan and focused electrical network.
10. Return pure semantic global truth.

No unbounded reroll loops are permitted. Unsupported topology fails honestly.

## 7. Geography / hydrology / roads

- Geography cells are planning resolution, not streaming partitions.
- Elevation is deterministic planning data, not tactical slope physics.
- Settlements require lowland/rolling terrain.
- Major roads may use lowland/rolling/upland with increasing cost; ridge is forbidden.
- The protected central cross remains legal low/rolling terrain.
- The primary river is a real boundary-to-boundary route outside the protected Candidate 006 corridor.
- Road river crossings are expensive but legal when topology requires them.
- Roads may not run collinearly along river centerlines.
- Every real perpendicular crossing has exactly one bridge intent.

## 8. Regional electrical rules

- Exactly one deterministic major-road boundary gateway is chosen as the regional electrical ingress.
- The small-town settlement center hosts the current regional substation planning node.
- Every settlement center has exactly one service node.
- The feeder planner uses the existing major-road geometry as its graph; it does not reroute independently through terrain.
- Primary-road corridors are mildly preferred over secondary corridors when alternative road-graph paths exist.
- The union of shortest required road-graph paths from ingress to the substation/services becomes the regional feeder network.
- Every feeder segment must remain contained in the named source road segment.
- Ridge avoidance is therefore inherited from roads and independently rechecked.
- Only the chosen ingress may create a feeder endpoint at the regional boundary.
- Same seed/profile replays identical power facts; alternate seeds may vary ingress/network topology legally.

## 9. System 20 projection seams

`System20AreaRequestProjector.project_site()` remains unchanged at the local request contract: it clips supported global major roads into `AreaGenerationRequest`.

Read-only future seams:

- `hydrology_constraints_for_bounds(plan, bounds)` -> clipped river + bridge intent facts;
- `power_constraints_for_bounds(plan, bounds)` -> clipped feeder segments + power nodes.

Neither seam silently injects unsupported water, bridges, poles or wires into `AreaGenerationRequest`.

## 10. Validation / exact-head acceptance

`verify/system00d-global-world` protects:

- deterministic geography, hydrology, roads, bridge intents and power infrastructure;
- legal alternate-seed variation;
- complete geography tiling and meaningful landforms;
- settlement geography + hydrology clearance;
- ridge-free roads;
- connected major-road network and boundary gateways;
- boundary-to-boundary river route;
- exact crossing/bridge-intent correspondence;
- exactly one power ingress and one small-town substation;
- exactly five settlement service nodes;
- road-contained, ridge-free, connected power feeder network;
- no unintended power boundary egress;
- protected Candidate 006 road request/output unchanged;
- clean adjacent central road projection;
- hydrology-free center/adjacent protected windows;
- outer bridge window exposing river + bridge facts;
- Candidate 006 read-only power projection exposing global feeder/service facts;
- pure-owner dependency boundaries;
- System 20 and canonical startup regressions.

## 11. Non-goals / future ownership

System 00D still does not own:

- local/minor roads, parcels, driveways, sidewalks or parking;
- building layouts/interiors;
- tactical water terrain/physics;
- bridge art/collision/destruction;
- lakes/wetlands/floodplains;
- tactical utility poles/wires/transformers;
- runtime energized state, outages, generators or building wiring;
- water/sewer utility networks;
- addresses/population/jobs/households;
- outbreak simulation;
- WHAT materialization;
- save/streaming partition strategy;
- renderer/camera/UI/input/player gameplay.

Future global extensions may add water/waste infrastructure, richer settlement hierarchy, zoning/addresses and other world-spanning facts. Streaming remains downstream of logical world truth.

## 12. North-star fit

The North Star requires geography, rivers, settlements, roads, utilities and other world-spanning structures to be coherent in global coordinates **before** streaming/local partitions are considered. Slices 001–004 now establish geography, hydrology, settlement/road topology and the first real regional utility network while deliberately stopping before tactical materialization, population or runtime electrical simulation.
