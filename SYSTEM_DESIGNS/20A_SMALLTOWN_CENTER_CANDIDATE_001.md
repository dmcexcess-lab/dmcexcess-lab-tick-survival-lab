# Tick Survival Lab — System 20A Small-Town Center Candidate 001

Status: **IMPLEMENTED**

Date: 2026-08-22

## 1. Goal

Add the first real `smalltown.center` System 20 local profile for the already-planned global site `area.smalltown.center.001`.

Candidate 001 must consume, rather than redefine, the System 00D v6 regional facts already crossing the site:

- inherited major roads;
- regional electrical nodes/feeders;
- municipal potable-water service, anchors and trunk;
- municipal wastewater service, anchors and collection trunk;
- hydrology/bridge facts if present.

The local result should read as a denser small rural town: compact main-road commercial frontage, connected interior local streets, residential frontage behind the main road, reusable infrastructure land reservations, and intentional vacant/open land toward the edges.

## 2. Approved decisions

Approved by the user on 2026-08-22:

1. Implement `smalltown.center` now that the regional infrastructure skeleton is stable.
2. Keep Rural Crossroads Candidate 006 frozen and semantically identical.
3. Generate a connected local town-street network branching from inherited regional roads.
4. Produce town-like blocks/parcels denser than the rural-crossroads morphology.
5. Concentrate small commercial frontage near the town center/main road and residential frontage on quieter local streets.
6. Use only the finalized System 19 building library in Candidate 001: Small Gas Station, Rural Diner, Trailer, Small Farmhouse, Large Farmhouse and Compact Laundry House.
7. Keep some commercial opportunities honestly vacant because the current System 19 library does not yet contain a complete downtown storefront/civic set.
8. Add a reusable System 20 infrastructure-reservation concept rather than hardcoding individual utility IDs into parcel logic.
9. Utility planning anchors reserve local physical land for future facilities without pretending those reserved rectangles are final treatment plants, wells, towers, substations or sewer works.
10. Local utility corridors preserve upstream connection geometry but do not implement runtime utility mechanics.
11. Do not switch the live System 22 critique world away from Candidate 006 in this slice; first prove the pure small-town plan.

## 3. Non-goals

Candidate 001 does not implement:

- new System 19 building archetypes;
- stores, police/fire, clinic, church, offices or other fake placeholder buildings;
- power poles/wires, energized state, outages or transformers;
- literal water/sewer pipes, pumps, pressure, plumbing or wastewater flow;
- final wellhead/tower/treatment-plant/substation art or collision;
- household/business/population truth;
- addresses/zoning economics;
- vehicles/traffic simulation;
- WHAT/WHEN runtime utility simulation;
- streaming/save partition ownership;
- renderer, camera, player or System 22 critique-runtime changes.

## 4. Public contract changes

### `AreaGenerationRequest`

Adds optional `inherited_planning_constraints: Array[Dictionary]`.

Each normalized upstream constraint has an explicit shape:

- stable `id`;
- `domain`: `hydrology`, `power`, `potable_water`, or `wastewater`;
- semantic `kind`;
- `reservation_role`: `facility`, `corridor`, or `service`;
- either a global `cell` or cardinal global `start`/`end` geometry;
- optional `width`;
- `blocks_parcels`;
- `blocks_local_roads`;
- source settlement/network/provenance fields where relevant.

Rural Crossroads projection continues to pass an empty planning-constraint collection so Candidate 006 remains exact.

### `GeneratedAreaPlan`

Adds:

- `reservations: Array[Dictionary]`;
- `blocks: Array[Dictionary]`.

A reservation has stable ID, source/domain/kind, `reservation_role`, a local global-coordinate `rect`, and explicit `blocks_parcels` / `blocks_local_roads` policy.

A block is semantic local morphology only: stable ID, global-coordinate `rect`, and `kind = town_block`. It is not a streaming chunk or persistence region.

## 5. Owners

Existing System 20 owners remain responsible for their domains.

New focused owners:

- `InfrastructureReservationPlanner.gd` — converts normalized upstream planning constraints into deterministic local reservation rectangles/corridors;
- `TownBlockPlanner.gd` — derives bounded semantic town blocks from the local street network.

Narrow changes:

- `AreaProfileCatalog.gd` adds `smalltown.center` v1;
- `AreaGenerationRequest.gd` stores/validates normalized inherited planning constraints;
- `LocalRoadPlanner.gd` adds profile-authorized town streets while preserving the rural-road path exactly;
- `ParcelPlanner.gd` consumes blocking reservations and classifies small-town land use;
- `OutdoorPropertyDressingPlanner.gd` treats reservation land as unavailable to random obstructive dressing;
- `GeneratedAreaPlan.gd` stores/signs blocks and reservations;
- `GeneratedAreaValidator.gd` verifies reservation/block legality and ordinary property exclusion;
- `LocalAreaGenerator.gd` orchestrates reservations -> roads -> blocks -> parcels -> existing building/access/dressing pipeline;
- `System20AreaRequestProjector.gd` normalizes System 00D small-town hydrology/power/water/wastewater facts into the new request seam;
- `LocalAreaGenerationSmoke.gd`, `SmallTownCenterGenerationSmoke.gd` and `GlobalWorldPlanningV6Smoke.gd` protect Candidate 001 plus Candidate 006 regressions.

## 6. Protected untouched neighbors

This slice must not change:

- System 00D global planning semantics/profile v6;
- Rural Crossroads Candidate 006 output;
- System 19 building grammar/archetypes;
- AreaMaterializationCoordinator behavior;
- WHAT, WHEN, collision, movement, door mechanics;
- recovered art/catalog/renderers;
- System 21 camera;
- System 22 live critique runtime;
- player/input/UI;
- streaming/population/outbreak systems.

## 7. Upstream projection rules

`System20AreaRequestProjector.project_site()` keeps using existing read-only 00D seams.

For `smalltown.center` only it normalizes:

- river segments as `hydrology/corridor`, blocking parcels and new local roads;
- bridge intents as service/provenance facts only;
- power feeder segments as `power/corridor`, blocking parcels but allowing local-road crossings;
- small-town `substation` as `power/facility`;
- potable-water municipal trunk as `potable_water/corridor`, blocking parcels but allowing local-road crossings;
- `groundwater_source` and `treatment_storage` as potable-water facilities;
- wastewater municipal collection trunk as `wastewater/corridor`, blocking parcels but allowing local-road crossings;
- `treatment_disposal` as a wastewater facility.

Service/connection nodes such as electrical settlement service, water settlement service and wastewater settlement collection remain queryable source facts but do not reserve arbitrary facility footprints.

The projector must verify that the small-town water and wastewater service records are municipal before producing the request.

## 8. Infrastructure reservation rules

`InfrastructureReservationPlanner` runs before local streets/parcels.

### Corridors

Cardinal upstream corridors become clipped reservation rectangles using the supplied width (minimum 1 cell).

Utility corridors:

- block ordinary parcels;
- do not block local-road crossings because utilities legitimately share/cross road rights-of-way.

Hydrology corridors block both parcels and new local roads; inherited regional road/bridge truth is preserved separately.

### Facilities

Facility anchors are upstream connection points on/near inherited road geometry, not final facility footprints.

System 20 chooses a deterministic legal adjacent reservation rectangle using profile-defined sizes and a small road-edge gap. Candidate 001 sizes are deliberately modest:

- substation reservation: 14×12;
- groundwater-source reservation: 12×12;
- water treatment/storage reservation: 16×16;
- wastewater treatment/disposal reservation: 20×16.

For each facility:

1. find an inherited road containing the source anchor;
2. enumerate legal rectangles on both sides of that road, centered along the source anchor;
3. reject rectangles outside the area, overlapping any road corridor, forbidden region, hydrology reservation or existing facility reservation;
4. choose deterministically from the remaining legal choices;
5. fail honestly if no legal reservation exists.

Facility reservations block parcels and new local roads. Water and wastewater facility reservations therefore remain physically distinct.

## 9. Small-town street morphology

`smalltown.center` uses a connected paved local-street network rather than rural gravel spurs.

Candidate 001 uses the inherited road nearest the site center as the town main-road spine. From that spine it creates a compact asymmetric grid:

- two perpendicular local cross streets at deterministic offsets on opposite sides of center;
- two parallel local connector/back streets on opposite sides of the main road;
- all local streets remain wholly internal to the area and connect through ordinary intersections;
- offsets receive bounded deterministic jitter while maintaining minimum block spacing;
- local street width is 3 cells;
- local streets use paved plain road surface without yellow centerline paint;
- local streets avoid facility/hydrology reservations;
- no local street creates an unauthorized area-boundary exit.

This produces several compact blocks without requiring a perfectly regular city grid.

Candidate 001 does not require a traffic signal. Existing Rural Crossroads signal behavior remains unchanged.

## 10. Town blocks

`TownBlockPlanner` derives central semantic `town_block` rectangles from gaps between the main spine and local cross/back streets.

Blocks:

- are global-coordinate morphology records only;
- remain inside the area;
- contain no road corridor cells;
- are carved around blocking facility/hydrology reservations rather than deleting otherwise useful surrounding town land;
- are not streaming/persistence boundaries;
- provide a future seam for zoning/addresses/land-value work.

## 11. Small-town parcels / land use

Candidate 001 is denser than Rural Crossroads:

- smaller local frontage ranges;
- compact ordinary residential setbacks;
- no farmstead target inside the town-center profile;
- four small-commercial opportunities near the center/main road;
- only the first two commercial opportunities receive the current gas-station and diner archetypes; the remaining commercial opportunities stay honestly vacant;
- ten residential opportunities, preferentially using `local_town` frontage;
- remaining legal parcels become deterministic `vacant`, `agricultural` or `wilderness`/open land, with density falling toward the site edge.

Ordinary parcels/buildings/driveways/parking may not overlap any reservation with `blocks_parcels = true`.

Existing System 19 primary-door alignment and real road-flush parking rules remain unchanged.

Inherited-road frontage is clipped to the actual inherited segment extent. A regional road that legitimately terminates inside the local 256×256 site therefore cannot accidentally authorize parcels beyond its physical centerline geometry.

## 12. Environment / presentation semantics

Candidate 001 reuses `temperate.rural` v3 environment semantics.

Local town streets use existing `ground.road_plain` pavement with no centerline paint. No new art semantic is introduced.

Reservation rectangles are planning facts only; they do not receive fake facility art or special ground presentation in this slice.

Random natural dressing must not place obstructive props inside reserved facility/corridor land.

## 13. Validation / acceptance

Exact-head `verify/system20-local-area` and `verify/system00d-global-world` prove:

1. `smalltown.center` v1 is a supported System 20 profile;
2. `area.smalltown.center.001` projects successfully from the current System 00D v6 global plan;
3. all inherited regional road IDs and real boundary contacts are preserved; regional segments may legally terminate inside the local site;
4. the generated plan has a connected interior `local_town` street network with no boundary exits;
5. semantic town blocks are present and legal;
6. four small-commercial opportunities exist near the main-road center;
7. exactly gas station + diner use the current commercial library and at least two commercial opportunities remain honestly vacant;
8. ten residential opportunities exist, with a majority on `local_town` frontage;
9. all occupied approaches terminate directly at real System 19 primary doors;
10. any real building-owned parking frontage still reaches its road using the existing Candidate 006 rule;
11. infrastructure reservations are deterministic, inside bounds, source-traceable and non-overlapping where blocking;
12. ordinary parcels/buildings do not occupy blocking infrastructure reservations;
13. potable-water and wastewater facility reservations are physically distinct;
14. hydrology reservation is honored if present;
15. same request/seed replays exactly and alternate legal seeds vary without reroll loops;
16. Candidate 006 request and generated signature remain exact;
17. unsupported `rural.scattered` / hamlet local profiles still fail honestly;
18. no System 19/render/camera/player/WHAT/WHEN/streaming contract changes.

## 14. Future seams

This slice intentionally leaves room for:

- real small-town storefront/civic System 19 content;
- sidewalks, alleys and richer parking;
- parcel addresses/zoning/land value;
- exact utility facility placement/materialization inside reserved land;
- local utility distribution to parcels/buildings;
- runtime power/water/wastewater state;
- households/businesses/jobs;
- vehicles/traffic;
- streaming/materialization.

Future systems consume the stable reservation/block/parcel facts instead of moving already-planned regional infrastructure.

## 15. North-star fit

The North Star requires large-scale roads/utilities to exist before local parcels and detailed materialization. Candidate 001 is the first local settlement profile to prove that hierarchy end to end: a recognizable town grows around inherited global truth instead of locally inventing a conflicting world.

## 16. Implementation result

Implemented on 2026-08-22/23 against System 00D `temperate.rural.region` v6.

The integrated implementation added the approved request/plan seams, `smalltown.center` v1, reusable infrastructure reservations, semantic town blocks, a connected paved `local_town` network, town-specific parcel classification, reservation-aware outdoor dressing, and global-to-local infrastructure normalization.

Integration exposed and corrected two assumptions that were valid for Candidate 006 but not for a real settlement site:

- an inherited regional road may legally terminate inside a local planning window; only actual boundary contacts require an allowed boundary exit;
- inherited-road parcel frontage must be limited to the real segment extent rather than the full local-area axis.

Candidate 006 remains exact: its projected request signature, generated semantic signature, profile versions, reservations and blocks are unchanged.

The first fully green implementation head is `3a5924f48acb3165c29c65c778802f6a209d98eb`. Exact-head verification succeeded for System 00D, Systems 19–22 and Pages deployment, including the dedicated `SmallTownCenterGenerationSmoke.gd` contract and `GlobalWorldPlanningV6Smoke.gd` integration regression.