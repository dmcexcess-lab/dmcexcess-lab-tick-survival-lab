# Tick Survival Lab — System 00D Global World Planning

Status: **SLICES 001–006 IMPLEMENTED**

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

Added one potable-water service record per settlement, municipal groundwater service for the small town, decentralized groundwater-source intent for the crossroads/hamlets, three small-town municipal planning anchors, two road-contained municipal trunk segments, independent water validation, and `water_constraints_for_bounds()`.

### Slice 006 — Wastewater / Septic Infrastructure

Detailed design: `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md`.

Added:

- one wastewater-service record for every current settlement;
- municipal wastewater treatment intent for `settlement.smalltown.001`;
- decentralized septic intent for the rural crossroads and three rural hamlets;
- `potable_source_clearance_required` on every rural septic service;
- one small-town `settlement_collection` anchor and one `treatment_disposal` anchor;
- one road-contained `municipal_collection_trunk` inside the small-town planning site;
- deterministic corridor selection that excludes the potable-water groundwater-source direction and rejects positive-length overlap with potable-water trunks;
- independent wastewater validation for classification, topology, road/site legality, ridge/boundary discipline, water/waste separation and ID uniqueness;
- read-only `System20AreaRequestProjector.wastewater_constraints_for_bounds()`;
- no change to Candidate 006 local generation or presentation.

## 3. Current canonical fixture

Profile: `temperate.rural.region` **v6**.

Global fixture:

- bounds `Rect2i(232,1232,1792,1792)`, seed `20001`;
- 196 coarse geography cells and five settlement anchors;
- connected primary/secondary regional road network;
- one deterministic primary river plus explicit bridge intent at every real crossing;
- one regional power ingress, one small-town electrical substation, five electrical service nodes and one connected road-following feeder network;
- five potable-water services: one small-town municipal groundwater service plus four decentralized rural groundwater-source intents;
- three small-town municipal water anchors and two road-contained potable-water trunk segments;
- five wastewater services: one small-town municipal treatment service plus four decentralized septic intents;
- two small-town municipal wastewater anchors and one road-contained collection trunk separated from the potable-water source/trunk corridor;
- broad rural-open region plus settlement influence regions;
- five local-area site records.

The protected central site remains `area.rural.crossroads.001` at `Rect2i(1000,2000,256,256)`, seed `20001`, using `rural.crossroads` + `temperate.rural` and inherited roads `road.region.primary.001` / `road.region.secondary.001`.

Its projected System 20 request remains semantically identical to `RuralCrossroadsPlanFixture.request(20001)`, and System 20 still produces the accepted Candidate 006 semantic output.

## 4. Owners

Pure owners under `game/scripts/generation/world/` include request/plan/profile contracts; geography, hydrology, settlement, major-road, bridge-intent, power, potable-water, wastewater and planning-region owners; independent base/power/water/wastewater validators; and `GlobalWorldPlanner.gd` as orchestration only.

Infrastructure-specific owners:

- `GlobalPowerInfrastructurePlanner.gd` / Query / Validator;
- `GlobalWaterInfrastructurePlanner.gd` / Query / Validator;
- `GlobalWastewaterInfrastructurePlanner.gd` / Query / Validator.

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
- `power_nodes` / `power_segments`;
- `water_services` / `water_nodes` / `water_segments`;
- `wastewater_services` / `wastewater_nodes` / `wastewater_segments`;
- `area_sites`;
- deterministic `signature()` and failure reason.

Bridge, power, water and wastewater records are planning truth only, not tactical/runtime state.

## 6. Generation order

1. Validate global request/profile.
2. Generate coarse geography.
3. Generate global hydrology.
4. Place/snap settlements and area sites against geography + river clearance.
5. Generate major roads against geography + river crossing cost.
6. Derive bridge intents from actual road/river crossings.
7. Derive regional electrical nodes/feeders from the connected major-road graph.
8. Derive potable-water service and the bounded small-town municipal backbone.
9. Derive wastewater/septic service and the bounded small-town municipal collection/treatment backbone, consuming public potable-water facts for separation.
10. Generate broad planning regions.
11. Independently validate base global truth plus focused power/water/wastewater infrastructure.
12. Return pure semantic global truth.

No unbounded reroll loops are permitted. Unsupported topology fails honestly.

## 7. Geography / hydrology / road rules

Geography cells are planning resolution, not streaming partitions. Settlements require legal lowland/rolling terrain. Major roads may use lowland/rolling/upland with increasing cost; ridge is forbidden. The primary river is boundary-to-boundary outside the protected Candidate 006 corridor. Roads cannot follow the river centerline; every real perpendicular crossing has exactly one bridge intent.

## 8. Regional electrical rules

Exactly one deterministic road gateway is the electrical ingress. The small town hosts the current substation. Every settlement has an electrical service node. The feeder uses existing major-road geometry, mildly prefers primary roads, remains road-contained/ridge-free, and only the selected ingress may terminate at the world boundary.

## 9. Potable-water rules

The small town is the only municipal potable-water service. Crossroads + three hamlets use decentralized groundwater-source intent. The regional river is not silently treated as drinking-water intake. The small-town municipal source/treatment/service anchors and two trunk segments remain inside its planning site, road-contained and ridge-free.

## 10. Wastewater / septic rules

- Exactly one wastewater-service record exists for each current settlement.
- The small town is the only municipal wastewater service in v6.
- Crossroads + three hamlets use `decentralized_septic` / `onsite_septic` and carry `potable_source_clearance_required`.
- Municipal `settlement_collection` is at the small-town center.
- `treatment_disposal` is placed at a bounded deterministic offset on a legal incident major-road corridor inside the small-town site.
- The chosen wastewater corridor may not be the potable-water groundwater-source direction.
- The municipal wastewater trunk may share the settlement-center endpoint but may not overlap potable-water trunk geometry for positive length.
- Physical septic/treatment facilities, exact well/septic clearance, local sewer networks and runtime sanitation are downstream responsibilities.

## 11. System 20 projection seams

`project_site()` remains unchanged and supplies only supported inherited major roads to `AreaGenerationRequest`.

Read-only seams:

- `hydrology_constraints_for_bounds()` -> clipped river + bridge facts;
- `power_constraints_for_bounds()` -> clipped feeder + power-node facts;
- `water_constraints_for_bounds()` -> settlement water-service intent + municipal water nodes/trunks;
- `wastewater_constraints_for_bounds()` -> wastewater-service intent + municipal wastewater nodes/trunk.

None silently injects bridges, poles, wires, wells, pipes, septic tanks or treatment facilities into local generation. Candidate 006 keeps its exact accepted local output while exposing decentralized water and septic intent. The unsupported small-town site can expose municipal utility planning facts without fabricating a local profile.

## 12. Validation / exact-head acceptance

`verify/system00d-global-world` protects deterministic geography/hydrology/roads/bridges/power/water/wastewater, alternate-seed legality, infrastructure topology and separation, unchanged Candidate 006 output, read-only projection seams, honest unsupported-profile failure, pure-owner dependency boundaries, System 20 regression and canonical startup.

## 13. Non-goals / future ownership

System 00D still does not own local roads/parcels/building internals; tactical bridge implementation; poles/wires/energized state; literal wells/towers/pipes; building plumbing; pressure/flow/water quantity; septic tanks/drain fields/sewer pipes/manholes/treatment buildings; sewage flow/backups/contamination; population/jobs/households/outbreak; WHAT materialization; save/streaming partitions; renderer/camera/UI/input/player gameplay.

With Slice 006, the current regional utility skeleton is sufficiently stable to move next into real local settlement profiles rather than continuing to expand global utilities by default.

## 14. North-star fit

The North Star requires geography, roads and utilities to be coherent globally before local partitions. Slices 001–006 now establish geography, hydrology, settlement/road topology, regional electrical service, mixed rural potable-water service and mixed rural wastewater/septic service while deliberately stopping before tactical utility materialization, population or runtime utility simulation.
