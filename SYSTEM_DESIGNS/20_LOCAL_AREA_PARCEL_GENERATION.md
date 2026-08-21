# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — CANDIDATE 001 PLANNER + INITIAL MATERIALIZATION**

Date: 2026-08-20

The user approved the rural-first design and explicitly directed development to move on from finalized System 19 using only the existing building library for the first area test. The deterministic pure planner was implemented first. On 2026-08-20 the user then explicitly requested that the generated area be put together into the live critique runtime, authorizing the separately owned initial-materialization slice described below.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile and inherited major-road constraints, produce a believable semantic local-area plan containing roads, intersections, parcels, legal access/driveways, land use, System 19 building requests and outdoor/property dressing.

System 20 may then perform a **one-time transactional initial materialization** of that already-validated plan into WHAT + Door State. After successful materialization, persistent world state owns later reality and System 20 relinquishes ownership.

System 20 bridges broad world planning and System 19 without turning either into a god generator.

## 2. Canonical hierarchy

1. **Future Global World Planning** owns geography, settlements/districts/rural regions, major road topology, major utilities/infrastructure, rivers and other cross-area facts.
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

### Environment profile

Controls initial ecological/surface semantics:

- base ground;
- tree/bush/fence/mailbox families;
- field surfaces;
- natural cluster tendencies;
- civic/environment semantic props.

Current implemented profile: `temperate.rural` v1.

Settlement morphology and ecology remain independently replaceable/combinable.

## 5. Implemented planning owners

All planning owners live under `game/scripts/generation/areas/` and remain pure-data / bounded generation work:

- `AreaSeed.gd` — stable named sub-seeds;
- `AreaGenerationRequest.gd` — caller constraints;
- `GeneratedAreaPlan.gd` — pure semantic result;
- `AreaProfileCatalog.gd` — settlement morphology/versioning;
- `EnvironmentProfileCatalog.gd` — ecological/surface semantics;
- `LocalRoadPlanner.gd` — inherited-road installation/intersections;
- `ParcelPlanner.gd` — road-facing parcels/land use;
- `ParcelAccessPlanner.gd` — parcel access and driveways;
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based selection/placement;
- `OutdoorPropertyDressingPlanner.gd` — fields/mailboxes/fences/trees/traffic signal;
- `GeneratedAreaValidator.gd` — generic full-plan correctness;
- `LocalAreaGenerator.gd` — coordinator only.

The planner imports no camera, renderer, player or WHAT mutation owner.

## 6. Public pure-plan pipeline

1. validate caller request;
2. resolve area/environment profiles;
3. install inherited roads;
4. derive intersections;
5. generate road-facing parcel candidates;
6. classify land use by centrality/profile;
7. assign road/parcel access;
8. query System 19 placement descriptors;
9. select/place eligible existing archetypes;
10. pre-generate and validate each System 19 subplan;
11. finalize driveways to the actual primary building entry;
12. create field/environment/property dressing;
13. validate the complete pure area plan;
14. return semantic plan and deterministic signature.

There is no unbounded reroll loop.

## 7. Determinism and stable identity

Same request + System/profile/environment versions + System 19 archetype versions produces the same semantic signature.

Named sub-seeds isolate domains so adding a later vegetation choice does not reshuffle roads or building assignments merely because a shared RNG consumed another value.

Stable IDs derive from caller area ID plus deterministic roles/geometry. Intentional same-seed output-rule changes require the owning profile/system version to change.

## 8. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement/primary-entry facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

## 9. Candidate 001 — `rural.crossroads + temperate.rural`

`RuralCrossroadsPlanFixture.gd` supplies:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- crossing at `(1128,2128)`;
- exactly one signalized crossroads;
- zero locally generated road spurs.

Target morphology:

- 3 `commercial_small` opportunities nearest center;
- 6 residential parcels;
- 4 farther farmstead parcels;
- remaining generated frontage agricultural/vacant/wilderness;
- materially longer farmstead setbacks/driveways;
- at least 60% of non-road area unbuilt by building envelopes.

Existing building library only:

- one `commercial.gas_station.small`;
- one `commercial.diner.rural_small`;
- one intentionally vacant commercial opportunity;
- residential/farmstead slots drawn from trailer, small farmhouse, large farmhouse and compact-laundry house.

Outdoor semantics include grass base, roads, gravel driveways, fields, one traffic light, rural mailboxes, sparse residential trees and sparse farm fencing. Open land remains legitimate output.

## 10. Candidate pure-plan verification

`LocalAreaGenerationSmoke.gd` protects:

- same-seed determinism and different-seed variation;
- inherited road/boundary integrity;
- exactly one signalized crossroads and zero spurs;
- parcel non-overlap / road exclusion;
- 3 commercial / 6 residential / 4 farmstead targets;
- gas station + diner + honest vacant commercial parcel;
- all four saved residential archetypes in the critique seed;
- density falling outward;
- longer farmstead driveways;
- >=60% unbuilt non-road area;
- traffic signal/mailboxes/fields;
- every building request accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive seeds without retry loops.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.
Exact-head context: `verify/system20-local-area`.

## 11. Initial materialization owner

`game/scripts/generation/areas/AreaMaterializationCoordinator.gd` is now implemented.

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

The coordinator does not import camera/render/UI/player systems. It does not regenerate an already-mutated runtime area.

Long-term save-file format and streaming-region transactions remain future ownership; this implementation establishes the correct initial-world seam without pretending those systems exist.

## 12. Large-area presentation boundary

System 20 still owns **no camera or viewer behavior**.

The implemented live critique presentation belongs to `SYSTEM_DESIGNS/22_LARGE_AREA_CRITIQUE_RUNTIME.md`, which consumes this materialized WHAT and System 21 camera services through public contracts.

The 256×256 planning domain remains unchanged even though the renderer displays only a bounded moving presentation window.

## 13. Performance / mobile

Planning and materialization are bounded startup/generation work, never per-frame systems.

- no full-world generation scan;
- no unbounded retries;
- no frame/input dependency in generation/materialization;
- renderer/mobile behavior remains downstream;
- materialization uses one atomic rollback boundary for the critique area.

## 14. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory road facts, insufficient mandatory parcel candidates, illegal IDs/geometry overlap, or selected mandatory buildings rejected by System 19.

Materialization failures restore the pre-transaction WHAT + Door State snapshots.

Valid outcomes include intentionally vacant parcels, farms without barns, omitted optional vegetation and open wilderness/agricultural land. No fake content is generated to satisfy a count.

## 15. Future extension seams

Future systems may add typed constraints/facts for utilities, rivers/topography, addresses, households/businesses, zoning/land value, secondary farm/commercial buildings, parking/vehicles, sidewalks/civic dressing, world-plan persistence and streaming orchestration.

These extend public request/plan/materialization orchestration rather than reaching into planner internals.

## 16. Approved decisions

1. Begin with rural open wilderness/houses/farms and a tiny crossroads center.
2. Candidate 001 uses a single memorable traffic light.
3. Settlement morphology and ecological environment remain separate profile dimensions.
4. Candidate 001 remains 256×256 and uses `temperate.rural`.
5. Candidate 001 uses zero local road spurs for the first critique.
6. Target occupied residential/farmstead count is 8–12; critique target is 10.
7. At least 60% of non-road land remains unbuilt.
8. System 20 is a global-coordinate planning domain, never a streaming chunk.
9. Candidate 001 uses only the existing System 19 building library.
10. The diner and gas station are the two real commercial buildings; another commercial opportunity stays vacant.
11. Pure planning stays independent from materialization and presentation.
12. On 2026-08-20 the user approved putting the generated plan into the live critique world; initial materialization therefore writes real WHAT rather than drawing a fake preview.
