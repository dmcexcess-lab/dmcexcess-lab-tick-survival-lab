# Tick Survival Lab — System 00D Global World Planning

Status: **SLICES 001–005 IMPLEMENTED**

Date: 2026-08-22

## 1. Goal

System 00D owns deterministic **large-scale semantic world truth** before local planning, materialization, population, outbreak simulation or streaming.

Canonical hierarchy:

`world seed -> geography -> hydrology -> settlements/regions -> major roads + bridge intent -> regional infrastructure -> System 20 local area -> System 19 buildings -> initial WHAT -> persistent runtime mutation`

System 00D is pure planning. It never materializes WHAT and never owns rendering, camera, local building layout or streaming partitions.

## 2. Implemented slices

### Slice 001 — Regional Skeleton

Established global request/plan/profile contracts, broad planning regions, five settlement anchors, coherent primary/secondary roads with real gateways, local-area site records, and the separate System 20 projection adapter.

### Slice 002 — Geography / Landform Constraints

Added the deterministic 128-cell geography lattice, planning elevation and lowland/rolling/upland/ridge classes, legal settlement geography, geography-aware road routing, and the protected central straight-cross corridor.

### Slice 003 — Global Hydrology / Bridge Intent

Detailed design: `00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md`.

Added a deterministic boundary-to-boundary primary river, settlement river clearance, hydrology-aware road costs, explicit bridge intents for real road/river crossings, independent crossing validation, and `hydrology_constraints_for_bounds()` while keeping Candidate 006 and its immediate adjacent windows hydrology-free.

### Slice 004 — Regional Electrical Infrastructure

Detailed design: `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`.

Added one regional grid ingress, one small-town substation, one electrical service node per settlement, one connected road-following feeder network with source-road provenance, independent electrical validation, and `power_constraints_for_bounds()` without changing Candidate 006.

### Slice 005 — Potable Water Infrastructure

Detailed design: `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`.

Added:

- one potable-water service record for every current settlement;
- municipal groundwater service for `settlement.smalltown.001`;
- decentralized groundwater-source intent for the rural crossroads and all three rural hamlets;
- one small-town municipal network with `groundwater_source`, `treatment_storage`, and `settlement_service` planning anchors;
- two contiguous `municipal_trunk` segments contained by real major-road geometry inside the small-town planning site;
- independent water validation for service classification, anchor/site/road legality, ridge/boundary discipline, exact topology and source-to-service reachability;
- read-only `System20AreaRequestProjector.water_constraints_for_bounds()`;
- no change to Candidate 006 local generation or presentation.

## 3. Current canonical fixture

Profile: `temperate.rural.region` **v5**.

Global fixture:

- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse geography cells and five settlement anchors;
- connected primary/secondary regional road network;
- one deterministic primary river plus explicit bridge intent at every real crossing;
- one regional power ingress, one small-town electrical substation, five electrical service nodes and one connected road-following feeder network;
- five potable-water service records;
- one small-town municipal groundwater service and four decentralized rural groundwater-source intents;
- three small-town municipal water connection anchors and two road-contained municipal trunk segments;
- broad rural-open region plus settlement influence regions;
- five local-area site records.

The protected central site remains `area.rural.crossroads.001` at `Rect2i(1000,2000,256,256)`, seed `20001`, using `rural.crossroads` + `temperate.rural` and inherited roads `road.region.primary.001` / `road.region.secondary.001`.

Its projected System 20 request remains semantically identical to `RuralCrossroadsPlanFixture.request(20001)`, and System 20 still produces the accepted Candidate 006 semantic output.

## 4. Owners

Pure owners under `game/scripts/generation/world/` include the request/plan/profile contracts; geography, hydrology, settlement, major-road, bridge-intent, power, potable-water and planning-region owners; independent base/power/water validators; and `GlobalWorldPlanner.gd` as orchestration only.

Potable-water-specific owners:

- `GlobalWaterInfrastructurePlanner.gd`;
- `GlobalWaterInfrastructureQuery.gd`;
- `GlobalWaterInfrastructureValidator.gd`.

Separate downstream adapter: `game/scripts/generation/integration/System20AreaRequestProjector.gd`.

Pure System 00D source does not import System 19, System 20, WHAT mutation, WHEN, renderer/art, camera/input/UI/player, reboot code or future streaming ownership.

## 5. Public plan contract

`GeneratedGlobalWorldPlan` exposes:

- provenance: world ID, seed, bounds, profile ID/version;
- `geography_cells`;
- `river_segments`;
- `regions`;
- `settlements`;
- `road_segments`;
- `bridge_intents`;
- `power_nodes`;
- `power_segments`;
- `water_services`;
- `water_nodes`;
- `water_segments`;
- `area_sites`;
- deterministic `signature()` and failure reason.

Bridge intents are planning facts, not tactical bridge state. Power records are regional corridor/service truth, not poles/wires or energized state.

A water service record stores stable ID, settlement ID, `municipal` or `decentralized_source`, source type (`groundwater` here), and municipal network ID when applicable. Decentralized service does not pre-place a physical well.

Municipal water nodes store stable network/kind/cell/settlement facts for `groundwater_source`, `treatment_storage`, and `settlement_service`. They are connection anchors, not exact facility footprints. Municipal water segments store `municipal_trunk` cardinal geometry plus source-road/source-route provenance.

## 6. Generation order

1. Validate global request/profile.
2. Generate coarse geography.
3. Generate global hydrology.
4. Place/snap settlements and area sites against geography + river clearance.
5. Generate major roads against geography + river crossing cost.
6. Derive bridge intents from actual road/river crossings.
7. Derive regional electrical nodes/feeders from the connected major-road graph.
8. Derive potable-water settlement service and the bounded small-town municipal backbone.
9. Generate broad planning regions.
10. Independently validate base global truth plus focused electrical and water infrastructure.
11. Return pure semantic global truth.

No unbounded reroll loops are permitted. Unsupported topology fails honestly.

## 7. Geography / hydrology / road rules

Geography cells are planning resolution, not streaming partitions. Settlements require legal lowland/rolling terrain. Major roads may use lowland/rolling/upland with increasing cost; ridge is forbidden. The primary river is a boundary-to-boundary route outside the protected Candidate 006 corridor. Roads cannot follow the river centerline; every real perpendicular crossing has exactly one bridge intent.

## 8. Regional electrical rules

Exactly one deterministic road gateway is the electrical ingress. The small town hosts the current substation. Every settlement has an electrical service node. The feeder uses existing major-road geometry, mildly prefers primary roads, remains road-contained/ridge-free, and only the selected ingress may terminate at the world boundary.

## 9. Potable-water rules

- Exactly one water-service record exists for each current settlement.
- The small town is the only municipal service in v5; crossroads + three hamlets are decentralized groundwater-source service areas.
- The regional river is not silently treated as drinking-water intake; current source type is semantic `groundwater`.
- Municipal `settlement_service` is at the small-town center.
- `treatment_storage` and `groundwater_source` anchors are placed at bounded deterministic offsets on one legal incident major-road corridor inside the small-town area site.
- Two contiguous trunk segments connect source -> treatment/storage -> service and retain source-road/source-route provenance.
- Municipal nodes/segments remain inside the small-town site, off the regional boundary, road-contained and ridge-free.
- Physical facilities, local distribution, private wells and runtime water behavior are downstream responsibilities.

## 10. System 20 projection seams

`project_site()` remains unchanged and supplies only supported inherited major roads to `AreaGenerationRequest`.

Read-only seams:

- `hydrology_constraints_for_bounds()` -> clipped river + bridge facts;
- `power_constraints_for_bounds()` -> clipped feeder + power-node facts;
- `water_constraints_for_bounds()` -> settlement water-service intent + clipped municipal nodes/trunks.

None silently injects bridges, poles, wires, wells or pipes into local generation. Candidate 006 keeps its exact accepted local output while exposing decentralized groundwater intent. The unsupported small-town site can expose municipal planning facts without fabricating a local profile.

## 11. Validation / exact-head acceptance

`verify/system00d-global-world` protects deterministic geography/hydrology/roads/bridges/power/water, alternate-seed legality, road and river constraints, electrical topology, five water services, exact mixed municipal/decentralized classification, three municipal anchors, two road-contained trunk segments, source-to-service reachability, unchanged Candidate 006 output, all read-only projection seams, honest unsupported-profile failure, dependency boundaries, System 20 regression and canonical startup.

## 12. Non-goals / future ownership

System 00D still does not own:

- local roads/parcels/driveways/parking or building internals;
- tactical bridge implementation;
- poles/wires/transformers or energized electrical state;
- literal potable-water wells, pumps, tanks, towers, waterworks or pipes;
- local municipal distribution, private-well placement or building plumbing;
- runtime pressure, flow, water quantity/quality/consumption or pump-power behavior;
- wastewater, sewer, septic or storm-drain infrastructure;
- population/jobs/households/outbreak;
- WHAT materialization or streaming/save partition strategy;
- renderer/camera/UI/input/player gameplay.

Future global extensions may add wastewater/septic intent, richer settlement hierarchy, zoning/addresses and other world-spanning facts.

## 13. North-star fit

The North Star requires geography, rivers, settlements, roads and utilities to be coherent globally before local partitions. Slices 001–005 now establish geography, hydrology, settlement/road topology, regional electrical service and a believable mixed rural potable-water model while stopping before tactical utility materialization, population or runtime utility simulation.
