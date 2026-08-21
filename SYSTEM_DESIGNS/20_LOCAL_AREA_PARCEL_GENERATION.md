# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS CANDIDATE 004 + INITIAL MATERIALIZATION**

Date: 2026-08-20

System 20 is the local planning layer between future global world planning and finalized System 19 building generation. The user approved a rural-first profile, then iteratively critiqued the live 256×256 area. Candidate 004 incorporates the current accepted lessons: inherited regional roads stay caller-owned; System 20 may add smaller local roads; those local roads may own real parcel frontage; ordinary buildings should sit close to their frontage road unless the intervening space has an explicit purpose; farms may sit somewhat farther back; and countryside ecology uses genuinely two-dimensional deterministic noise rather than authored-looking lines.

## 1. Goal

Given a bounded global area, stable seed, settlement/area profile, environment profile and inherited major-road constraints, produce a believable semantic local-area plan containing:

- inherited and profile-authorized local roads;
- intersections/control classification;
- road-facing parcels;
- land use;
- legal road/property access;
- System 19 building requests;
- driveways/property geometry;
- fields and outdoor/environment dressing.

System 20 may then perform a **one-time transactional initial materialization** of that already-validated plan into WHAT + Door State. After successful materialization, persistent world state owns later reality and System 20 relinquishes ownership.

## 2. Canonical hierarchy

1. **Future Global World Planning** owns geography, settlements/districts/rural regions, inherited major-road topology, major utilities/infrastructure, rivers and other cross-area facts.
2. **System 20 Local Area / Parcel Generation** refines one caller-assigned global area into local roads, parcels, access, land use, building placement requests and property/environment dressing.
3. **System 19 Local Building Generation** consumes an already-chosen envelope/orientation/frontage/archetype/instance ID/seed and creates the physical building/property detail.
4. **System 20 Area Materialization** transactionally writes the validated initial area + System 19 subplans into WHAT and initializes doors CLOSED.
5. **WHAT + typed mechanic state** own all later persistent reality.

A System 20 area is a **planning domain, not a streaming chunk**. Storage/render/streaming windows may differ without redefining logical geography.

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

A static traffic-light object is initial civic dressing only.

System 20 **may** create profile-authorized minor/local roads entirely inside its assigned area. Such roads may own local parcel frontage. They may not invent a new major road or unauthorized area-boundary continuation.

## 4. Area profile and environment profile remain separate

### Area / settlement profile

Controls human morphology:

- local-road density/style;
- which road classes may own parcel frontage;
- parcel size/distribution;
- land-use weighting;
- vacancy/open-space rate;
- front setbacks;
- density gradient;
- driveway expectations;
- intersection control;
- building-selection policy.

Current implemented profile: `rural.crossroads` **v3**.

### Environment profile

Controls ecological/surface semantics:

- base ground;
- paved/local-road surface families and physical centerline semantics;
- tree/shrub/rock families;
- spatial ecological density/noise tendencies;
- field surfaces;
- fence/mailbox/civic/environment props.

Current implemented profile: `temperate.rural` **v3**.

Settlement morphology and ecology remain independently replaceable/combinable.

## 5. Implemented planning owners

All planning owners live under `game/scripts/generation/areas/`:

- `AreaSeed.gd` — stable named sub-seeds and mixed 2D coordinate hashing;
- `AreaGenerationRequest.gd` — caller constraints;
- `GeneratedAreaPlan.gd` — pure semantic result;
- `AreaProfileCatalog.gd` — settlement morphology/versioning;
- `EnvironmentProfileCatalog.gd` — ecological/surface semantics;
- `LocalRoadPlanner.gd` — inherited roads, local roads, intersections;
- `ParcelPlanner.gd` — road-facing parcels and land use;
- `ParcelAccessPlanner.gd` — road/property access and driveways;
- `BuildingPlacementPlanner.gd` — System 19 descriptor-based placement;
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
6. generate parcel candidates from every road explicitly allowed to own frontage;
7. reject parcel candidates overlapping any road corridor, forbidden area or existing parcel;
8. verify enough local-road candidates exist for profile-local occupancy targets;
9. classify land use by centrality/profile;
10. assign road/parcel access;
11. query System 19 placement descriptors;
12. select/place eligible existing archetypes;
13. pre-generate and validate each System 19 subplan;
14. finalize driveways to the actual generated primary exterior entry;
15. create road/field/environment/property dressing;
16. validate the complete pure area plan;
17. return semantic plan and deterministic signature.

There is no unbounded reroll loop. If required morphology cannot fit, generation fails rather than silently reverting to a visibly wrong fallback.

## 7. Determinism and stable identity

Same request + profile/environment versions + System 19 archetype versions produces the same semantic signature.

Named sub-seeds isolate unrelated domains. Vegetation changes do not reshuffle buildings because a shared RNG consumed another value.

`AreaSeed.hash_2d(seed, x, y, salt)` mixes both coordinates into one deterministic spatial sample. `unit_2d()` exposes the same mixed value in 0–1 form.

Stable IDs derive from caller area ID plus deterministic roles/geometry. Intentional same-seed output-rule changes bump the owning profile version.

Version history:

- Candidate 001: `rural.crossroads@1 + temperate.rural@1`;
- Candidate 002: both profiles v2 for road/environment morphology changes;
- Candidate 003: `rural.crossroads@2 + temperate.rural@3`, ecological noise correction only;
- Candidate 004: `rural.crossroads@3 + temperate.rural@3`, local-road frontage/setback morphology correction only.

## 8. System 19 boundary

System 20 may use only System 19 public contracts:

- `LocalBuildingGenerator.placement_descriptor()`;
- `LocalBuildingGenerator.generate()`;
- `GeneratedBuildingValidator`;
- public `GeneratedBuildingPlan` placement/primary-entry facts;
- `GeneratedBuildingMaterializer` during initial materialization.

It may not inspect individual building generator/profile internals or duplicate their canonical geometry truth.

## 9. Candidate 004 — `rural.crossroads@3 + temperate.rural@3`

`RuralCrossroadsPlanFixture.gd` still supplies:

- global bounds `Rect2i(1000,2000,256,256)`;
- seed `20001`;
- inherited 5-cell primary east/west road;
- inherited 3-cell secondary north/south road;
- signalized crossing `(1128,2128)`.

Those inherited roads remain exact caller constraints and retain their authorized boundary exits.

### 9.1 Road morphology

Candidate 004 keeps the inherited regional crossroads and adds **two** deterministic small rural roads:

- road class `local_rural`;
- 3 cells wide;
- internal only, with no area-boundary exit;
- each joins the inherited primary road at an ordinary uncontrolled junction;
- each contains multiple cardinal bends/segments;
- gravel/unpainted surface semantics;
- **parcel-frontage authority enabled**.

The two local roads extend into opposite portions of the countryside so local development is not forced onto one inherited highway axis.

The inherited crossroads remains the only signalized intersection. Candidate 004 therefore has four roads total and three intersections: one signalized inherited crossroads and two uncontrolled local-road junctions.

### 9.2 Road surfaces / paint

The Candidate 002 road-presentation correction remains locked:

- inherited paved corridors use `ground.road_plain`;
- only the center path receives `ground.road_yellow_line_h` / `ground.road_yellow_line_v`;
- centerline paint is withheld through immediate intersections;
- both local rural roads use `ground.gravel_dark` and no yellow centerline.

These are semantic world facts, not renderer instructions. System 05 and recovered art remain unchanged.

### 9.3 Parcel frontage and interior land use

Candidate 004 removes the previous “all development hugs inherited roads” failure.

Polyline local roads expose only their straight segment spans as legal frontage. Parcel generation:

- keeps a corner/end safety margin around local-road bends;
- creates parcels on either side of usable local-road segments;
- rejects any parcel touching any road corridor;
- gives local parcels enough rear depth for yards/fields without increasing their **front** setback;
- requires enough legal local-road candidates to satisfy the configured local occupancy target.

The critique target remains:

- 3 `commercial_small` opportunities;
- 6 residential parcels;
- 4 farmsteads;
- 12 occupied buildings total: gas station + diner + ten homes/farmhouses;
- one intentionally vacant commercial opportunity;
- all existing System 19 residential profiles exercised;
- >=60% of non-road area remains unbuilt by building envelopes.

Commercial opportunities remain on the inherited primary road near the tiny center. Of the ten residential/farmstead properties, Candidate 004 targets **at least six on local roads**: at least three residential and at least three farmsteads. This is a deliberate majority, not a fallback preference.

### 9.4 Front setback rule

The user explicitly rejected large purposeless strips of empty grass between road and building.

Candidate 004 therefore treats **road edge -> building facade** as the meaningful setback measure. Total driveway length is not used as a setback proxy because an off-center front door may require lateral driveway travel even when the building itself is close to the road.

Current profile intent:

- ordinary residential: very close frontage (`residential_setback = 1` inside the parcel/buildable geometry);
- small commercial: very close frontage (`commercial_setback = 1`) because Candidate 004 does **not** generate a parking lot;
- farmstead: modestly farther back (`farmstead_setback = 4`) while retaining useful land behind the house.

Regression rules lock average facade setbacks to:

- residential <= 5 cells from road edge;
- commercial <= 5 cells from road edge;
- farmstead > residential and <= 8 cells from road edge.

Candidate 004 deliberately generates **zero parking cells**. A future parking lot is valid only when explicitly generated as physical property geometry/surface; unused grass is never treated as implicit parking.

### 9.5 Driveway geometry

Driveways connect the actual road edge to the actual generated System 19 primary exterior entry.

For readable property access, the path now:

1. enters the parcel **perpendicular to the frontage road first**;
2. then turns near the building toward an off-center primary door when needed.

This avoids unnatural travel along the road shoulder/front property line, preserves mailbox space, and separates visual front setback from lateral entry alignment.

### 9.6 Natural rural dressing — Candidate 003 rule preserved

Candidate 004 retains `temperate.rural` v3 unchanged.

Natural placement uses two-scale deterministic 2D noise:

1. low-frequency smooth value noise modulates broad density;
2. independent per-cell coordinate noise decides individual placement;
3. a second broad noise field biases tree-heavy, shrub-heavy or rocky pockets;
4. independent coordinate hashing selects semantic variants.

Natural dressing remains clear of:

- roads and driveway halos;
- building envelopes;
- active fields;
- occupied residential/commercial/farmstead interiors;
- the immediate signalized town center.

The anti-diagonal regression remains in place: broad map coverage and bounded X/Y correlation are checked across twelve consecutive seeds.

## 10. Candidate 004 pure-plan verification

`LocalAreaGenerationSmoke.gd` protects:

- same-seed determinism and different-seed variation;
- exact inherited-road/boundary integrity;
- two inherited roads + two internal bent local rural roads;
- one signalized crossroads + two uncontrolled local-road junctions;
- local roads have no boundary exits and are real parcel-frontage authorities;
- parcel non-overlap / all-road exclusion;
- required local-road parcel capacity;
- 3 commercial / 6 residential / 4 farmstead targets;
- >=6 of the ten homes/farmsteads on local roads, including >=3 residential and >=3 farmstead;
- gas station + diner + honest vacant commercial opportunity;
- all four saved residential archetypes in the critique seed;
- close residential/commercial facade setbacks and bounded farm setbacks;
- zero fake parking cells;
- frontage-first driveway geometry compatible with mailboxes/access;
- >=60% unbuilt non-road area;
- plain inherited paved corridors + single centerlines + two gravel local roads;
- one traffic signal / ten mailboxes / real field zones;
- Candidate 003 two-dimensional tree/shrub/rock noise distribution;
- every building request accepted by System 19;
- recovered-art semantic coverage;
- twelve consecutive seeds without reroll loops while preserving the local-road majority, close setbacks, buildings, roads and environmental distribution.

Dedicated workflow: `.github/workflows/local-area-generation.yml`.
Exact-head context: `verify/system20-local-area`.

## 11. Initial materialization owner

`AreaMaterializationCoordinator.gd` is unchanged.

It is **not part of pure planning**. It owns only the one-time initial write transaction:

1. validate the `GeneratedAreaPlan` against its request;
2. regenerate/validate every System 19 subplan;
3. preflight stable entity IDs;
4. snapshot WHAT + Door State;
5. apply area ground regions in priority order;
6. materialize outdoor semantic props;
7. materialize every System 19 building and initialize doors CLOSED;
8. rollback WHAT + Door State on any failed write;
9. return success and relinquish generation ownership.

Long-term save-file format and streaming-region transactions remain future ownership.

## 12. Presentation boundary

System 20 owns **no camera or viewer behavior**.

The live critique presentation belongs to `SYSTEM_DESIGNS/22_LARGE_AREA_CRITIQUE_RUNTIME.md`, consuming materialized WHAT and System 21 camera services through public contracts.

Candidate 004 changes only System 20 road/parcel/access morphology and tests/docs. It does not change Art Catalog/assets, rendering, camera behavior, player movement, door behavior, or System 19 building internals.

## 13. Performance / mobile

Planning/materialization are bounded startup work, never per-frame systems.

The current 256×256 environment scan performs bounded deterministic eligibility/noise evaluation. Parcel/local-road work is bounded by explicit profile counts and segment lengths. There are no unbounded rerolls.

System 22 still renders only its bounded moving window rather than all 65,536 cells every frame.

## 14. Failure behavior

Whole-plan failures include:

- invalid requests/profiles;
- contradictory inherited road facts;
- unauthorized local-road boundary exits;
- insufficient mandatory parcel candidates;
- **insufficient local-road frontage to satisfy the profile's local occupancy target**;
- illegal IDs/geometry overlap;
- mandatory buildings rejected by System 19.

Generation does not silently revert to placing everything on inherited roads if local-road morphology fails.

Materialization failures restore pre-transaction WHAT + Door State snapshots.

Valid outcomes include intentionally vacant parcels, farms without barns, naturally sparse ecological pockets and substantial open land. No fake content is generated merely to fill space.

## 15. Future extension seams

Future systems may add typed constraints/facts for:

- utilities;
- rivers/topography;
- addresses;
- households/businesses;
- zoning/land value;
- secondary farm/commercial buildings;
- **real parking lots/parking access**;
- vehicles;
- sidewalks/civic dressing;
- world-plan persistence;
- streaming orchestration.

Future Global World Planning may supply richer inherited road geometry. System 20 continues to preserve inherited facts rather than locally bending caller-owned regional roads for aesthetics.

Environment profiles may select different noise scales/densities/semantic families for forest, desert, scrub, marsh or other ecological profiles without changing parcel/building logic.

## 16. Approved decisions / critique history

1. Begin with rural open wilderness/houses/farms and a tiny crossroads center.
2. Keep a single memorable traffic light.
3. Settlement morphology and ecological environment remain separate profile dimensions.
4. Keep the 256×256 temperate-rural critique area.
5. Target occupied residential/farmstead count is 8–12; critique target remains ten.
6. At least 60% of non-road land remains unbuilt.
7. System 20 is a global-coordinate planning domain, never a streaming chunk.
8. The area test uses only the existing System 19 building library.
9. Pure planning stays independent from materialization and presentation.
10. Candidate 002 fixed wide-road markings, added the first bent local road and added natural dressing.
11. Candidate 003 replaced correlated X/Y vegetation clusters with true mixed-coordinate 2D noise.
12. On 2026-08-20 the user identified that development still lined the inherited center road and that buildings sat too far behind purposeless open space.
13. Candidate 004 therefore makes two small internal rural roads real parcel-frontage authorities, targets a majority of homes/farmsteads on those local roads, tightens visible road-to-facade setbacks, keeps farms only modestly farther back, and generates no implicit/fake parking lot.
14. If parking is later used to justify commercial setback, it must be explicit physical generated property geometry/surface.
