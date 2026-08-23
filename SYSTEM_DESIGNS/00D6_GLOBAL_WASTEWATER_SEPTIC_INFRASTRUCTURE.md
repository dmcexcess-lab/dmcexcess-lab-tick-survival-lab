# Tick Survival Lab — System 00D Slice 006 Wastewater / Septic Infrastructure

Status: **IMPLEMENTED**

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
- `service_mode`: `municipal` or `decentralized_septic`;
- `disposal_type`: `municipal_treatment` or `onsite_septic`;
- `network_id` for municipal service, otherwise empty;
- `separation_policy`: empty for municipal service, `potable_source_clearance_required` for decentralized septic.

A decentralized service record means downstream local/property generation must provide legal septic/disposal geometry with potable-source clearance. It does not pre-place a tank or field globally.

### Municipal wastewater node record

The current municipal network records exactly two planning anchors:

- `settlement_collection` at the small-town center;
- `treatment_disposal` on a legal road corridor inside the small-town site.

Each stores stable `id`, `network_id`, semantic `kind`, global tactical `cell`, and the small-town `settlement_id`. These are connection anchors, not exact physical plant/manhole footprints.

### Municipal wastewater segment record

The current municipal network records one segment with `wastewater_class = municipal_collection_trunk`, cardinal start/end cells, ordinal, and source-road/source-route provenance.

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

The v6 profile uses a 64-cell treatment anchor offset, farther from town center than the potable-water treatment anchor while remaining inside the 256×256 small-town planning site.

## 8. Potable-water relationship

- Wastewater planning runs after potable water and consumes only its public plan facts.
- The municipal treatment/disposal anchor may not occupy any potable-water node cell.
- The municipal wastewater trunk may not overlap the potable-water municipal trunk.
- The selected wastewater direction may not equal the potable-water groundwater-source direction.
- Decentralized septic service records explicitly require potable-source clearance later, but no arbitrary parcel-distance rule is invented before parcel/well/septic footprints exist.

## 9. Geography / hydrology relationship

Municipal wastewater geometry follows existing major-road geometry, remains inside the small-town area site, inherits and independently rechecks ridge avoidance, does not reach the regional boundary, and does not infer an outfall from the regional river.

## 10. Determinism

Same request/profile version/seed replays identical wastewater facts. Corridor choice uses a named deterministic seed domain. Alternate legal seeds must independently validate. Stable IDs never depend on Godot Node identity.

## 11. Independent validation

`GlobalWastewaterInfrastructureValidator` independently verifies complete five-settlement service classification, one municipal small-town service, four rural septic intents with clearance policy, exactly two municipal nodes and one road-contained trunk, small-town/site/bounds legality, ridge/boundary discipline, potable-water node/trunk separation, exact collection-to-treatment connectivity, and ID uniqueness against existing global/power/water facts.

`GlobalWorldPlanner` treats wastewater-validation failure as global generation failure.

## 12. System 20 projection seam

`System20AreaRequestProjector.wastewater_constraints_for_bounds(plan, bounds)` returns read-only `services`, `nodes`, and clipped `segments`. `project_site()` remains unchanged.

Candidate 006 exposes exactly its decentralized-septic intent and no municipal nodes/trunk. The future small-town site exposes municipal service plus collection/treatment anchors and trunk even while `smalltown.center` remains unsupported.

## 13. Performance

Planning scans the already-small settlement/site/road/water collections once and creates a tiny fixed-size municipal network. Projection is a bounded read-only scan. There is no per-frame work.

## 14. Failure behavior

Generation fails honestly on missing/duplicate required settlement/site identity, unsupported settlement classification, missing potable-water source truth, no separate legal treatment corridor, off-road/out-of-site geometry, potable-water overlap, ridge/boundary violation, duplicate/orphan records, or independent validation failure.

## 15. Acceptance criteria

`verify/system00d-global-world` proves v6 profile identity, five wastewater services, one municipal/four septic split, four rural clearance policies, exact two-node/one-trunk municipal topology, road/site legality, potable-water separation, deterministic replay, legal alternate seed, exact Candidate 006 regression, correct Candidate 006/small-town wastewater projection behavior, existing hydrology/bridge/power/water regressions, System 20 regression and pure-owner dependency boundaries.

## 16. Future extension seams

Later approved systems may consume these facts for real small-town sewer layout, local collection mains/manholes, treatment facilities, septic tanks/drain fields, well/septic clearance, toilets/drains, sewage backups, contamination/cleanup, power-dependent pumps, repair/pumping gameplay, outbreak infrastructure failure and streaming/coarse utility simulation.

## 17. North-star fit

The North Star requires utilities to be coherent before local materialization and streaming. Slice 006 completes the current rural region's high-level water/waste service skeleton using the smallest causal model that prevents later world-generation contradictions while deliberately deferring physical plumbing and runtime sanitation simulation to their proper owners.

## 18. Implementation result

Implemented on 2026-08-22 with `temperate.rural.region` **v6**. The global plan now records five wastewater-service intents: municipal treatment for the small town and decentralized septic intent for the rural crossroads plus three hamlets. Every rural septic service carries `potable_source_clearance_required` without inventing parcel geometry prematurely.

The municipal wastewater network records exactly two planning anchors (`settlement_collection`, `treatment_disposal`) and one `municipal_collection_trunk` on named major-road geometry. The planner consumes the already-generated potable-water source direction and selects a different legal corridor so wastewater does not reuse the potable-water source/trunk alignment.

The first integrated Slice 006 code head `d3eaab10a522c371a98b6059846acb34220cac7e` passed `verify/system00d-global-world` (run `32610287488`) plus protected System 19, System 20, System 22 and Pages checks before final documentation promotion.