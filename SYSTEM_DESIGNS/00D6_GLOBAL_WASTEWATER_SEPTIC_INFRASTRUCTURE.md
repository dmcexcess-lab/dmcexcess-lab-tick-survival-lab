# Tick Survival Lab — System 00D Slice 006 Wastewater / Septic Infrastructure

Status: **APPROVED**

Date: 2026-08-22

## 1. Goal

Add deterministic wastewater-service planning truth to System 00D before small-town/rural local generation, streaming, population and outbreak simulation depend on it.

Slice 006 mirrors the believable rural split established by potable water without pretending every remote settlement has municipal sewer:

- the current small town receives municipal wastewater collection/treatment intent;
- the rural crossroads and three rural hamlets receive decentralized septic intent;
- future local/property planning must keep decentralized wastewater facilities clear of potable-water sources.

Canonical order becomes:

`global request -> geography -> hydrology -> settlements/sites -> major roads -> bridge intents -> regional electrical infrastructure -> potable water infrastructure -> wastewater/septic infrastructure -> planning regions -> validation -> global plan`

System 00D records service topology and connection anchors only. It does not place literal septic tanks, drain fields, manholes or treatment buildings, mutate WHAT, or simulate sewage flow/contamination.

## 2. Approved decisions

Approved by the user on 2026-08-22:

1. Finish wastewater/septic planning before beginning the real small-town local profile so later local generation cannot invalidate utility topology.
2. `settlement.smalltown.001` uses municipal wastewater service.
3. The rural crossroads and three rural hamlets use decentralized septic intent.
4. Municipal collection/treatment facts are planning connection anchors, not exact physical facility footprints.
5. The small-town municipal wastewater trunk follows an existing major-road corridor inside the small-town planning site.
6. Prefer a legal treatment/disposal corridor different from the potable-water groundwater-source direction, preventing the municipal wastewater anchor from occupying the potable-water source/trunk corridor.
7. Rural septic intent carries an explicit `potable_source_clearance_required` policy; the exact parcel-scale clearance distance remains downstream System 20/environment-profile ownership because no septic/well footprints exist globally yet.
8. Expose a read-only System 20 wastewater projection seam without changing `AreaGenerationRequest` or Candidate 006 output.
9. Bump `temperate.rural.region` from v5 to v6 because same-seed global output gains canonical wastewater-service truth.

## 3. Non-goals

Slice 006 does not implement:

- tactical septic tanks, drain fields, sewer pipes, manholes, lift stations or treatment buildings;
- building toilets/drains or fixture wastewater state;
- sewage quantity, flow, blockage, backup or pumping;
- contamination, disease, smell or environmental-health mechanics;
- treatment-plant operation, outage coupling or repair;
- storm drains or combined sewer systems;
- literal parcel well/septic separation distances;
- WHAT materialization;
- WHEN simulation;
- streaming/save ownership;
- population/outbreak behavior;
- changes to System 19, System 20 local generation, render/art, camera or player mechanics.

## 4. Owners

Pure System 00D owners under `game/scripts/generation/world/`:

- `GlobalWastewaterInfrastructurePlanner.gd` — classifies settlement service mode and creates the small-town municipal collection/treatment anchors/trunk;
- `GlobalWastewaterInfrastructureQuery.gd` — read-only wastewater service/network queries;
- `GlobalWastewaterInfrastructureValidator.gd` — independently verifies service classification and municipal topology;
- `GeneratedGlobalWorldPlan.gd` — stores wastewater facts and includes them in deterministic signatures;
- `GlobalWorldPlanner.gd` — orchestrates wastewater planning after potable water and composes validation;
- `GlobalWorldProfileCatalog.gd` — owns Slice 006 profile version and bounded treatment-anchor offset.

Separate downstream adapter:

- `game/scripts/generation/integration/System20AreaRequestProjector.gd` — read-only local-window wastewater projection only.

## 5. Public global-plan contract

`GeneratedGlobalWorldPlan` gains:

- `wastewater_services: Array[Dictionary]`;
- `wastewater_nodes: Array[Dictionary]`;
- `wastewater_segments: Array[Dictionary]`.

### Wastewater service record

Exactly one record exists for every current settlement:

- stable `id`;
- `settlement_id`;
- `service_mode`:
  - `municipal`;
  - `decentralized_septic`;
- `disposal_type`:
  - `municipal_treatment` for the small town;
  - `onsite_septic` for rural settlements;
- `network_id` for municipal service, otherwise empty;
- `separation_policy`: empty for municipal service, `potable_source_clearance_required` for decentralized septic.

A decentralized service record means downstream local/property generation must provide legal septic/disposal geometry with potable-source clearance. It does not pre-place a tank or field globally.

### Municipal wastewater node record

The current municipal network records exactly two planning anchors:

- `settlement_collection` at the small-town center;
- `treatment_disposal` on a legal road corridor inside the small-town site.

Each stores stable `id`, `network_id`, semantic `kind`, global tactical `cell`, and the small-town `settlement_id`.

These are connection anchors, not exact physical plant/manhole footprints.

### Municipal wastewater segment record

The current municipal network records one `collection_trunk` segment:

- stable `id` / `network_id`;
- `wastewater_class = municipal_collection_trunk`;
- cardinal `start` / `end` global cells;
- stable `ordinal`;
- `source_road_id` and `source_route_id` proving road-corridor provenance.

## 6. Service model

Current `temperate.rural.region` classification:

- `settlement.smalltown.001` -> `municipal`, `municipal_treatment`;
- `settlement.rural.crossroads.001` -> `decentralized_septic`, `onsite_septic`;
- `settlement.rural.hamlet.001` -> `decentralized_septic`, `onsite_septic`;
- `settlement.rural.hamlet.002` -> `decentralized_septic`, `onsite_septic`;
- `settlement.rural.hamlet.003` -> `decentralized_septic`, `onsite_septic`.

Unknown current settlement IDs fail honestly.

## 7. Municipal anchor / routing model

1. Find the small-town settlement and matching area site.
2. Read the already-generated potable-water groundwater-source anchor.
3. Derive its cardinal direction from the small-town center.
4. Enumerate major-road directions incident to the small-town center that remain inside the area site for the configured wastewater-treatment offset.
5. Remove the potable-water source direction so wastewater does not reuse the water-source/trunk corridor.
6. Prefer primary-road options where legal; choose among remaining legal options deterministically with a named seed domain.
7. Place `settlement_collection` at the small-town center.
8. Place `treatment_disposal` outward on the chosen road corridor.
9. Create one `municipal_collection_trunk` from collection to treatment/disposal with source road/route provenance.
10. Fail honestly if no separate legal wastewater corridor exists.

The current profile uses a treatment anchor farther from town center than the potable-water treatment anchor while remaining inside the 256×256 small-town planning site.

## 8. Potable-water relationship

- Wastewater planning runs after potable water and consumes only its public plan facts.
- The municipal treatment/disposal anchor may not occupy any potable-water node cell.
- The municipal wastewater trunk may not overlap the potable-water municipal trunk.
- The selected wastewater direction may not equal the potable-water groundwater-source direction.
- Decentralized septic service records explicitly require potable-source clearance later, but no arbitrary parcel-distance rule is invented before parcel/well/septic footprints exist.

This preserves the future contamination/placement seam without turning Slice 006 into groundwater or health simulation.

## 9. Geography / hydrology relationship

- Municipal wastewater geometry follows existing major-road geometry, inheriting road ridge avoidance and independently rechecking it.
- Municipal nodes/trunk remain inside the small-town area site and do not reach the regional world boundary.
- No wastewater outfall is inferred from the regional river in this profile.
- `treatment_disposal` is semantic planning intent, not a modeled discharge point.

## 10. Determinism

- Same request/profile version/seed replays identical wastewater service/node/segment signatures.
- Corridor choice uses a named deterministic seed domain, never call-order RNG.
- Alternate legal seeds must still produce a valid independently validated wastewater plan.
- Stable IDs never depend on Godot Node identity.

## 11. Independent validation

`GlobalWastewaterInfrastructureValidator` independently verifies:

- one wastewater-service record for every current settlement;
- exactly one municipal service: the small town;
- all four rural settlements use decentralized septic with `potable_source_clearance_required`;
- municipal service references the one municipal wastewater network while rural services do not;
- exactly one `settlement_collection` and one `treatment_disposal` node;
- both nodes belong to the small town, lie inside world bounds and the small-town site, and lie on a real major road;
- exactly one non-zero cardinal `municipal_collection_trunk`;
- the trunk references a real road/route and is fully contained by that road geometry;
- the trunk avoids ridge geography and regional boundary contact;
- treatment/disposal does not share a potable-water node cell;
- wastewater trunk does not overlap any potable-water municipal trunk;
- collection -> treatment connectivity is exact with no orphan geometry;
- wastewater IDs do not collide with existing global/power/water IDs.

`GlobalWorldPlanner` treats wastewater-validation failure as global generation failure.

## 12. System 20 projection seam

`System20AreaRequestProjector` gains:

`wastewater_constraints_for_bounds(plan, bounds)`

It returns read-only:

- `services` — wastewater-service records whose associated settlement center lies in the requested bounds;
- `nodes` — municipal wastewater nodes inside the bounds;
- `segments` — municipal collection trunk segments clipped to the bounds while preserving IDs/provenance.

`project_site()` remains unchanged.

Expected behavior:

- Candidate 006 exposes exactly its decentralized-septic intent and no municipal nodes/trunk;
- the future small-town site exposes municipal service plus collection/treatment anchors and trunk even while `smalltown.center` remains unsupported.

## 13. Performance

Planning scans the already-small settlement/site/road/water collections once and creates a tiny fixed-size municipal network. There is no per-frame work.

Projection is a bounded read-only scan.

## 14. Failure behavior

Generation fails honestly on missing/duplicate required settlement/site identity, unsupported settlement classification, missing potable-water source truth, no separate legal treatment corridor, off-road/out-of-site geometry, potable-water overlap, ridge/boundary violation, duplicate/orphan records, or independent validation failure.

No reroll loop, downstream deletion or presentation trick may hide invalid infrastructure.

## 15. Acceptance criteria

Exact-head `verify/system00d-global-world` must prove:

1. profile v6 is recorded;
2. five wastewater-service records exist;
3. small town is municipal treatment while crossroads + three hamlets are decentralized septic;
4. all four rural records carry `potable_source_clearance_required`;
5. exactly two municipal wastewater nodes and one collection trunk exist;
6. municipal wastewater geometry follows real major-road geometry inside the small-town site;
7. wastewater treatment/trunk does not occupy/overlap potable-water municipal geometry;
8. same-seed replay includes identical wastewater facts;
9. alternate seed still independently validates;
10. Candidate 006 `project_site()` request/generated semantic output remain exact;
11. Candidate 006 wastewater projection exposes only decentralized septic intent;
12. small-town wastewater projection exposes municipal service/nodes/trunk while the local profile remains unsupported;
13. existing hydrology, bridge, power and potable-water regressions remain green;
14. pure System 00D retains no dependency on System 19/20 owners, WHAT, WHEN, render/art, player/camera or streaming.

## 16. Future extension seams

Later approved systems may consume these facts for real small-town sewer layout, local collection mains/manholes, treatment facilities, septic tanks/drain fields, well/septic clearance, toilets/drains, sewage backups, contamination/cleanup, power-dependent pumps, repair/pumping gameplay, outbreak infrastructure failure and streaming/coarse utility simulation.

Those systems consume the stable municipal-vs-septic service decision rather than redefining it.

## 17. North-star fit

The North Star requires utilities to be coherent before local materialization and streaming. Slice 006 completes the current rural region's high-level water/waste service skeleton using the smallest causal model that prevents later world-generation contradictions while deliberately deferring physical plumbing and runtime sanitation simulation to their proper owners.