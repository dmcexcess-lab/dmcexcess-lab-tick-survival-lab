# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 005 + INITIAL MATERIALIZATION**

Date: 2026-08-20

System 20 is the local planning layer between future global world planning and finalized System 19 building generation. The current rural critique series has established the working rules for inherited roads, locally generated roads, parcel frontage, compact setbacks, outdoor ecology, and readable property access.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile and inherited major-road constraints, produce a believable semantic local-area plan containing:

- inherited and profile-authorized local roads;
- intersections/control classification;
- road-facing parcels;
- land use;
- legal road/property access;
- System 19 building requests;
- approaches/driveways/property geometry;
- fields and outdoor/environment dressing.

System 20 may then perform a **one-time transactional initial materialization** of the already-validated plan into WHAT + Door State. After successful materialization, persistent world state owns later reality and System 20 relinquishes ownership.

## 2. Canonical hierarchy

1. **Future Global World Planning** owns geography, settlements/districts/rural regions, inherited major-road topology, major utilities/infrastructure, rivers and other cross-area facts.
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
- building-selection/placement policy.

Current implemented profile: `rural.crossroads` **v4**.

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
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based placement and public-primary-entry alignment;
- `OutdoorPropertyDressingPlanner.gd` — road surfaces/markings, fields/mailboxes/fences, natural noise, traffic signal;
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
15. finalize straight frontage-normal approaches/driveways;
16. create road/field/environment/property dressing;
17. validate the complete pure area plan;
18. return semantic plan and deterministic signature.

There is no unbounded reroll loop. If required morphology cannot fit, generation fails rather than silently reverting to a visibly wrong fallback.

## 7. Determinism and version history

Same request + profile/environment versions + System 19 archetype versions produces the same semantic signature.

Named sub-seeds isolate unrelated domains. `AreaSeed.hash_2d(seed, x, y, salt)` mixes both coordinates into one deterministic spatial sample.

Intentional same-seed output-rule changes bump the owning profile version.

- Candidate 001: `rural.crossroads@1 + temperate.rural@1`;
- Candidate 002: both profiles v2 for road/environment morphology changes;
- Candidate 003: `rural.crossroads@2 + temperate.rural@3`, ecological noise correction only;
- Candidate 004: `rural.crossroads@3 + temperate.rural@3`, local-road frontage/setback correction;
- Candidate 005: `rural.crossroads@4 + temperate.rural@3`, primary-door/property-approach alignment correction only.

## 8. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement/primary-entry facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

Candidate 005 is an explicit example: System 20 does **not** move a door inside a saved prefab. It reads the generated primary-door cell through the public plan and aligns the property approach to that door.

## 9. Candidate 005 — `rural.crossroads@4 + temperate.rural@3`

`RuralCrossroadsPlanFixture.gd` continues to supply:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- signalized crossing `(1128,2128)`.

### 9.1 Preserved Candidate 004 morphology

Candidate 005 deliberately preserves the user-approved Candidate 004 map morphology:

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
- zero fake parking cells;
- >=60% of non-road area remains unbuilt;
- Candidate 003 coordinate-noise vegetation remains unchanged.

### 9.2 Road surfaces / paint

Inherited paved corridors use `ground.road_plain`; only their center paths receive `ground.road_yellow_line_h` / `ground.road_yellow_line_v`. Centerline paint is withheld through immediate intersections. Local roads use `ground.gravel_dark` with no yellow centerline.

### 9.3 Primary-door approach alignment — Candidate 005 correction

Live Candidate 004 critique found that some visible property approaches reached the building facade and then turned sideways because saved System 19 prefabs may have off-center primary exterior doors.

Candidate 005 makes the **actual generated primary exterior door** the final alignment truth while keeping accepted building envelopes and parcel morphology intact:

1. System 20 places the building using the same legal Candidate 004 envelope/setback rule;
2. System 19 generates/validates the building normally;
3. System 20 reads `door.exterior.primary` from the public `GeneratedBuildingPlan`;
4. the parcel-side and road-side access anchors slide only **along the road frontage axis** until they share the door's X coordinate for north/south frontage or Y coordinate for east/west frontage;
5. the final approach runs straight, perpendicular to the frontage, from road edge to the real door;
6. if the resulting parcel-side anchor leaves the parcel, placement fails instead of restoring a crooked approach.

No System 19 room, wall, door, fixture or archetype source changes. Roads, fields, setbacks, vegetation and building envelopes remain Candidate 004 behavior.

## 10. Candidate 005 pure-plan verification

`LocalAreaGenerationSmoke.gd` protects:

- same-seed determinism and different-seed variation;
- exact inherited-road/boundary integrity;
- two inherited roads + two internal bent local rural roads;
- one signalized crossroads + two uncontrolled local-road junctions;
- local-road frontage capacity and majority occupancy;
- 3 commercial / 6 residential / 4 farmstead targets;
- gas station + diner + honest vacant commercial opportunity;
- all existing residential building families in the critique seed;
- close facade setbacks and zero fake parking;
- **every occupied property's approach starts at its road-access anchor, ends at the real System 19 primary door, and remains on one frontage-normal axis with no sideways hook**;
- >=60% unbuilt non-road area;
- accepted road paint/surface semantics;
- one traffic signal / ten mailboxes / real field zones;
- Candidate 003 two-dimensional tree/shrub/rock noise distribution;
- every building request accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive seeds without reroll loops while preserving the door-alignment rule and all accepted morphology targets.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.
Exact-head context: `verify/system20-local-area`.

## 11. Initial materialization owner

`AreaMaterializationCoordinator.gd` is unchanged. It consumes an already-generated plan and owns only the one-time initial write transaction:

1. validate the area plan;
2. regenerate/validate every System 19 subplan;
3. preflight stable IDs;
4. snapshot WHAT + Door State;
5. apply area terrain/outdoor props;
6. materialize every System 19 building and initialize doors CLOSED;
7. rollback on failure;
8. relinquish generation ownership after success.

Long-term save-file format and streaming-region transactions remain future ownership.

## 12. Presentation boundary

System 20 owns **no camera or viewer behavior**. The live critique presentation belongs to System 22 and consumes materialized WHAT plus System 21 camera services.

Candidate 005 changes only System 20 property-access alignment, profile version, regression tests and durable documentation. It does not change art assets/catalog, rendering, camera behavior, player movement, door mechanics, roads, environment generation, or System 19 building internals.

## 13. Performance / mobile

Planning/materialization remain bounded startup work, never per-frame systems. Candidate 005 adds only one public-entry lookup and constant-time frontage-axis adjustment per occupied building.

System 22 continues to render only its bounded moving window rather than all 65,536 cells every frame.

## 14. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory inherited road facts, unauthorized local-road boundary exits, insufficient parcel/local-road capacity, illegal IDs/overlap, System 19 building rejection, or a primary-door alignment that cannot remain inside its legal parcel.

Generation never hides invalid geometry with a presentation-only bend or fake content.

## 15. Future extension seams

Future systems may add typed constraints/facts for utilities, rivers/topography, addresses, households/businesses, zoning/land value, secondary buildings, real parking lots, vehicles, sidewalks/civic dressing, world-plan persistence and streaming orchestration.

Future Global World Planning may supply richer inherited road geometry. System 20 preserves inherited facts rather than locally bending caller-owned regional roads for aesthetics.

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
10. Candidate 004 made two small local roads real frontage authorities, moved a majority of homes/farms off the inherited highway, tightened purposeless setbacks, and retained zero fake parking.
11. On 2026-08-20 the user accepted Candidate 004 roads/farms overall but identified property approaches that did not terminate directly at front doors.
12. Candidate 005 preserves Candidate 004 morphology and aligns every occupied frontage approach directly to the actual generated System 19 primary exterior door without editing the prefab itself.
