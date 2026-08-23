# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 006 + SMALL-TOWN CENTER CANDIDATE 001 + INITIAL MATERIALIZATION**

Date: 2026-08-22

System 20 is the local planning layer between System 00D global world planning and finalized System 19 building generation. The rural critique series established working rules for inherited roads, locally generated roads, parcel frontage, compact setbacks, outdoor ecology, readable property access, and real road-connected commercial paved frontage. Small-Town Center Candidate 001 extends that contract with reusable inherited planning constraints, infrastructure reservations, semantic town blocks and a denser local-street morphology while preserving Rural Crossroads Candidate 006 exactly.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile, inherited major-road constraints and optional upstream planning constraints, produce a believable semantic local-area plan containing:

- inherited and profile-authorized local roads;
- intersections/control classification;
- optional infrastructure/hydrology reservations derived from upstream global facts;
- optional semantic town blocks;
- road-facing parcels;
- land use;
- legal road/property access;
- System 19 building requests;
- approaches/driveways/property geometry;
- real building-declared paved parking frontage where applicable;
- fields and outdoor/environment dressing.

System 20 may then perform a **one-time transactional initial materialization** of the already-validated plan into WHAT + Door State. After successful materialization, persistent world state owns later reality and System 20 relinquishes ownership.

## 2. Canonical hierarchy

1. **System 00D Global World Planning** owns geography, settlements/districts/rural regions, inherited major-road topology, hydrology and regional infrastructure facts.
2. **System 20 Local Area / Parcel Generation** refines one caller-assigned global area into profile-authorized local roads, reservations, blocks, parcels, access, land use, building placement requests and property/environment dressing.
3. **System 19 Local Building Generation** consumes an already-chosen envelope/orientation/frontage/archetype/instance ID/seed and creates the physical building/property detail.
4. **System 20 Area Materialization** transactionally writes the validated initial area + System 19 subplans into WHAT and initializes doors CLOSED.
5. **WHAT + typed mechanic state** own all later persistent reality.

A System 20 area or block is a **planning domain/fact, not a streaming chunk**.

## 3. Ownership / non-goals

System 20 does **not** own:

- world/continent geography or settlement placement;
- caller-owned major-road topology outside supplied constraints;
- regional rivers/topography or utility network routing;
- building interiors, room programs or furniture;
- households/population/social business state;
- loot, cars, corpses or outbreak damage;
- runtime construction/destruction;
- runtime power/water/wastewater state;
- weather/lighting/perception/sound;
- camera/zoom/renderer/UI;
- streaming/save partition size;
- traffic simulation or traffic-light cycling.

System 20 **may** create profile-authorized minor/local roads entirely inside its assigned area. Such roads may own local parcel frontage. They may not invent a new major road or unauthorized area-boundary continuation.

System 20 may reserve local land around supplied upstream facility/corridor facts, but those reservations are **planning land, not fake final substations/wells/towers/treatment works/pipes**.

System 20 may connect a **real public System 19 building-owned paved frontage** to the road. It may not invent a parking lot merely because a commercial building has empty setback space.

## 4. Area and environment profiles remain separate

### Area / settlement profile

Controls human morphology:

- local-road density/style;
- road classes allowed to own parcel frontage;
- parcel size/distribution;
- land-use weighting;
- vacancy/open-space rate;
- front setbacks;
- density gradient;
- property-access expectations;
- intersection control;
- building-selection/placement policy;
- local connection policy for real building-owned paved frontage;
- optional infrastructure-reservation dimensions/policy;
- optional block morphology.

Current implemented profiles:

- `rural.crossroads` **v5**;
- `smalltown.center` **v1**.

### Environment profile

Controls ecological/surface semantics:

- base ground;
- paved/local-road surface families and physical centerline semantics;
- tree/shrub/rock families;
- spatial ecological density/noise tendencies;
- field surfaces;
- fence/mailbox/civic/environment props.

Current implemented profile: `temperate.rural` **v3**.

## 5. Implemented planning owners

All planning owners live under `game/scripts/generation/areas/`:

- `AreaSeed.gd` — stable named sub-seeds and mixed 2D coordinate hashing;
- `AreaGenerationRequest.gd` — caller constraints, including optional normalized inherited planning constraints;
- `GeneratedAreaPlan.gd` — pure semantic result, including reservations and blocks;
- `AreaProfileCatalog.gd` — settlement morphology/versioning;
- `EnvironmentProfileCatalog.gd` — ecological/surface semantics;
- `InfrastructureReservationPlanner.gd` — deterministic local reservation rectangles/corridors from normalized global planning facts;
- `LocalRoadPlanner.gd` — inherited roads, rural local roads, town local streets and intersections;
- `TownBlockPlanner.gd` — optional semantic `town_block` records carved around roads/reservations;
- `ParcelPlanner.gd` — road-facing parcels and profile-specific land use;
- `ParcelAccessPlanner.gd` — road/property access and final approaches;
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based placement, public-primary-entry alignment, and public road-facing parking-edge discovery;
- `CommercialPavedFrontagePlanner.gd` — extends only real building-owned road-facing parking semantics to the road edge;
- `OutdoorPropertyDressingPlanner.gd` — road surfaces/markings, parking-apron presentation data, fields/mailboxes/fences, natural noise, traffic signal, and reservation avoidance;
- `GeneratedAreaValidator.gd` — generic full-plan correctness including reservations/blocks;
- `LocalAreaGenerator.gd` — coordinator only;
- `AreaMaterializationCoordinator.gd` — separate one-time WHAT/Door State initial-write transaction.

Planning imports no camera, renderer, player or runtime gameplay owner.

## 6. Public contracts

### `AreaGenerationRequest`

Carries:

- area ID, seed, bounds;
- area profile + environment profile;
- inherited major-road records;
- forbidden regions;
- optional `inherited_planning_constraints: Array[Dictionary]`.

Normalized planning constraints use stable source IDs and explicit domain/kind/reservation-role plus point or cardinal segment geometry and blocking policy. Current domains are hydrology, power, potable water and wastewater.

Candidate 006 receives an empty planning-constraint collection so its accepted request/signature remains exact.

### `GeneratedAreaPlan`

Stores/signs the complete pure local result including:

- roads;
- intersections;
- reservations;
- blocks;
- parcels;
- System 19 building requests;
- semantic ground regions;
- outdoor props.

Reservations and blocks are local planning facts only. They do not create runtime utility state or streaming ownership.

## 7. Public pure-plan pipeline

1. validate caller request;
2. resolve area/environment profiles;
3. convert optional inherited planning constraints into deterministic local reservations;
4. install inherited roads exactly;
5. create profile-authorized local roads without unauthorized boundary exits and while respecting road-blocking reservations;
6. derive intersections;
7. derive optional semantic town blocks from legal road/reservation gaps;
8. generate parcel candidates from roads explicitly allowed to own frontage;
9. reject parcels overlapping roads, forbidden area, blocking reservations or other parcels;
10. verify enough local-road capacity exists for the profile target;
11. classify profile-specific land use;
12. assign initial road/parcel access anchors;
13. query System 19 placement descriptors;
14. select/place eligible existing archetypes;
15. generate/validate each System 19 subplan and read its public primary exterior entry;
16. align each occupied property approach along its frontage so the approach axis terminates directly at that real primary entry;
17. read public System 19 ground entries and detect `ground.parking*` only when such cells are actually on the generated building/property footprint's road-facing edge;
18. finalize straight frontage-normal approaches/driveways;
19. extend each detected building-owned parking edge straight to the frontage road using the **same semantic surface**, creating no apron when no such edge exists;
20. create road/parking/field/environment/property dressing while excluding reserved/occupied geometry;
21. validate the complete pure area plan;
22. return semantic plan and deterministic signature.

There is no unbounded reroll loop. If required morphology cannot fit, generation fails rather than silently reverting to a visibly wrong fallback.

## 8. Determinism and version history

Same request + profile/environment versions + System 19 archetype versions produces the same semantic signature.

Named sub-seeds isolate unrelated domains. `AreaSeed.hash_2d(seed, x, y, salt)` mixes both coordinates into one deterministic spatial sample.

Intentional same-seed output-rule changes bump the owning profile version.

Rural Crossroads history:

- Candidate 001: `rural.crossroads@1 + temperate.rural@1`;
- Candidate 002: both profiles v2 for road/environment morphology changes;
- Candidate 003: `rural.crossroads@2 + temperate.rural@3`, ecological noise correction only;
- Candidate 004: `rural.crossroads@3 + temperate.rural@3`, local-road frontage/setback correction;
- Candidate 005: `rural.crossroads@4 + temperate.rural@3`, primary-door/property-approach alignment correction only;
- Candidate 006: `rural.crossroads@5 + temperate.rural@3`, real road-flush building-owned paved frontage correction only.

Small-Town history:

- Candidate 001: `smalltown.center@1 + temperate.rural@3`, infrastructure-aware reservations + town streets/blocks/parcels.

## 9. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement, primary-entry and semantic ground facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

The primary-door alignment rule is generic: System 20 reads `door.exterior.primary` from the public generated plan and aligns the property approach to that door.

The paved-frontage rule is generic: System 20 reads public generated ground entries, recognizes an actual `ground.parking*` frontage edge, and extends that physical semantic to the road. A building without an exposed parking edge receives no invented apron.

## 10. Rural Crossroads Candidate 006 — `rural.crossroads@5 + temperate.rural@3`

`RuralCrossroadsPlanFixture.gd` supplies:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- signalized crossing `(1128,2128)`.

Candidate 006 preserves:

- four roads total: two inherited regional roads + two internal bent 3-cell gravel `local_rural` roads;
- one signalized inherited crossroads + two uncontrolled local-road junctions;
- no unauthorized local-road boundary exits;
- local roads as real parcel-frontage authorities;
- 3 commercial opportunities: gas station + diner + one honest vacancy;
- 6 residential parcels;
- 4 farmsteads;
- at least 6/10 residential+farmstead properties on local roads, including >=3 houses and >=3 farmsteads;
- compact residential/commercial facade setbacks and modest deeper farm setbacks;
- every occupied approach reaching the actual generated primary exterior door on one frontage-normal axis;
- >=60% of non-road area unbuilt;
- deterministic mixed-coordinate ecological noise;
- one real gas-station `ground.parking_faded` frontage extended continuously to the road;
- no fake parking for buildings without a qualifying parking frontage.

Candidate 006 receives no infrastructure reservations or semantic town blocks. Its projected request and generated signature remain a hard regression anchor while other profiles are added.

## 11. Small-Town Center Candidate 001 — `smalltown.center@1 + temperate.rural@3`

Detailed design: `SYSTEM_DESIGNS/20A_SMALLTOWN_CENTER_CANDIDATE_001.md`.

Candidate 001 consumes the actual System 00D v6 `area.smalltown.center.001` facts instead of authoring another standalone fixture truth.

### 11.1 Global -> local constraints

For the small-town profile, `System20AreaRequestProjector.project_site()` normalizes relevant read-only 00D facts into `inherited_planning_constraints`:

- hydrology corridor/bridge provenance where present;
- power feeder corridor + substation facility anchor;
- municipal potable-water trunk + groundwater-source/treatment-storage facility anchors;
- municipal wastewater collection trunk + treatment/disposal facility anchor.

Utility corridors block parcels but permit legitimate local-road crossings. Hydrology corridors block parcels and new local roads. Service/connection nodes that do not need local physical land remain source facts rather than arbitrary facility footprints.

### 11.2 Reservations

`InfrastructureReservationPlanner` creates deterministic legal local reservation rectangles/corridors before local streets/parcels.

Current facility reservation sizes:

- substation 14×12;
- groundwater source 12×12;
- water treatment/storage 16×16;
- wastewater treatment/disposal 20×16.

Facility reservations are adjacent to their inherited-road anchors, remain inside bounds, avoid roads/forbidden/hydrology/other facilities, and block parcels/local roads. They are protected planning land only, not final facility geometry.

### 11.3 Town streets and blocks

The profile creates a connected compact asymmetric internal paved network:

- two perpendicular local cross streets;
- two parallel connector/back streets;
- 3-cell `local_town` width;
- plain paved surface without yellow centerline paint;
- bounded deterministic offsets/jitter;
- no unauthorized boundary exits;
- facility/hydrology avoidance.

`TownBlockPlanner` derives semantic `town_block` rectangles from legal gaps and carves them around blocking reservations rather than discarding otherwise useful town land.

### 11.4 Parcels and land use

Candidate 001 creates:

- four small-commercial opportunities near the main-road center;
- gas station + diner from the current System 19 library;
- at least two honest vacant commercial opportunities because no fake storefront/civic archetypes are invented;
- ten residential opportunities, with a majority using `local_town` frontage;
- deterministic vacant/agricultural/wilderness/open remainder toward edges;
- no farmstead target in the town-center profile.

Inherited-road parcel frontage is limited to the actual inherited segment extent. Regional segments may legitimately terminate inside the 256×256 local site; only actual local-boundary contacts require authorized exits.

All occupied approaches still end directly at the real System 19 primary exterior door, and any real building-owned parking frontage still follows the Candidate 006 road-flush rule.

## 12. Verification

`LocalAreaGenerationSmoke.gd` remains the exact Rural Crossroads Candidate 006 regression.

`SmallTownCenterGenerationSmoke.gd` independently protects Candidate 001, including:

- successful projection from the current System 00D v6 world;
- small-town profile/version;
- connected internal `local_town` network;
- legal blocks/reservations;
- four commercial opportunities with gas station + diner + honest vacancies;
- ten residential opportunities with local-town majority;
- real primary-door access;
- parking semantics;
- reservation exclusion;
- deterministic replay/variation;
- Candidate 006 exactness.

`GlobalWorldPlanningV6Smoke.gd` protects the global -> local seam and keeps `rural.scattered` honestly unsupported until its dedicated profile exists.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.
Exact-head context: `verify/system20-local-area`.

## 13. Initial materialization owner

`AreaMaterializationCoordinator.gd` consumes an already-generated plan and owns only the one-time initial write transaction:

1. validate the area plan;
2. regenerate/validate every System 19 subplan;
3. preflight stable IDs;
4. snapshot WHAT + Door State;
5. apply area terrain/outdoor props;
6. materialize every System 19 building and initialize doors CLOSED;
7. rollback on failure;
8. relinquish generation ownership after success.

Long-term save-file format and streaming-region transactions remain future ownership.

Small-Town Candidate 001 did **not** alter this owner or switch the live System 22 critique runtime. Its reservations remain pure planning facts and are not materialized as fake facility entities.

## 14. Presentation boundary

System 20 owns **no camera or viewer behavior**. The live critique presentation belongs to System 22 and consumes materialized WHAT plus System 21 camera services.

The live Web build remains Rural Crossroads Candidate 006. Implementing a local profile does not automatically make it a presentation target.

## 15. Performance / mobile

Planning/materialization remain bounded startup work, never per-frame systems. Reservation, block, street and parcel operations are bounded by the assigned local planning area and contain no unbounded reroll loop.

System 22 continues to render only its bounded moving window rather than all 65,536 cells every frame.

## 16. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory inherited road facts, unauthorized local-road boundary exits, insufficient parcel/local-road capacity, illegal IDs/overlap, impossible infrastructure reservations, System 19 building rejection, a primary-door alignment that cannot remain inside its legal parcel, or a declared paved frontage that cannot legally reach its frontage road.

Generation never hides invalid geometry with a presentation-only bend or fake content.

## 17. Future extension seams

Future System 20 profiles may add other settlement/rural morphologies while reusing the same request/plan contracts.

Known future consumers/extensions include:

- `rural.scattered` / hamlet local planning;
- sidewalks, alleys and richer parking;
- real storefront/civic System 19 content;
- parcel addresses/zoning/land value;
- exact utility facility placement/materialization inside reserved land;
- local utility distribution to parcels/buildings;
- runtime power/water/wastewater state;
- households/businesses/jobs;
- vehicles/traffic;
- streaming/materialization.

Future systems consume stable reservation/block/parcel facts rather than moving already-planned regional infrastructure.

## 18. Approved decisions / critique history

1. Begin with rural open wilderness/houses/farms and a tiny crossroads center.
2. Keep one memorable traffic light.
3. Settlement morphology and ecological environment remain separate profiles.
4. Keep the 256×256 temperate-rural critique area.
5. Target ten occupied residential/farmstead properties and >=60% non-road land unbuilt for the rural crossroads.
6. System 20 is a global-coordinate planning domain, never a streaming chunk.
7. Use only the existing System 19 library for the first area tests.
8. Candidate 002 fixed wide-road markings, added bent local-road geometry and added natural dressing.
9. Candidate 003 replaced correlated vegetation placement with true mixed-coordinate 2D noise.
10. Candidate 004 made two small local roads real frontage authorities, moved a majority of homes/farms off the inherited highway, tightened purposeless setbacks, and prohibited fake parking inferred from empty setbacks.
11. Candidate 005 aligned every occupied frontage approach directly to the actual generated System 19 primary exterior door without editing the prefab itself.
12. Candidate 006 implemented generic road-flush real parking/forecourt frontage from public System 19 `ground.parking*` semantics and preserved Candidate 005 morphology.
13. On 2026-08-22 the user approved Small-Town Center Candidate 001 after System 00D Slices 001–006 established stable regional infrastructure.
14. Candidate 001 added infrastructure-aware planning constraints/reservations, semantic town blocks, connected paved local streets, denser residential/commercial morphology and honest vacancies while preserving Candidate 006 exactly.
15. Integration clarified that regional roads may terminate inside a local planning window and that inherited parcel frontage must be clipped to actual segment extent.