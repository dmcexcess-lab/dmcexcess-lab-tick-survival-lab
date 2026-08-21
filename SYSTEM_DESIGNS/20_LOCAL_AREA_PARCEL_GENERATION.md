# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 006 + INITIAL MATERIALIZATION**

Date: 2026-08-21

System 20 is the local planning layer between System 00D global world planning and finalized System 19 building generation. The rural critique series has established the working rules for inherited roads, locally generated roads, parcel frontage, compact setbacks, outdoor ecology, readable property access, and real road-connected commercial paved frontage.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile and inherited major-road constraints, produce a believable semantic local-area plan containing:

- inherited and profile-authorized local roads;
- intersections/control classification;
- road-facing parcels;
- land use;
- legal road/property access;
- System 19 building requests;
- approaches/driveways/property geometry;
- real building-declared paved parking frontage where applicable;
- fields and outdoor/environment dressing.

System 20 may then perform a **one-time transactional initial materialization** of the already-validated plan into WHAT + Door State. After successful materialization, persistent world state owns later reality and System 20 relinquishes ownership.

## 2. Canonical hierarchy

1. **System 00D Global World Planning** owns geography, settlements/districts/rural regions, inherited major-road topology and future cross-area infrastructure/hydrology facts.
2. **System 20 Local Area / Parcel Generation** refines one caller-assigned global area into local roads, parcels, access, land use, building placement requests and property/environment dressing.
3. **System 19 Local Building Generation** consumes an already-chosen envelope/orientation/frontage/archetype/instance ID/seed and creates the physical building/property detail.
4. **System 20 Area Materialization** transactionally writes the validated initial area + System 19 subplans into WHAT and initializes doors CLOSED.
5. **WHAT + typed mechanic state** own all later persistent reality.

A System 20 area is a **planning domain, not a streaming chunk**.

## 3. Ownership / non-goals

System 20 does **not** own:

- world/continent geography or settlement placement;
- caller-owned major-road topology outside supplied constraints;
- rivers/topography or major utility networks;
- building interiors, room programs or furniture;
- households/population/social business state;
- loot, cars, corpses or outbreak damage;
- runtime construction/destruction;
- weather/lighting/perception/sound;
- camera/zoom/renderer/UI;
- streaming/save partition size;
- traffic simulation or traffic-light cycling.

System 20 **may** create profile-authorized minor/local roads entirely inside its assigned area. Such roads may own local parcel frontage. They may not invent a new major road or unauthorized area-boundary continuation.

System 20 may also connect a **real public System 19 building-owned paved frontage** to the road. It may not invent a parking lot merely because a commercial building has empty setback space.

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
- local connection policy for real building-owned paved frontage.

Current implemented profile: `rural.crossroads` **v5**.

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
- `AreaGenerationRequest.gd` — caller constraints;
- `GeneratedAreaPlan.gd` — pure semantic result;
- `AreaProfileCatalog.gd` — settlement morphology/versioning;
- `EnvironmentProfileCatalog.gd` — ecological/surface semantics;
- `LocalRoadPlanner.gd` — inherited roads, local roads, intersections;
- `ParcelPlanner.gd` — road-facing parcels and land use;
- `ParcelAccessPlanner.gd` — road/property access and final approaches;
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based placement, public-primary-entry alignment, and public road-facing parking-edge discovery;
- `CommercialPavedFrontagePlanner.gd` — extends only real building-owned road-facing parking semantics to the road edge;
- `OutdoorPropertyDressingPlanner.gd` — road surfaces/markings, parking-apron presentation data, fields/mailboxes/fences, natural noise, traffic signal;
- `GeneratedAreaValidator.gd` — generic full-plan correctness;
- `LocalAreaGenerator.gd` — coordinator only;
- `AreaMaterializationCoordinator.gd` — separate one-time WHAT/Door State initial-write transaction.

Planning imports no camera, renderer, player or runtime gameplay owner.

## 6. Public pure-plan pipeline

1. validate caller request;
2. resolve area/environment profiles;
3. install inherited roads exactly;
4. create profile-authorized local roads without unauthorized boundary exits;
5. derive intersections;
6. generate parcel candidates from roads explicitly allowed to own frontage;
7. reject parcels overlapping roads, forbidden area or other parcels;
8. verify enough local-road capacity exists for the profile target;
9. classify land use;
10. assign initial road/parcel access anchors;
11. query System 19 placement descriptors;
12. select/place eligible existing archetypes;
13. generate/validate each System 19 subplan and read its public primary exterior entry;
14. align each occupied property approach along its frontage so the approach axis terminates directly at that real primary entry;
15. read public System 19 ground entries and detect `ground.parking*` only when such cells are actually on the generated building/property footprint's road-facing edge;
16. finalize straight frontage-normal approaches/driveways;
17. extend each detected building-owned parking edge straight to the frontage road using the **same semantic surface**, creating no apron when no such edge exists;
18. create road/parking/field/environment/property dressing;
19. validate the complete pure area plan;
20. return semantic plan and deterministic signature.

There is no unbounded reroll loop. If required morphology cannot fit, generation fails rather than silently reverting to a visibly wrong fallback.

## 7. Determinism and version history

Same request + profile/environment versions + System 19 archetype versions produces the same semantic signature.

Named sub-seeds isolate unrelated domains. `AreaSeed.hash_2d(seed, x, y, salt)` mixes both coordinates into one deterministic spatial sample.

Intentional same-seed output-rule changes bump the owning profile version.

- Candidate 001: `rural.crossroads@1 + temperate.rural@1`;
- Candidate 002: both profiles v2 for road/environment morphology changes;
- Candidate 003: `rural.crossroads@2 + temperate.rural@3`, ecological noise correction only;
- Candidate 004: `rural.crossroads@3 + temperate.rural@3`, local-road frontage/setback correction;
- Candidate 005: `rural.crossroads@4 + temperate.rural@3`, primary-door/property-approach alignment correction only;
- Candidate 006: `rural.crossroads@5 + temperate.rural@3`, real road-flush building-owned paved frontage correction only.

## 8. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement, primary-entry and semantic ground facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

Candidate 005 is the door-alignment example: System 20 does **not** move a door inside a saved prefab. It reads the generated primary-door cell through the public plan and aligns the property approach to that door.

Candidate 006 is the paved-frontage example: System 20 does **not** special-case the gas-station archetype. It reads public generated ground entries, recognizes an actual `ground.parking*` frontage edge, and extends that physical semantic to the road. A diner, house, or future store without an exposed parking edge receives no invented apron.

## 9. Candidate 006 — `rural.crossroads@5 + temperate.rural@3`

`RuralCrossroadsPlanFixture.gd` continues to supply:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- signalized crossing `(1128,2128)`.

The inherited-road request is also produced by System 00D `temperate.rural.region` v2.

### 9.1 Preserved Candidate 005 morphology

Candidate 006 deliberately preserves the accepted Candidate 005 morphology and door alignment:

- four roads total: two inherited regional roads + two internal bent 3-cell gravel `local_rural` roads;
- one signalized inherited crossroads + two uncontrolled local-road junctions;
- no unauthorized local-road boundary exits;
- local roads are real parcel-frontage authorities;
- 3 commercial opportunities: gas station + diner + one honest vacancy;
- 6 residential parcels;
- 4 farmsteads;
- at least 6/10 residential+farmstead properties on local roads, including >=3 houses and >=3 farmsteads;
- commercial remains near inherited primary-road center;
- residential/commercial average facade setback <=5 cells;
- farmstead average setback > residential and <=8 cells;
- every occupied approach still reaches the actual generated primary exterior door on one frontage-normal axis;
- >=60% of non-road area remains unbuilt;
- Candidate 003 coordinate-noise vegetation remains unchanged.

Candidate 004's rule remains intact: **empty grass is not implicit parking**. Candidate 006 adds parking cells only where a real System 19 generated parking surface already reaches the building/property frontage edge.

### 9.2 Road surfaces / paint

Inherited paved corridors use `ground.road_plain`; only their center paths receive `ground.road_yellow_line_h` / `ground.road_yellow_line_v`. Centerline paint is withheld through immediate intersections. Local roads use `ground.gravel_dark` with no yellow centerline.

### 9.3 Primary-door approach alignment — preserved Candidate 005 rule

The **actual generated primary exterior door** remains the final approach-alignment truth:

1. System 20 places the building using the legal envelope/setback rule;
2. System 19 generates/validates the building normally;
3. System 20 reads `door.exterior.primary` from the public `GeneratedBuildingPlan`;
4. parcel-side and road-side access anchors slide only along the road frontage axis until they align to the door;
5. the final approach runs straight, perpendicular to frontage, from road edge to the real door;
6. an alignment that leaves the legal parcel fails rather than restoring a crooked approach.

No System 19 room, wall, door, fixture or archetype source changes.

### 9.4 Road-flush paved frontage — Candidate 006 correction

The live critique showed the gas station's existing parking/forecourt visually separated from the road by an unpaved strip. The user established the broader morphology rule: **a store with a real parking lot/forecourt should have that paved frontage meet the road directly.**

Candidate 006 implements the general rule rather than a gas-station exception:

1. `BuildingPlacementPlanner` generates the selected System 19 building normally;
2. it reads public `GeneratedBuildingPlan.ground_entries`;
3. it selects semantic entries beginning with `ground.parking` **only if they lie on the actual road-facing edge of the generated footprint**;
4. it records those cells + their exact semantic as `road_flush_paved_frontage` on the local parcel;
5. `CommercialPavedFrontagePlanner` extends each such edge toward the road-access line until the road edge;
6. it emits `parking_cells` and ground regions using the same building-owned semantic;
7. if the building exposes no such frontage edge, it receives no parking apron;
8. the new parking cells are reserved from natural dressing/obstruction like other access geometry.

For the current gas station this means its `ground.parking_faded` forecourt is physically continuous to the road. The diner and residential buildings do not receive fake parking because they expose no qualifying parking frontage.

No System 19 gas-station source, art asset/catalog, renderer, camera, player movement or door mechanic changed.

## 10. Candidate 006 pure-plan verification

`LocalAreaGenerationSmoke.gd` protects:

- same-seed determinism and different-seed variation;
- exact inherited-road/boundary integrity;
- two inherited roads + two internal bent local rural roads;
- one signalized crossroads + two uncontrolled local-road junctions;
- local-road frontage capacity and majority occupancy;
- 3 commercial / 6 residential / 4 farmstead targets;
- gas station + diner + honest vacant commercial opportunity;
- all existing residential building families in the critique seed;
- compact facade setbacks;
- every occupied property's approach starts at its road-access anchor, ends at the real System 19 primary door, and remains on one frontage-normal axis with no sideways hook;
- at least one real parking-apron cell in the current candidate;
- every exposed building-owned parking frontage reaches the road continuously;
- no building without a real road-facing parking edge receives an apron;
- every parking-apron cell has a matching semantic ground region, including `ground.parking_faded` for the gas station;
- >=60% unbuilt non-road area;
- accepted road paint/surface semantics;
- one traffic signal / ten mailboxes / real field zones;
- Candidate 003 two-dimensional tree/shrub/rock noise distribution;
- every building request accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive seeds without reroll loops while preserving the door-alignment and road-flush parking rules plus accepted morphology targets.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.
Exact-head context: `verify/system20-local-area`.

## 11. Initial materialization owner

`AreaMaterializationCoordinator.gd` consumes an already-generated plan and owns only the one-time initial write transaction:

1. validate the area plan;
2. regenerate/validate every System 19 subplan;
3. preflight stable IDs;
4. snapshot WHAT + Door State;
5. apply area terrain/outdoor props, including real parking-apron ground regions;
6. materialize every System 19 building and initialize doors CLOSED;
7. rollback on failure;
8. relinquish generation ownership after success.

Long-term save-file format and streaming-region transactions remain future ownership.

## 12. Presentation boundary

System 20 owns **no camera or viewer behavior**. The live critique presentation belongs to System 22 and consumes materialized WHAT plus System 21 camera services.

Candidate 006 changes only System 20 local property morphology where a generated building actually exposes paved parking frontage. It does not change art assets/catalog, rendering, camera behavior, player movement, door mechanics, inherited/local road rules, environment noise, or System 19 building internals.

## 13. Performance / mobile

Planning/materialization remain bounded startup work, never per-frame systems. Candidate 006 adds a bounded public-ground scan per occupied building and a short straight frontage extension for qualifying parking edges.

System 22 continues to render only its bounded moving window rather than all 65,536 cells every frame.

## 14. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory inherited road facts, unauthorized local-road boundary exits, insufficient parcel/local-road capacity, illegal IDs/overlap, System 19 building rejection, a primary-door alignment that cannot remain inside its legal parcel, or a declared paved frontage that cannot legally reach its frontage road.

Generation never hides invalid geometry with a presentation-only bend or fake content.

## 15. Future extension seams

Future systems may add typed constraints/facts for utilities, rivers/topography, addresses, households/businesses, zoning/land value, secondary buildings, larger/more complex parking lots, vehicles, sidewalks/civic dressing, world-plan persistence and streaming orchestration.

Future Global World Planning may supply richer inherited road geometry. System 20 preserves inherited facts rather than locally bending caller-owned regional roads for aesthetics.

The Candidate 006 paved-frontage seam is intentionally semantic rather than archetype-specific, so future System 19 commercial content can opt into the same local connection behavior simply by exposing a real road-facing `ground.parking*` edge through its normal generated plan.

## 16. Approved decisions / critique history

1. Begin with rural open wilderness/houses/farms and a tiny crossroads center.
2. Keep one memorable traffic light.
3. Settlement morphology and ecological environment remain separate profiles.
4. Keep the 256×256 temperate-rural critique area.
5. Target ten occupied residential/farmstead properties and >=60% non-road land unbuilt.
6. System 20 is a global-coordinate planning domain, never a streaming chunk.
7. Use only the existing System 19 library for the first area tests.
8. Candidate 002 fixed wide-road markings, added bent local-road geometry and added natural dressing.
9. Candidate 003 replaced correlated vegetation placement with true mixed-coordinate 2D noise.
10. Candidate 004 made two small local roads real frontage authorities, moved a majority of homes/farms off the inherited highway, tightened purposeless setbacks, and prohibited fake parking inferred from empty setbacks.
11. On 2026-08-20 the user accepted Candidate 004 roads/farms overall but identified property approaches that did not terminate directly at front doors.
12. Candidate 005 preserves Candidate 004 morphology and aligns every occupied frontage approach directly to the actual generated System 19 primary exterior door without editing the prefab itself.
13. On 2026-08-21 the user identified the gas station's unpaved separation from the road and established the general rule that stores with real parking/forecourt frontage should be flush to the road.
14. Candidate 006 implements that rule generically from public System 19 `ground.parking*` frontage semantics, preserves Candidate 005 morphology, and invents no parking for buildings without a real parking edge.
