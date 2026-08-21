# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 003 + INITIAL MATERIALIZATION**

Date: 2026-08-20

The user approved the rural-first design and explicitly directed development to move on from finalized System 19 using only the existing building library for the first area test. Candidate 001 established deterministic roads/parcels/building placement and later real WHAT materialization. Candidate 002 fixed the live yellow-box road presentation input, added one bent local farm-access road, and added trees/shrubs/rocks. During the next live critique the user identified that the natural props themselves were spatially correlated into a diagonal line. Candidate 003 corrects only that ecological-placement rule while preserving the accepted Candidate 002 road, parcel and building morphology.

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
- spatial ecological density/noise tendencies;
- field surfaces;
- fence/mailbox/civic/environment semantic props.

Current implemented profile: `temperate.rural` **v3**.

Settlement morphology and ecology remain independently replaceable/combinable.

## 5. Implemented planning owners

All planning owners live under `game/scripts/generation/areas/` and remain pure-data / bounded generation work:

- `AreaSeed.gd` — stable named sub-seeds plus deterministic mixed 2D coordinate hashing for spatial-noise consumers;
- `AreaGenerationRequest.gd` — caller constraints;
- `GeneratedAreaPlan.gd` — pure semantic result;
- `AreaProfileCatalog.gd` — settlement morphology/versioning;
- `EnvironmentProfileCatalog.gd` — ecological/surface semantics;
- `LocalRoadPlanner.gd` — inherited-road installation, local road branches, intersections;
- `ParcelPlanner.gd` — road-facing parcels/land use and road-overlap rejection;
- `ParcelAccessPlanner.gd` — parcel access and driveways;
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based selection/placement;
- `OutdoorPropertyDressingPlanner.gd` — road surfaces/markings, fields/mailboxes/fences, natural noise dressing, traffic signal;
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

Named sub-seeds isolate unrelated domains so vegetation changes do not reshuffle roads or building assignments merely because a shared RNG consumed another value.

For spatial ecology, `AreaSeed.hash_2d(seed, x, y, salt)` mixes both coordinates into one deterministic value. X and Y are never generated from sibling linear seed streams. `unit_2d()` exposes the same mixed value as a stable 0–1 sample.

Stable IDs derive from caller area ID plus deterministic generation order/roles. Intentional same-seed output-rule changes require the owning profile/system version to change.

Candidate 002 bumped `rural.crossroads` and `temperate.rural` from v1 to v2. Candidate 003 keeps `rural.crossroads` v2 because human morphology is unchanged and bumps only `temperate.rural` **v2 -> v3** because ecological placement intentionally changes.

## 8. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement/primary-entry facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

## 9. Candidate 003 — `rural.crossroads@2 + temperate.rural@3`

`RuralCrossroadsPlanFixture.gd` still supplies:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- crossing at `(1128,2128)`.

Those inherited roads remain exact caller constraints and retain their authorized boundary exits.

### Road morphology — unchanged from Candidate 002

Candidate 003 preserves exactly one deterministic local **farm-access branch**:

- 3 cells wide;
- internal only; no area-boundary exit;
- branches from the inherited primary road at an ordinary uncontrolled junction;
- contains multiple cardinal bends rather than another straight line;
- uses gravel/unpainted rural-road surface semantics;
- currently does **not** claim parcel-frontage authority.

The memorable inherited-road crossroads remains the only signalized intersection.

### Paved-road surface/marking rule — unchanged from Candidate 002

The full paved corridor is `ground.road_plain`; only the center path receives `ground.road_yellow_line_h` or `ground.road_yellow_line_v`. Centerline paint is withheld through the immediate intersection footprint. The local farm-access branch uses `ground.gravel_dark` with no yellow centerline.

These are semantic physical surfaces/paint facts, not atlas indices or renderer instructions. System 05 remains unchanged.

### Parcel/building target — unchanged from Candidate 002

Candidate 003 preserves:

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

The farm-access road is still not allowed to erase these counts.

### Natural rural dressing — Candidate 003 correction

The Candidate 002 cluster algorithm selected a finite list of cluster centers by deriving X and Y separately from closely related string-domain seed streams. The output was deterministic but the two coordinate streams were visibly correlated, producing a diagonal chain across the map.

Candidate 003 removes random cluster centers entirely.

Natural placement now uses **two-scale deterministic 2D noise**:

1. every eligible cell is evaluated with a low-frequency smooth value-noise field;
2. that field modulates local natural-prop density, creating broad dense and sparse patches;
3. an independent mixed per-cell coordinate sample decides whether an individual cell receives a prop;
4. a second lower-frequency noise field biases local ecology toward tree-heavy, shrub-heavy or rocky pockets;
5. a final independent coordinate hash selects the exact semantic variant.

The value-noise field interpolates four independently mixed coarse-grid coordinate samples, so density changes smoothly through space without a preferred diagonal, row or column.

Eligible natural space remains constrained exactly as before:

- clear radius around the signalized town center;
- clearance around all road corridors and driveways;
- no building-envelope overlap;
- no active-field overlap;
- occupied residential/commercial/farmstead parcel interiors remain controlled;
- wilderness/vacant parcels and otherwise unclaimed open rural land are valid natural space.

Trees, shrubs and rocks therefore appear as irregular noise-like countryside with local groves/brush/rocky pockets and genuine empty gaps, rather than as a line of authored-looking clusters.

## 10. Candidate 003 pure-plan verification

`LocalAreaGenerationSmoke.gd` protects:

- same-seed determinism and different-seed variation;
- exact inherited-road/boundary integrity;
- two inherited roads + one bent local farm-access branch;
- one signalized crossroads + one uncontrolled branch junction;
- local branch has no boundary exit or parcel-frontage authority;
- parcel non-overlap / all-road exclusion;
- 3 commercial / 6 residential / 4 farmstead targets;
- gas station + diner + honest vacant commercial parcel;
- all four saved residential archetypes in the critique seed;
- density falling outward;
- longer farmstead driveways;
- >=60% unbuilt non-road area;
- plain paved corridor + single horizontal/vertical yellow centerline layers + gravel local branch;
- no generic multi-cell `ground.road` region;
- one traffic signal / ten mailboxes / real field zones;
- substantial tree/shrub/rock dressing and active-field exclusion;
- natural-prop local-neighbor ratio bounded away from both total isolation and one dense chain;
- broad 4x4 coarse-map coverage;
- low absolute X/Y correlation, explicitly preventing the reported diagonal-collapse failure;
- every building request accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive seeds without retry loops while preserving building, road and natural-noise distribution targets.

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

System 20 owns **no camera or viewer behavior**.

The live critique presentation belongs to `SYSTEM_DESIGNS/22_LARGE_AREA_CRITIQUE_RUNTIME.md`, which consumes materialized WHAT and System 21 camera services through public contracts.

Candidate 003 changes only semantic environment output and its deterministic seed helper. No art assets, camera zoom values, renderer contract, player movement, door behavior, road morphology, parcel allocation or System 19 building content changes.

## 13. Performance / mobile

Planning and materialization are bounded startup/generation work, never per-frame systems.

Candidate 003 scans the bounded local-area cells once during environment generation. For the current 256×256 critique area that is 65,536 deterministic eligibility/noise evaluations at startup, with no retries and no frame polling. Rendering still draws only the bounded System 22 window.

If future planning domains become dramatically larger, natural dressing may be spatially partitioned internally without changing the 2D-noise contract or logical world coordinates.

## 14. Failure behavior

Whole-plan failures include invalid requests/profiles, contradictory road facts, insufficient mandatory parcel candidates, illegal IDs/geometry overlap, or selected mandatory buildings rejected by System 19.

Local roads may not create unauthorized boundary exits. Materialization failures restore the pre-transaction WHAT + Door State snapshots.

Valid outcomes include intentionally vacant parcels, farms without barns, naturally sparse ecological pockets and substantial open land. No fake content is generated to satisfy a visual count.

## 15. Future extension seams

Future systems may add typed constraints/facts for utilities, rivers/topography, addresses, households/businesses, zoning/land value, secondary farm/commercial buildings, parking/vehicles, sidewalks/civic dressing, world-plan persistence and streaming orchestration.

Future Global World Planning may also supply richer inherited road geometry. System 20 continues to preserve inherited facts rather than locally bending a caller-owned regional road merely for aesthetics.

Environment profiles may later select different noise scales/densities/semantic families for forest, desert, scrub, marsh or other ecological profiles without changing parcel/building logic.

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
12. On 2026-08-20 live critique identified the yellow-box road markings, over-straight road network and under-dressed wilderness. Candidate 002 added semantic carriageway/centerline separation, one bent local farm-access branch, and trees/shrubs/rocks while preserving the accepted building/parcel baseline.
13. On 2026-08-20 the next live critique identified that Candidate 002 natural props formed a visible diagonal line. Candidate 003 therefore replaces separate-X/Y cluster-center sampling with mixed-coordinate two-scale 2D noise while leaving Candidate 002 morphology unchanged.
