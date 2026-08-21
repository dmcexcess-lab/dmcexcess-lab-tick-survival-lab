# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — CANDIDATE 001 PURE-PLAN SLICE**

Date: 2026-08-20

The user approved the rural-first design choices in conversation and on 2026-08-20 explicitly directed development to move on from finalized System 19 and test the next phase using only the building/prefab library already available.

System 20 Candidate 001 therefore implements the **pure deterministic planning layer first**. Large-area camera/viewer presentation and initial WHAT materialization remain separate later slices; neither is hidden inside the planner.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile and inherited major-road constraints, produce a believable semantic local-area plan containing roads, intersections, parcels, legal access/driveways, land use, System 19 building requests and outdoor/property dressing.

System 20 bridges broad world planning and System 19 without turning either into a god generator.

## 2. Canonical hierarchy

1. **Future Global World Planning** owns geography, settlements/districts/rural regions, major road topology, major utilities/infrastructure, rivers and other facts that must remain coherent across local areas.
2. **System 20 Local Area / Parcel Generation** refines one caller-assigned global area into local roads, parcels, access, land use, building placement requests and property/environment dressing.
3. **System 19 Local Building Generation** consumes an already-chosen building envelope/orientation/frontage/archetype/instance ID/seed and creates the physical building/property detail.
4. **WHAT + typed mechanic state** own later persistent reality after materialization.

A System 20 area is a **planning domain, not a streaming chunk**. Future storage/streaming boundaries must not redefine logical geography.

## 3. Non-goals

System 20 does not own:

- world/continent geography;
- town placement or regional settlement selection;
- major road topology outside the request;
- rivers/topography;
- major utility networks;
- building interiors, room programs or furniture;
- households/population/social businesses;
- loot, cars, corpses or outbreak damage;
- runtime construction/destruction;
- weather/lighting/perception/sound;
- camera/zoom/renderer/UI;
- streaming/save partition size;
- traffic simulation or traffic-light cycling.

A static traffic-light object is initial civic dressing only.

## 4. Area profile and environment profile are separate

### Area / settlement profile
Controls human morphology:

- local-road density/style;
- parcel size/distribution;
- land-use weighting;
- vacancy/open-space rate;
- setbacks;
- density gradient;
- driveway expectations;
- intersection control;
- building-selection policy.

Current implemented profile: `rural.crossroads` v1.

Future examples may include `rural.scattered`, `suburban.low_density`, `smalltown.center`, `urban.grid` and `industrial.edge` without changing the environment contract.

### Environment profile
Controls initial ecological/surface semantics:

- base ground;
- tree/bush/fence/mailbox families;
- field surfaces;
- natural cluster tendencies;
- civic/environment semantic props.

Current implemented profile: `temperate.rural` v1.

Settlement morphology and ecology remain independently replaceable/combinable.

## 5. Implemented owners

### `AreaSeed.gd`
Produces stable named sub-seeds so changes to one generation stage do not reshuffle unrelated stages.

### `AreaGenerationRequest.gd`
Pure caller constraints:

- stable `area_id`;
- seed;
- global `Rect2i bounds`;
- area profile ID;
- environment profile ID;
- inherited major-road constraints;
- optional forbidden regions.

Inherited roads carry stable ID/class, axis-aligned start/end, odd width and explicit authorized boundary continuation cells.

### `GeneratedAreaPlan.gd`
Pure semantic result containing:

- provenance/version facts;
- roads/intersections;
- parcels and land use;
- access/driveway facts;
- System 19 `BuildingGenerationRequest`s;
- ground regions;
- outdoor semantic props;
- deterministic signature.

No Nodes, textures, atlas coordinates, camera values or runtime actors are stored.

### `AreaProfileCatalog.gd`
Owns settlement morphology/versioned selection policy.

### `EnvironmentProfileCatalog.gd`
Owns ecological/surface semantic families independently from settlement policy.

### `LocalRoadPlanner.gd`
Installs inherited roads exactly and derives intersections. Candidate 001 intentionally generates zero local road spurs. It may not invent unauthorized cross-boundary exits.

### `ParcelPlanner.gd`
Creates non-overlapping road-facing parcels outside an intersection exclusion zone, varies frontage deterministically, and classifies them by centrality into commercial, residential, farmstead and open-land uses.

### `ParcelAccessPlanner.gd`
Chooses parcel/road access cells and, after building placement, creates deterministic driveways from the actual road edge to the generated System 19 primary entry.

### `BuildingPlacementPlanner.gd`
Consumes only System 19 public placement descriptors and public generation/validation contracts. It selects eligible existing archetypes, rotates them to face their frontage road, places them inside parcel buildable regions and obtains the actual primary exterior-door cell from the resulting public building plan.

### `OutdoorPropertyDressingPlanner.gd`
Produces semantic initial outdoor facts: base grass, road/driveway/field ground regions, one traffic signal, rural mailboxes, sparse residential trees and farm-boundary fence dressing. Roads/driveways/buildings always take priority over decoration.

### `GeneratedAreaValidator.gd`
Owns generic area-plan correctness:

- bounds;
- authorized inherited-road exits;
- intersection references;
- parcel overlap/road exclusion;
- frontage/access/driveway validity;
- building fit;
- System 19 generation/validation acceptance;
- unique stable IDs;
- outdoor prop road/driveway/building exclusion;
- ground-region containment.

Profile-specific visual-density targets stay in focused Candidate tests.

### `LocalAreaGenerator.gd`
Coordinator only. Orchestrates the focused owners and returns a validated pure plan. It contains no rendering, camera, player, WHAT mutation or gameplay logic.

## 6. Public pipeline

Current Candidate 001 pipeline:

1. validate caller request;
2. resolve area/environment profiles;
3. install inherited roads;
4. derive intersections;
5. generate road-facing parcel candidates outside the crossroads exclusion zone;
6. classify land use by centrality;
7. assign road/parcel access;
8. query System 19 placement descriptors;
9. select/place only existing eligible building archetypes;
10. pre-generate and validate each System 19 subplan;
11. finalize driveways to the actual primary building entry;
12. create field/environment/property dressing;
13. validate the complete pure area plan;
14. return semantic plan and deterministic signature.

There is no unbounded reroll loop.

## 7. Determinism and stable identity

Same request + System 20/profile/environment versions + System 19 archetype versions must produce the same semantic signature.

Named sub-seeds isolate domains such as parcel widths and building selection. Adding a later vegetation choice must not silently change the major roads or building assignments merely because one shared RNG consumed another value.

Stable IDs derive from the caller area ID plus deterministic roles/geometry, e.g. area/road/intersection/parcel/building/property roles.

Intentional same-seed output-rule changes require the owning profile/system version to change.

## 8. System 19 boundary

System 20 may use only:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement/primary-entry facts.

It may not inspect individual building-generator/profile internals or duplicate their canonical size/frontage truth.

System 19 remains the building/interior owner.

## 9. Candidate 001 — `rural.crossroads + temperate.rural`

### Request fixture

`RuralCrossroadsPlanFixture.gd` supplies:

- global bounds `Rect2i(1000,2000,256,256)`;
- critique seed `20001`;
- one inherited 5-cell-wide primary east/west road;
- one inherited 3-cell-wide secondary north/south road;
- crossing at global `(1128,2128)`;
- only those inherited endpoints are authorized boundary continuations.

### Target morphology

Mostly open rural land with sparse residences/farms and a tiny crossroads center.

Candidate 001 deliberately has:

- exactly **one signalized crossroads**;
- **zero generated local road spurs**;
- **3 commercial-small parcel opportunities** nearest the crossroads;
- **6 residential parcels** next outward;
- **4 farmstead parcels** farther outward;
- remaining generated frontage parcels classified agricultural/vacant/wilderness;
- materially longer farmstead setbacks/driveways;
- at least 60% of non-road area unbuilt by building envelopes.

### Existing building library only

No new System 19 profiles are created for this test.

Commercial:

- one `commercial.gas_station.small`;
- one accepted `commercial.diner.rural_small`;
- one additional commercial parcel remains intentionally vacant.

Residential/farmstead planning exercises the existing:

- `residential.trailer.singlewide`;
- `residential.house.farm_small`;
- `residential.house.farm_large`;
- `residential.house.compact_laundry`.

The six residential slots cycle across all four saved residential archetypes. Farmsteads use the existing farmhouse archetypes. This makes Candidate 001 a test of **area planning**, not a disguised content-generation task.

### Outdoor semantics

Candidate 001 includes:

- `ground.grass_lush` base;
- inherited road ground;
- gravel driveways;
- field-green farm/agricultural regions;
- exactly one `prop.traffic_light` near the central intersection;
- one curb mailbox per occupied residential/farmstead property;
- sparse residential trees;
- sparse farm rear-boundary fencing.

Open land is intentionally left open.

## 10. Candidate-specific acceptance contract

`LocalAreaGenerationSmoke.gd` verifies:

1. the 256×256 global request is valid;
2. same-seed replay has identical signature;
3. a different seed changes legal parcel/building planning;
4. exactly two inherited roads and one signalized crossroads exist;
5. no local road spur is invented;
6. exactly three commercial opportunities, six residential parcels and four farmsteads are produced;
7. exactly twelve existing-library building requests are emitted: two commercial + ten residential/farmstead;
8. gas station and diner each appear once and one commercial opportunity remains vacant;
9. all four residential saved archetypes appear in the critique seed;
10. commercial average distance < residential average distance < farmstead average distance;
11. farmstead average driveway is longer than residential average driveway;
12. at least 60% of non-road area remains unbuilt;
13. exactly one traffic-light prop and ten rural mailboxes are emitted;
14. farm/agricultural field regions exist;
15. every building request is accepted by System 19 generation + validation;
16. every System 20 ground/prop semantic resolves through the recovered art catalog;
17. twelve consecutive area seeds generate successfully without retry loops while preserving the structural targets.

Generic validation separately protects boundary exits, overlaps, access, stable IDs and containment.

## 11. Materialization / persistence status

**Not implemented in Candidate 001.**

This slice intentionally stops at a complete validated pure plan. It does not paint a 256×256 world into WHAT yet.

A later `AreaMaterializationCoordinator` must preflight the complete plan and all System 19 subplans, then use public WHAT/Door State contracts with safe rollback/transaction behavior. After successful initial materialization, generation relinquishes ownership permanently.

No runtime regeneration of already-mutated persistent areas is allowed.

## 12. Visualization status

**Not owned by System 20.**

The 256×256 area is deliberately larger than the current one-screen critique fixture. A proper large-area critique view/camera must be implemented as a separately owned presentation slice after the pure planner is green.

Do not shrink the logical planning area or add camera/render code to System 20 merely to make this test visible.

## 13. Performance / mobile

System 20 runs only as bounded generation work, never per frame.

- no full-world scan;
- no unbounded retries;
- no frame-time/input dependency;
- parcel/road checks are bounded to one requested area;
- renderer/mobile/Safari behavior is unaffected by this pure-plan slice.

## 14. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory road facts, insufficient mandatory parcel candidates, illegal stable-ID/geometry overlap, or a selected mandatory building that System 19 rejects.

Valid outcomes include intentionally vacant parcels, open farms without barns, omitted optional vegetation and open wilderness/agricultural land.

No fake content is generated to satisfy a count.

## 15. Future extension seams

Future higher-level systems may add typed constraints/facts for:

- utility corridors;
- rivers/topography/exclusions;
- addresses;
- household/business assignment;
- zoning/land value;
- secondary farm/commercial buildings;
- parking/vehicle spawn facts;
- sidewalks/civic dressing;
- world-plan persistence;
- materialization/streaming orchestration.

Those extend the request/plan contracts rather than reaching into System 20 internals.

## 16. Approved decisions

1. Begin with rural open wilderness/houses/farms and a tiny crossroads center.
2. Candidate 001 uses a single memorable traffic light.
3. Settlement morphology and ecological environment remain separate profile dimensions.
4. Candidate 001 remains 256×256 and uses `temperate.rural`.
5. Candidate 001 uses zero local road spurs so inherited-road/parcel behavior can be judged first.
6. Target occupied residential/farmstead count is 8–12; implemented critique target is 10.
7. At least 60% of non-road land remains unbuilt.
8. System 20 is a global-coordinate planning domain, never a streaming chunk.
9. First implementation is pure-plan/headless before any large-area viewer.
10. Candidate 001 uses only the existing System 19 building library; new building profiles are deferred until after this area test.
11. The accepted diner is now a legitimate second commercial building; another commercial opportunity remains vacant rather than creating a fake store.
