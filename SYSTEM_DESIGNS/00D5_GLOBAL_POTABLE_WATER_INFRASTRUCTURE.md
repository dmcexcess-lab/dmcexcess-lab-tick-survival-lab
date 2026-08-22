# Tick Survival Lab — System 00D Slice 005 Potable Water Infrastructure

Status: **IMPLEMENTED**

Date: 2026-08-22

## 1. Goal

Add deterministic potable-water infrastructure planning truth to System 00D before small-town/rural local generation, streaming, population and outbreak simulation depend on it.

Slice 005 uses a mixed rural service model rather than copying the regional electrical grid:

- the current small town receives a municipal groundwater system;
- the rural crossroads and three rural hamlets receive decentralized groundwater-source intent;
- no remote settlement is falsely connected to one region-wide municipal main.

Canonical order becomes:

`global request -> geography -> hydrology -> settlements/sites -> major roads -> bridge intents -> regional electrical infrastructure -> potable water infrastructure -> planning regions -> validation -> global plan`

System 00D records infrastructure topology and service intent only. It does not place literal wells/towers/buildings, provide water to fixtures, mutate WHAT or simulate pressure/flow.

## 2. Approved decisions

Approved by the user on 2026-08-22:

1. Implement water now so later settlement/materialization work must respect it instead of retrofitting around it.
2. Use a mixed municipal/decentralized rural model.
3. `settlement.smalltown.001` uses municipal groundwater service.
4. The rural crossroads and three rural hamlets use decentralized groundwater-source intent.
5. Municipal source/treatment/storage/service facts are planning connection anchors, not exact physical facility footprints.
6. Municipal trunk geometry follows existing major-road corridors inside the small-town planning area.
7. Expose a read-only System 20 water projection seam without changing the current `AreaGenerationRequest` or Candidate 006 output.
8. Sewer/septic/wastewater remains a separate future slice.
9. Bump `temperate.rural.region` from v4 to v5 because same-seed global planning output gains canonical water-service truth.

## 3. Non-goals

Slice 005 does not implement:

- tactical wells, pumps, water towers, tanks or treatment buildings;
- literal pipe sprites/collision;
- building plumbing or fixture water state;
- pressure, flow, storage quantity or water consumption;
- drinking, filling containers or purification gameplay;
- water quality/contamination;
- outages, pump-power coupling or repair;
- rain collection;
- sewer, septic, wastewater or storm drains;
- WHAT materialization;
- WHEN simulation;
- streaming/save ownership;
- population/outbreak behavior;
- changes to System 19, System 20 local generation, render/art, camera or player mechanics.

## 4. Owners

Pure System 00D owners under `game/scripts/generation/world/`:

- `GlobalWaterInfrastructurePlanner.gd` — classifies settlement service mode and creates the small-town municipal connection anchors/trunk;
- `GlobalWaterInfrastructureQuery.gd` — read-only service/network queries;
- `GlobalWaterInfrastructureValidator.gd` — independently verifies service classification and municipal topology;
- `GeneratedGlobalWorldPlan.gd` — stores water facts and includes them in deterministic signatures;
- `GlobalWorldPlanner.gd` — orchestrates water planning after electrical infrastructure and composes validation;
- `GlobalWorldProfileCatalog.gd` — owns Slice 005 profile version and bounded anchor offsets.

Separate downstream adapter:

- `game/scripts/generation/integration/System20AreaRequestProjector.gd` — read-only local-window water projection only.

## 5. Public global-plan contract

`GeneratedGlobalWorldPlan` gains:

- `water_services: Array[Dictionary]`;
- `water_nodes: Array[Dictionary]`;
- `water_segments: Array[Dictionary]`.

### Water service record

Exactly one record exists for every current settlement:

- stable `id`;
- `settlement_id`;
- `service_mode`:
  - `municipal`;
  - `decentralized_source`;
- `source_type` (`groundwater` in the current profile);
- `network_id` for municipal service, otherwise empty.

A decentralized service record means downstream local/property generation must provide a legal local source such as a private/shared well. It does not pre-place that source globally.

### Municipal water node record

The current municipal network records exactly three planning anchors:

- `groundwater_source`;
- `treatment_storage`;
- `settlement_service`.

Each stores:

- stable `id`;
- `network_id`;
- semantic `kind`;
- global tactical `cell`;
- associated small-town `settlement_id`.

These cells are connection anchors on existing road-corridor geometry inside the small-town planning site. They are not exact wellhead/tower/building footprints.

### Municipal water segment record

Each municipal trunk segment stores:

- stable `id`;
- `network_id`;
- `water_class` (`municipal_trunk`);
- cardinal `start` / `end` global cells;
- stable `ordinal`;
- `source_road_id` and `source_route_id` proving which existing major-road corridor owns the alignment.

## 6. Service model

Current `temperate.rural.region` service classification is intentionally simple and explicit:

- `settlement.smalltown.001` -> `municipal`, `groundwater`;
- `settlement.rural.crossroads.001` -> `decentralized_source`, `groundwater`;
- `settlement.rural.hamlet.001` -> `decentralized_source`, `groundwater`;
- `settlement.rural.hamlet.002` -> `decentralized_source`, `groundwater`;
- `settlement.rural.hamlet.003` -> `decentralized_source`, `groundwater`.

Unknown current settlement kinds/IDs fail honestly rather than silently receiving municipal service.

## 7. Municipal anchor / routing model

The small-town settlement center is already on valid major-road geometry and its local site is hydrologically clear.

1. Find the small-town settlement and its matching area site.
2. Find legal major-road directions incident to the small-town center that remain inside that area site for the configured source-anchor distance.
3. Choose one legal direction deterministically from a named world-seed domain.
4. Place the municipal `settlement_service` anchor at the small-town center.
5. Place `treatment_storage` a bounded distance outward on that same source road corridor.
6. Place `groundwater_source` farther outward on the same corridor.
7. Create two contiguous `municipal_trunk` segments: source -> treatment/storage -> settlement service.
8. Record the source road/route on each segment.

The current profile uses modest offsets so the complete municipal backbone remains inside the small-town planning site. A future `smalltown.center` local planner may place actual facilities around these anchors and extend local distribution to parcels without redefining the global source/service relationship.

## 8. Geography / hydrology relationship

- The municipal backbone may only use existing major-road geometry, so ridge avoidance is inherited and independently checked.
- All three municipal anchors must lie inside the existing small-town area site, which already satisfies the global river-clearance contract.
- No potable-water source is inferred from the regional river in this profile.
- `groundwater` is semantic source intent, not aquifer simulation.

## 9. Determinism

- Same world request/profile version/seed must replay identical water service/node/segment signatures.
- Source-side choice uses a named deterministic seed domain, never call-order RNG.
- Alternate legal seeds must still produce a valid mixed-service water plan; anchor-side/topology variation is allowed when more than one legal corridor choice exists but is not required.
- Stable IDs are semantic and never depend on Godot Node identity.

## 10. Independent validation

`GlobalWaterInfrastructureValidator` independently verifies:

- one water-service record for every current settlement and no unknown settlement association;
- exactly one municipal service: the small town;
- all four non-small-town settlements use decentralized groundwater-source intent;
- municipal service references the one municipal network;
- decentralized services do not claim a municipal network;
- exactly one `groundwater_source`, one `treatment_storage` and one municipal `settlement_service` node;
- every municipal node is associated with the small town, lies inside world bounds, lies inside the small-town area site and lies on a real major road;
- exactly two non-zero cardinal municipal trunk segments;
- every trunk references a real source road/route and is completely contained by that road geometry;
- no municipal trunk crosses ridge geography;
- no municipal trunk reaches the regional world boundary;
- no duplicate water IDs/edges;
- the municipal node graph connects groundwater source -> treatment/storage -> settlement service with no orphan segment;
- water IDs do not collide with existing global/power IDs.

`GlobalWorldPlanner` treats water-validation failure as global generation failure.

## 11. System 20 projection seam

`System20AreaRequestProjector` gains:

`water_constraints_for_bounds(plan, bounds)`

It returns read-only:

- `services` — water-service records whose associated settlement center lies in the requested bounds;
- `nodes` — municipal water nodes inside the bounds;
- `segments` — municipal trunk segments clipped to the bounds while preserving semantic/source IDs.

`project_site()` remains unchanged. Slice 005 does not inject water facts into `AreaGenerationRequest`.

Expected current behavior:

- Candidate 006 exposes its `decentralized_source` groundwater service intent, but no municipal nodes/trunks and no visible well;
- the future small-town site exposes municipal service plus the municipal connection anchors/trunk.

## 12. Performance

Planning scans the existing small global settlement/site/road collections once and creates a tiny fixed-size municipal network. There is no per-frame work.

Projection is a bounded read-only scan over small water collections.

## 13. Failure behavior

Generation fails honestly on:

- missing/duplicate required settlement or area-site identity;
- unsupported current settlement classification;
- no legal incident small-town road corridor long enough for the bounded anchors;
- anchor outside the small-town site or off major-road geometry;
- invalid source road/route provenance;
- disconnected/duplicate municipal trunk geometry;
- ridge-crossing or regional-boundary municipal geometry;
- water validation failure.

No local deletion, reroll loop or presentation trick may hide invalid infrastructure.

## 14. Acceptance criteria

Exact-head `verify/system00d-global-world` must prove:

1. profile v5 is recorded;
2. the global plan contains five water-service records;
3. small town is municipal groundwater service;
4. crossroads + three hamlets are decentralized groundwater-source service;
5. exactly three municipal nodes exist with source/treatment/service roles;
6. exactly two municipal trunk segments exist and follow real major-road geometry;
7. all municipal anchors/trunks stay inside the small-town planning site and avoid ridge/boundary violations;
8. municipal source reaches treatment/storage and service through the recorded trunk;
9. same-seed replay includes identical water facts;
10. alternate seed still produces a legal independently validated water plan;
11. Candidate 006 `project_site()` request and generated semantic output remain exact;
12. Candidate 006 read-only water projection exposes only its decentralized service intent;
13. small-town read-only water projection exposes municipal service/nodes/trunks even though the local profile remains unsupported;
14. hydrology, bridge and power regressions remain valid;
15. unsupported `smalltown.center` / `rural.scattered` `project_site()` calls still fail honestly;
16. pure System 00D retains no dependency on System 19/20 owners, WHAT, WHEN, render/art, player/camera or streaming.

## 15. Future extension seams

Later approved systems may consume these facts for:

- real small-town waterworks/well/tank/tower placement;
- local municipal distribution mains and parcel service;
- private/shared rural well placement;
- pumps, pressure tanks and cisterns;
- building plumbing/fixture service;
- runtime water quantity/pressure/quality;
- electrical dependence of pumps and outage consequences;
- repair, purification and hauling gameplay;
- wastewater/septic design;
- causal infrastructure failure during outbreak simulation;
- streaming/coarse utility simulation.

Those systems consume the stable service/source topology rather than redefining which settlements are municipal versus decentralized.

## 16. North-star fit

The North Star requires world-spanning infrastructure to be coherent before local materialization and streaming. Slice 005 establishes the smallest believable rural potable-water model that preserves future survival consequences without pretending to simulate plumbing now: municipal groundwater service where a town supports it, decentralized groundwater intent where rural properties should remain independent.

## 17. Implementation result

Implemented on 2026-08-22 with `temperate.rural.region` **v5**. The canonical regional plan now records five settlement water-service intents: municipal groundwater for the small town and decentralized groundwater-source intent for the rural crossroads plus three hamlets.

The small-town municipal backbone records exactly three road-corridor connection anchors (`groundwater_source`, `treatment_storage`, `settlement_service`) and two contiguous `municipal_trunk` segments with source-road/source-route provenance. `GlobalWaterInfrastructureValidator` independently checks service classification, anchor/site/road legality, ridge and boundary discipline, ID uniqueness, exact two-edge topology and source-to-service reachability.

`System20AreaRequestProjector.water_constraints_for_bounds()` exposes these facts read-only. Candidate 006 remains semantically identical and exposes only its decentralized groundwater intent; it receives no fake well, municipal nodes or trunk. The unsupported small-town local profile remains honestly unsupported while its future planning window can already query municipal water truth.

The first integrated Slice 005 code head `415cca449acb598c517434bfc7b48ba07fb62340` passed `verify/system00d-global-world` (run `32600102767`) plus protected Systems 19–22 before final documentation promotion.