# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 002 + INITIAL MATERIALIZATION**

Date: 2026-08-20

The user approved the rural-first design and explicitly directed development to move on from finalized System 19 using only the existing building library for the first area test. Candidate 001 established deterministic roads/parcels/building placement and later real WHAT materialization. During live critique, the user then identified three concrete quality failures: multi-cell paved roads rendered as repeated yellow boxes, the local road network was too geometrically straight, and the large open rural spaces lacked enough trees/shrubs/rocks. Candidate 002 hardens those same approved System 20 responsibilities without reopening System 19, System 21, or renderer ownership.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile and inherited major-road constraints, produce a believable semantic local-area plan containing roads, intersections, parcels, legal access/driveways, land use, System 19 building requests and outdoor/property dressing.

System 20 may then perform a **one-time transactional initial materialization** of that already-validated plan into WHAT + Door State. After successful materialization, persistent world state owns later reality and System 20 relinquishes ownership.

System 20 bridges broad world planning and System 19 without turning either into a god generator.

## 2. Canonical hierarchy

1. **Future Global World Planning** owns geography, settlements/districts/rural regions, inherited major-road topology, major utilities/infrastructure, rivers and other cross-area facts.
2. **System 20 Local Area / Parcel Generation** refines one caller-assigned global area into local roads, parcels, access, land use, building placement requests and property/environment dressing.
3. **System 19 Local Building Generation** consumes an already-chosen building envelope/orientation/frontage/archetype/instance ID/seed and creates the physical building/property detail.
4. **System 20 Area Materialization** transactionally writes the validated initial area + System 19 subplans into WHAT and initializes doors CLOSED.
5. **WHAT + typed mechanic state** own all later persistent reality.

A System 20 area is a **planning domain, not a streaming chunk**. Storage/render/streaming windows may differ without redefining logical geography.

## 3. Non-goals

System 20 does not own:

- world/continent geography or settlement placement;
- major road topology outside caller constraints;
- rivers/topography or major utility networks;
- building interiors, room programs or furniture;
- households/population/social business state;
- loot, cars, corpses or outbreak damage;
- runtime construction/destruction;
- weather/lighting/perception/sound;
- camera/zoom/renderer/UI;
- streaming/save partition size;
- traffic simulation or traffic-light cycling.

A static traffic-light object is initial civic dressing only.

## 4. Area profile and environment profile remain separate

### Area / settlement profile

Controls human morphology:

- inherited/local-road density and style;
- parcel size/distribution;
- land-use weighting;
- vacancy/open-space rate;
- setbacks;
- density gradient;
- driveway expectations;
- intersection control;
- building-selection policy.

Current implemented profile: `rural.crossroads` **v2**.

### Environment profile

Controls initial ecological/surface semantics:

- base ground;
- paved/local-road surface families and physical centerline semantics;
- tree/shrub/rock families;
- natural cluster tendencies;
- field surfaces;
- fence/mailbox/civic/environment semantic props.

Current implemented profile: `temperate.rural` **v2**.

Settlement morphology and ecology remain independently replaceable/combinable.

## 5. Implemented planning owners

All planning owners live under `game/scripts/generation/areas/` and remain pure-data / bounded generation work:

- `AreaSeed.gd` — stable named sub-seeds;
- `AreaGenerationRequest.gd` — caller constraints;
- `GeneratedAreaPlan.gd` — pure semantic result;
- `AreaProfileCatalog.gd` — settlement morphology/versioning;
- `EnvironmentProfileCatalog.gd` — ecological/surface semantics;
- `LocalRoadPlanner.gd` — inherited-road installation, local road branches, intersections;
- `ParcelPlanner.gd` — road-facing parcels/land use and road-overlap rejection;
- `ParcelAccessPlanner.gd` — parcel access and driveways;
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based selection/placement;
- `OutdoorPropertyDressingPlanner.gd` — road surfaces/markings, fields/mailboxes/fences, natural clusters, traffic signal;
- `GeneratedAreaValidator.gd` — generic full-plan correctness;
- `LocalAreaGenerator.gd` — coordinator only.

The planner imports no camera, renderer, player or WHAT mutation owner.

## 6. Public pure-plan pipeline

1. validate caller request;
2. resolve area/environment profiles;
3. install inherited roads exactly;
4. create profile-authorized local roads that do not invent boundary exits;
5. derive intersections;
6. generate road-facing parcel candidates only from roads explicitly allowed to own frontage;
7. reject any parcel candidate overlapping any road corridor;
8. classify land use by centrality/profile;
9. assign road/parcel access;
10. query System 19 placement descriptors;
11. select/place eligible existing archetypes;
12. pre-generate and validate each System 19 subplan;
13. finalize driveways to the actual primary building entry;
14. create road/field/environment/property dressing;
15. validate the complete pure area plan;
16. return semantic plan and deterministic signature.

There is no unbounded reroll loop.

## 7. Determinism and stable identity

Same request + System/profile/environment versions + System 19 archetype versions produces the same semantic signature.

Named sub-seeds isolate domains so vegetation variation does not reshuffle building assignments merely because a shared RNG consumed another value.

Stable IDs derive from caller area ID plus deterministic roles/geometry. Intentional same-seed output-rule changes require the owning profile/system version to change.

Candidate 002 therefore bumps both `rural.crossroads` and `temperate.rural` from v1 to v2.

## 8. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement/primary-entry facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

## 9. Candidate 002 — `rural.crossroads@2 + temperate.rural@2`

`RuralCrossroadsPlanFixture.gd` still supplies:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- crossing at `(1128,2128)`.

Those inherited roads remain exact caller constraints and retain their authorized boundary exits.

### Road morphology

Candidate 002 adds exactly one deterministic **local farm-access branch**:

- 3 cells wide;
- internal only; no area-boundary exit;
- branches from the inherited primary road at an ordinary uncontrolled junction;
- contains multiple cardinal bends rather than another straight line;
- uses gravel/unpainted rural-road surface semantics;
- currently does **not** claim parcel-frontage authority, so it can add believable rural road shape without silently redesigning parcel allocation.

The memorable inherited-road crossroads remains the only signalized intersection.

### Paved-road surface/marking rule

The earlier generic-road approach was correct for one-cell topology roads but wrong for a 3–5-cell-wide carriageway: every interior cell saw neighbors in all directions, so the Ground Renderer legitimately selected intersection-like road art repeatedly and the road looked like yellow boxes.

Candidate 002 fixes the semantic input rather than changing System 05:

- the full paved corridor is `ground.road_plain`;
- only the center path receives `ground.road_yellow_line_h` or `ground.road_yellow_line_v`;
- centerline paint is withheld through the immediate intersection footprint so crossings read as crossings rather than overlapping painted boxes;
- the local farm-access branch uses `ground.gravel_dark` with no yellow centerline.

These are semantic physical surfaces/paint facts, not atlas indices or renderer instructions. System 05 continues to render explicit ground semantics literally through the Art Catalog.

### Parcel/building target

Candidate 002 deliberately preserves the accepted Candidate 001 density/content target:

- 3 `commercial_small` opportunities nearest center;
- 6 residential parcels;
- 4 farther farmstead parcels;
- remaining generated frontage agricultural/vacant/wilderness;
- materially longer farmstead setbacks/driveways;
- at least 60% of non-road area unbuilt by building envelopes;
- one gas station;
- one diner;
- one intentionally vacant commercial opportunity;
- ten residential/farmstead placements using only Trailer / Small Farmhouse / Large Farmhouse / Compact Laundry House profiles.

The new farm-access road is not allowed to erase these counts. Parcel candidates overlapping it are rejected before classification; remaining inherited-road frontage supplies the same 12 buildings.

### Natural rural dressing

`temperate.rural` v2 adds deterministic clustered natural dressing rather than uniform scatter:

- deciduous large/small trees;
- dense/thorn shrubs;
- small/cluster/mossy rocks;
- multiple seeded cluster families (groves, brush-heavy clusters, rocky scrub);
- bounded cluster count/radius/size;
- a clear radius around the signalized town center;
- clearance around roads and driveways;
- no placement inside building envelopes or active field rectangles;
- occupied residential/commercial/farmstead parcel interiors remain deliberately controlled;
- wilderness/vacant parcels and otherwise unclaimed open rural land are valid natural-cluster space.

Open land remains open at the planning level, but it no longer means visually empty grass.

## 10. Candidate 002 pure-plan verification

`LocalAreaGenerationSmoke.gd` protects:

- same-seed determinism and different-seed variation;
- exact inherited-road/boundary integrity;
- two inherited roads + one local farm-access branch;
- one signalized crossroads + one uncontrolled branch junction;
- local branch has real bends and no boundary exit;
- parcel non-overlap / all-road exclusion;
- 3 commercial / 6 residential / 4 farmstead targets;
- gas station + diner + honest vacant commercial parcel;
- all four saved residential archetypes in the critique seed;
- density falling outward;
- longer farmstead driveways;
- >=60% unbuilt non-road area;
- plain paved corridor + single horizontal/vertical yellow centerline layers + gravel local branch;
- no generic multi-cell `ground.road` region in Candidate 002;
- one traffic signal / ten mailboxes / real field zones;
- substantial tree/shrub/rock dressing, clustered rather than uniform, and excluded from active fields;
- every building request accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive seeds without retry loops while preserving building, road and natural-dressing targets.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.
Exact-head context: `verify/system20-local-area`.

## 11. Initial materialization owner

`game/scripts/generation/areas/AreaMaterializationCoordinator.gd` is unchanged.

It is **not part of pure generation**. It consumes an already-generated plan and owns only the one-time initial write transaction.

Contract:

1. validate the `GeneratedAreaPlan` against its `AreaGenerationRequest`;
2. regenerate every System 19 subplan from the plan's public `BuildingGenerationRequest`s;
3. validate every subplan before writing;
4. preflight stable entity IDs;
5. snapshot WHAT + Door State;
6. apply area ground regions in priority order;
7. materialize outdoor semantic props;
8. call `GeneratedBuildingMaterializer` for every System 19 subplan so building surfaces/structures/props are written through the existing contract and doors initialize CLOSED;
9. rollback WHAT + Door State on any failed write;
10. return success and relinquish generation ownership.

Long-term save-file format and streaming-region transactions remain future ownership.

## 12. Presentation boundary

System 20 still owns **no camera or viewer behavior**.

The live critique presentation belongs to `SYSTEM_DESIGNS/22_LARGE_AREA_CRITIQUE_RUNTIME.md`, which consumes materialized WHAT and System 21 camera services through public contracts.

Candidate 002 intentionally changes only semantic area output. No art assets, camera zoom values, renderer topology contract, player movement or door behavior are changed.

## 13. Performance / mobile

Planning and materialization are bounded startup/generation work, never per-frame systems.

Natural dressing uses a fixed number of deterministic cluster/placement attempts rather than a full per-frame/world scan or unbounded reroll loop. Rendering still draws only the bounded System 22 window.

## 14. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory road facts, insufficient mandatory parcel candidates, illegal IDs/geometry overlap, or selected mandatory buildings rejected by System 19.

Local roads may not create unauthorized boundary exits. Materialization failures restore the pre-transaction WHAT + Door State snapshots.

Valid outcomes include intentionally vacant parcels, farms without barns, omitted individual optional vegetation placements and substantial open land. No fake content is generated to satisfy a visual count.

## 15. Future extension seams

Future systems may add typed constraints/facts for utilities, rivers/topography, addresses, households/businesses, zoning/land value, secondary farm/commercial buildings, parking/vehicles, sidewalks/civic dressing, world-plan persistence and streaming orchestration.

Future Global World Planning may also supply richer inherited road geometry. System 20 continues to preserve inherited facts rather than locally bending a caller-owned regional road merely for aesthetics.

## 16. Approved decisions / critique history

1. Begin with rural open wilderness/houses/farms and a tiny crossroads center.
2. Keep a single memorable traffic light.
3. Settlement morphology and ecological environment remain separate profile dimensions.
4. Keep the 256×256 temperate-rural critique area.
5. Candidate 001 intentionally started with zero local road spurs to isolate inherited-road/parcel behavior.
6. Target occupied residential/farmstead count is 8–12; critique target remains 10.
7. At least 60% of non-road land remains unbuilt.
8. System 20 is a global-coordinate planning domain, never a streaming chunk.
9. The area test uses only the existing System 19 building library.
10. Pure planning stays independent from materialization and presentation.
11. On 2026-08-20 the user approved putting the generated plan into the live critique world; initial materialization writes real WHAT rather than a fake preview.
12. On 2026-08-20 live critique identified the yellow-box road markings, over-straight road network and under-dressed wilderness. Candidate 002 therefore adds semantic carriageway/centerline separation, one bent local farm-access branch, and clustered trees/shrubs/rocks while preserving the accepted building/parcel baseline.
