# Tick Survival Lab — System 20B Rural-Scattered / Hamlet Candidate 001

Status: **IMPLEMENTED**

Date: 2026-08-22

## 1. Goal

Add the real `rural.scattered` System 20 local profile required by the three existing System 00D v6 hamlet sites:

- `area.rural.scattered.001` / `settlement.rural.hamlet.001`;
- `area.rural.scattered.002` / `settlement.rural.hamlet.002`;
- `area.rural.scattered.003` / `settlement.rural.hamlet.003`.

The profile should represent a sparse roadside hamlet/country cluster rather than another crossroads or miniature town: a real inherited regional road, a couple of short gravel local lanes, scattered homes/farmsteads, substantial open/agricultural land, no fake commercial center, and explicit consumption of the already-planned rural utility/service facts.

The three global hamlet sites share one profile but vary deterministically by their already-distinct site seeds and inherited road geometry.

## 2. Approved decisions

Approved by the user on 2026-08-22:

1. Add `rural.scattered` **v1** as the third System 20 area profile; keep `temperate.rural` v3.
2. Keep Rural Crossroads Candidate 006 and Small-Town Center Candidate 001 semantically exact.
3. Treat the hamlet as **sparse settlement along/behind a regional road**, not a centered business district.
4. Generate exactly **two short 3-cell gravel `local_rural` lanes** from a selected inherited road segment, using bounded deterministic geometry that works for horizontal or vertical inherited roads.
5. Give those lanes real parcel frontage; they remain internal and create no area-boundary exits.
6. Create **zero commercial targets** in Candidate 001. The current System 19 gas station/diner should not be repeated merely because they exist.
7. Target **six occupied rural properties**: four residential + two farmstead.
8. Require at least **four of the six** occupied properties to use local-lane frontage so the hamlet does not collapse into highway-strip development.
9. Preserve large open space: at least **72% of non-road area remains unbuilt**.
10. Use only the finalized System 19 residential library: Trailer, Small Farmhouse, Large Farmhouse and Compact Laundry House; farmstead slots use the two farmhouse archetypes.
11. Reuse the existing infrastructure-constraint seam. Rural decentralized water/septic records remain **non-blocking service intent**, not invented well/septic coordinates. Regional electrical feeder geometry may reserve its existing corridor, but no rural substation/facility is invented.
12. Produce no semantic town blocks for this profile; `blocks` remains empty.
13. Do not switch System 22 live presentation away from Candidate 006 in this slice.

## 3. Non-goals

Candidate 001 does not implement:

- new System 19 buildings;
- a general store, church, barn, police/fire, clinic or other fake hamlet center content;
- literal private wells, pumps, septic tanks, drain fields or household utility hookups;
- tactical electrical poles/wires or runtime energized state;
- physical water/sewer plumbing or sanitation state;
- addresses/land ownership/zoning economics;
- households/population/jobs/business truth;
- vehicles/traffic;
- streaming/save partition ownership;
- renderer/camera/player/UI changes;
- changes to System 00D settlement, road, hydrology or utility planning.

## 4. Public contract impact

No new System 20 public data contract was required.

Candidate 001 reuses the already-implemented:

- `AreaGenerationRequest.inherited_planning_constraints`;
- `GeneratedAreaPlan.reservations`;
- `GeneratedAreaPlan.blocks` (empty for this profile);
- generic road/parcel/building/access/dressing contracts.

Narrow catalog/API changes:

- `AreaProfileCatalog` adds `RURAL_SCATTERED = &"rural.scattered"` and v1 profile data;
- `LocalAreaGenerator.area_profile_ids()` exposes the new profile;
- `System20AreaRequestProjector.project_site()` recognizes `rural.scattered` and normalizes rural upstream service facts into the existing planning-constraint seam.

## 5. Protected untouched neighbors

Implementation preserves:

- System 00D v6 global plan semantics and profile version;
- Rural Crossroads Candidate 006 request/signature;
- Small-Town Center Candidate 001 request/signature;
- System 19 archetypes/grammar;
- `AreaMaterializationCoordinator` behavior;
- WHAT, WHEN, collision, movement, doors;
- art/render/camera/player/input/UI;
- System 22 live critique target;
- streaming/population/outbreak systems.

## 6. Global -> rural-scattered projection

For each `rural.scattered` site, the projector keeps the real inherited major-road segments exactly as supplied by System 00D.

It also builds a bounded rural planning-constraint set from existing read-only seams.

### Hydrology

If a river segment intersects a future legal rural-scattered site, normalize it as a blocking `hydrology/corridor` exactly as Small-Town Candidate 001 does; bridge intents remain non-blocking service/provenance points.

The current System 00D v6 hamlet placement already enforces river clearance, so the canonical three hamlet sites have no hydrology reservation. The seam remains general rather than assuming this forever.

### Electrical

Regional feeder segments inside the site become `power/corridor` constraints:

- `blocks_parcels = true`;
- `blocks_local_roads = false`.

The hamlet electrical `settlement_service` node becomes a non-blocking `power/service` point. No `power/facility` constraint is created because System 00D defines no rural substation there.

### Potable water

The projector requires exactly one matching rural water service with:

- `service_mode = decentralized_source`;
- `source_type = groundwater`.

Because System 00D intentionally does not choose an exact rural well cell, System 20 records the service intent at the settlement/site center as a **non-blocking service anchor only**. It creates no facility reservation and no well geometry.

### Wastewater

The projector requires exactly one matching rural wastewater service with:

- `service_mode = decentralized_septic`;
- `disposal_type = onsite_septic`;
- `separation_policy = potable_source_clearance_required`.

It likewise records this as a non-blocking service anchor at the settlement/site center. Candidate 001 does not guess tank/drain-field coordinates.

This keeps the crucial future rule visible: when parcel-scale well/septic placement is eventually designed, it must satisfy the existing potable-source-clearance policy.

## 7. Selecting the inherited hamlet spine

The Rural Crossroads local-road code assumes a horizontal primary road; that assumption is not reused for hamlets.

`rural.scattered` selects one inherited segment as the local hamlet spine using this bounded rule:

1. prefer an inherited road whose center path contains the site center;
2. otherwise choose the inherited segment with minimum Manhattan distance from its path to the site center;
3. break ties by road class priority (`primary` before `secondary`) and stable road ID;
4. accept either horizontal or vertical cardinal orientation;
5. keep every inherited segment in the local plan regardless of which one is selected as the lane-branching spine.

The selected spine is only a local morphology reference. System 20 does not rewrite or merge global road IDs.

## 8. Rural lane morphology

`LocalRoadPlanner` implements a dedicated `road_layout = rural_scattered_lanes` path.

Candidate 001 creates exactly two internal public gravel lanes.

For each lane:

1. enumerate usable branch-anchor path cells on the selected inherited spine with a permissive bounded anchor pool;
2. choose distinct branch anchors using named deterministic seed domains;
3. require the two anchors to remain meaningfully separated;
4. choose opposite or otherwise separated sides of the spine where legal, so both lanes do not form one visual comb by default;
5. extend a long perpendicular developable branch from the spine, then add one short lateral bend/tail;
6. use 3-cell width and `road_class = local_rural`;
7. use the rural gravel surface family with no centerline paint;
8. enable parcel frontage;
9. require the full road corridor—not only its centerline—to remain wholly internal to the 256×256 area;
10. avoid hydrology/facility reservations and positive-length overlap with inherited/local roads;
11. allow crossing a non-blocking regional utility corridor where necessary;
12. reject illegal near-edge anchors by actual full-corridor fit rather than globally over-constraining the anchor pool;
13. fail honestly after exhausting the finite candidate set rather than rerolling indefinitely.

The implemented v1 profile uses a 24-cell branch-anchor margin, 44-cell minimum anchor separation, 72-cell perpendicular branch, and 24-cell short lateral tail. Those values are profile data rather than public-contract constants.

The two lanes create ordinary uncontrolled junctions with the inherited spine. Candidate 001 requires no traffic signal.

## 9. No town blocks

`TownBlockPlanner` remains town-specific.

For `rural.scattered`:

- `GeneratedAreaPlan.blocks` is empty;
- parcels are road-frontage rural properties, not subdivisions inside semantic urban blocks;
- this profile does not invent a village center merely to reuse the small-town abstraction.

## 10. Parcel morphology

`land_use_mode = rural_scattered` makes parcel ranking use the **site center** rather than the first generated intersection as its semantic reference.

Implemented v1 profile targets:

- `commercial_count = 0`;
- `residential_count = 4`;
- `farmstead_count = 2`;
- `local_residential_target = 3`;
- `local_farmstead_target = 1`;
- at least 4/6 total occupied properties on `local_rural` frontage;
- frontage/depth ranges similar to Rural Crossroads but with wider gaps and more edge openness;
- residential facade setback remains the existing rural 1-cell value;
- farmstead setback remains 4 cells;
- no commercial setback policy is exercised.

Classification order:

1. reserve the required local-lane residential/farmstead targets;
2. fill remaining residential/farmstead targets from legal inherited/local frontage without forcing highway use;
3. classify the remainder as deterministic `agricultural`, `wilderness` or `vacant/open` land;
4. bias farther/edge parcels toward open/agricultural/wilderness use;
5. require at least 72% of non-road cells to remain unbuilt.

## 11. Building use

Candidate 001 uses only current finalized System 19 residential content.

Residential pool:

- `residential.trailer.singlewide`;
- `residential.house.farm_small`;
- `residential.house.farm_large`;
- `residential.house.compact_laundry`.

Farmstead pool:

- `residential.house.farm_small`;
- `residential.house.farm_large`.

No commercial archetype is requested.

Existing System 20 rules remain mandatory:

- building placement comes only from System 19 descriptors;
- the real generated `door.exterior.primary` is the final access truth;
- approaches remain frontage-normal and end directly at that door;
- `ground.parking*` is extended to the road only if a building actually exposes qualifying parking frontage;
- empty rural grass is never implicit parking.

## 12. Environment / property dressing

Reuse `temperate.rural` v3.

Candidate 001 is more open than both existing profiles:

- substantial two-dimensional tree/shrub/rock noise outside occupied/access/reserved geometry;
- agricultural/field semantics around farmstead/open parcels where current rules support them;
- one mailbox per occupied residential/farmstead property using the existing rule;
- no traffic signal;
- no fake civic props or utility hardware.

Natural dressing continues avoiding roads, approaches, buildings, active fields where required, and any blocking infrastructure/hydrology reservation.

## 13. Validation / acceptance

Exact-head `verify/system20-local-area` and `verify/system00d-global-world` prove:

1. `rural.scattered` v1 is supported;
2. all three current System 00D hamlet sites project successfully;
3. each projected request keeps exact inherited regional road IDs/geometry/boundary contacts;
4. each request carries the correct matching decentralized groundwater and septic service intent;
5. each request preserves `potable_source_clearance_required` without inventing a well/septic facility;
6. regional power facts remain source-traceable and no fake substation is created;
7. each canonical hamlet generates exactly two internal 3-cell gravel `local_rural` lanes;
8. lane generation works regardless of horizontal/vertical selected inherited spine;
9. lanes remain internal, connected to inherited road truth, and create no unauthorized boundary exits;
10. no semantic town blocks are generated;
11. zero commercial parcels/buildings are required;
12. exactly four residential + two farmstead occupied targets exist;
13. at least four of six occupied properties use `local_rural` frontage, including >=3 residential and >=1 farmstead;
14. every occupied approach reaches the real System 19 primary door directly;
15. no blocking reservation overlaps ordinary parcel/building/access geometry;
16. at least 72% of non-road area remains unbuilt;
17. environment dressing remains deterministic, broad and non-diagonal;
18. same request/seed replays exactly;
19. alternate legal seeds vary lane/property/environment layout without reroll loops;
20. Rural Crossroads Candidate 006 remains exact;
21. Small-Town Candidate 001 remains exact;
22. no System 00D/System 19/materialization/render/camera/player/WHAT/WHEN/streaming contract changes.

`RuralScatteredGenerationSmoke.gd` tests all three canonical hamlet sites rather than treating one hand-picked seed as representative. It also directly tests both horizontal and vertical inherited-spine cases.

## 14. Implemented surface

System 20 implementation changes are bounded to:

- `AreaProfileCatalog.gd`;
- `LocalAreaGenerator.gd` profile exposure only;
- `System20AreaRequestProjector.gd` rural-scattered normalization plus the boundary-tangent road-projection correction discovered during integration;
- `LocalRoadPlanner.gd` orientation-agnostic rural-scattered lane branch;
- `ParcelPlanner.gd` rural-scattered center/classification path;
- `RuralScatteredGenerationSmoke.gd`;
- `.github/workflows/local-area-generation.yml` gate coverage;
- `GlobalWorldPlanningV6Smoke.gd` three-site projection/generation coverage;
- canonical docs/changelog.

No new major owner was required; this slice is a new System 20 profile using existing System 20 responsibilities.

### Integration correction discovered during implementation

A regional road whose centerline lies purely along a local planning area's mathematical boundary is a **boundary tangency**, not a road that enters the area. `System20AreaRequestProjector.road_constraints_for_bounds()` now ignores positive-length boundary-tangent overlaps as well as single-point tangencies. This prevents a full-width inherited-road corridor from being falsely projected partly outside the local area while preserving real roads that actually enter/cross it.

## 15. Future seams

With `rural.scattered` implemented, the current five System 00D settlement sites all have real System 20 local profiles.

That creates a clean point to choose among the next major layers:

- System 00F streaming/materialization orchestration;
- richer System 19 settlement content such as storefront/civic/agricultural outbuildings;
- parcel addresses/ownership/zoning;
- System 00E households/population/jobs/outbreak/player story.

The recommended architecture order remains: finish logical places first, then let streaming partition them technically, then populate those real places.

## 16. North-star fit

A rural hamlet feels like a real sparse place in the same continuous world, not a repeated tactical template. This implementation consumes the actual global road/utility/service facts, creates only the local roads/properties that belong to System 20, preserves substantial open land, and refuses to invent businesses or physical utility hardware that do not yet have real owners.

## 17. Implementation verification

First fully green implementation head:

`92d896d1d73cc67cb6df99b5e9102f9404fa21bc`

On that exact code head, all relevant protected checks succeeded:

- `verify/system00d-global-world`;
- `verify/system19-local-building`;
- `verify/system20-local-area`;
- `verify/system21-camera-view`;
- `verify/system22-area-critique`.

Final documentation promotion is verified separately on the exact final repository head before the slice is considered formally closed.