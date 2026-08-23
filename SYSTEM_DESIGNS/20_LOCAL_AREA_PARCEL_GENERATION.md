# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **IMPLEMENTED — RURAL CROSSROADS 006 + SMALL-TOWN 001 + RURAL-SCATTERED 001 + RURAL-OPEN 001 + INITIAL MATERIALIZATION**

Updated: 2026-08-23

System 20 is the local physical-planning layer between System 00D global world planning and System 19 building generation. It preserves caller-owned global facts, adds only profile-authorized local morphology, and may transactionally create initial WHAT + Door State through its separate materialization owner.

A System 20 planning area is a **logical generation domain, not a streaming chunk**.

## 1. Canonical hierarchy

1. **System 00D** owns global geography, settlements/planning regions, major roads, hydrology and regional infrastructure.
2. **System 20** refines caller-assigned global bounds into local roads/land cover/reservations/blocks/parcels/access/building requests/environment according to the resolved profile.
3. **System 19** owns building/property internals for already-selected building envelopes.
4. **AreaMaterializationCoordinator** performs the one-time initial validated area write into WHAT + Door State.
5. **WHAT + typed mechanic state** own all subsequent persistent reality.
6. **System 00F** may choose when a logical source is materialized/active, but stream regions never define System 20 morphology.

## 2. Ownership / non-goals

System 20 does not own:

- global settlement/geography/river/major-road/infrastructure planning;
- households, population, jobs or outbreak simulation;
- runtime utilities;
- loot, vehicles, corpses or construction/destruction mechanics;
- rendering, camera, player input or UI;
- stream/storage partition geometry;
- save-file encoding;
- WHEN scheduling.

System 20 may create local roads only when the resolved profile authorizes them. It may reserve land around supplied infrastructure facts, but reservations are planning land rather than fake finished facilities.

## 3. Area/environment profiles

Current area profiles:

- `rural.crossroads` **v5**;
- `smalltown.center` **v1**;
- `rural.scattered` **v1**;
- `rural.open` **v1**.

Current environment profile:

- `temperate.rural` **v3**.

Area profiles own morphology/human land-use rules. Environment profiles own surface/ecology semantic families.

## 4. Public request contract

`AreaGenerationRequest` carries:

- stable area ID;
- seed;
- global bounds;
- area/environment profile IDs;
- zero or more inherited major-road records;
- forbidden regions;
- normalized inherited planning constraints;
- optional clipped `inherited_geography` records.

The base request type permits zero roads because roadless space is valid geography. The resolved profile decides whether roads are required.

Existing settlement profiles still require inherited roads. `rural.open` permits zero or more.

Normalized planning constraints continue to use stable source IDs, domain/kind/reservation role, explicit point/cardinal geometry and blocking policy. Current domains include hydrology, power, potable water and wastewater.

`inherited_geography` is currently consumed only by `rural.open` and contains stable source geography ID, clipped rect, source grid coordinate, planning elevation and landform.

## 5. Generated plan contract

`GeneratedAreaPlan` contains/signs:

- reservations;
- roads/intersections;
- optional town blocks;
- parcels;
- System 19 building requests;
- semantic ground regions;
- outdoor props;
- area/environment profile versions.

A valid `rural.open` plan may have zero roads. Existing profile completeness rules remain unchanged.

## 6. Implemented owners

Canonical planning code lives under `game/scripts/generation/areas/`:

- `AreaSeed.gd` — deterministic named/2D hashing;
- `AreaGenerationRequest.gd` — public local-generation input;
- `GeneratedAreaPlan.gd` — pure semantic output;
- `AreaProfileCatalog.gd`;
- `EnvironmentProfileCatalog.gd`;
- `InfrastructureReservationPlanner.gd`;
- `LocalRoadPlanner.gd`;
- `TownBlockPlanner.gd`;
- `ParcelPlanner.gd`;
- `ParcelAccessPlanner.gd`;
- `BuildingPlacementPlanner.gd`;
- `CommercialPavedFrontagePlanner.gd`;
- `OutdoorPropertyDressingPlanner.gd`;
- `RuralOpenLandscapePlanner.gd` — dry countryside land cover/global-coordinate natural props;
- `GeneratedAreaValidator.gd`;
- `LocalAreaGenerator.gd` — coordinator only;
- `AreaMaterializationCoordinator.gd` — separate initial WHAT/Door transaction.

Integration adapter:

`game/scripts/generation/integration/System20AreaRequestProjector.gd`.

Planning imports no renderer/camera/player/runtime simulation owner.

## 7. Settlement-profile pipeline

For Crossroads, Small-Town and Rural-Scattered the existing pipeline remains:

1. validate request and resolve profiles;
2. convert inherited planning constraints into legal reservations;
3. install exact inherited roads;
4. add profile-authorized local roads;
5. derive intersections;
6. derive optional blocks;
7. produce legal road-facing parcel candidates;
8. classify land use and access;
9. place buildings only through public System 19 descriptors/generation;
10. align occupied approaches to the actual generated `door.exterior.primary`;
11. connect only real public `ground.parking*` frontage to its road;
12. add property/environment dressing;
13. validate the complete plan.

There is no unbounded reroll loop.

## 8. Rural Crossroads Candidate 006

`rural.crossroads@5 + temperate.rural@3` remains the protected live/local integration anchor.

Key accepted facts:

- 256×256 logical area;
- exact inherited primary + secondary crossing;
- two internal bent 3-cell gravel `local_rural` roads;
- one signalized inherited crossroads;
- gas station + diner + one honest commercial vacancy;
- 6 residential + 4 farmstead occupied opportunities;
- at least 6/10 residential/farm properties on local roads;
- compact meaningful setbacks;
- all approaches end on actual System 19 primary doors;
- generic road-flush real parking/forecourt frontage only when the generated building exposes `ground.parking*`;
- >=60% non-road area physically unbuilt;
- deterministic mixed-coordinate ecological dressing.

Its request/signature remains a hard regression as newer profiles are added.

## 9. Small-Town Center Candidate 001

Detailed design: `20A_SMALLTOWN_CENTER_CANDIDATE_001.md`.

`smalltown.center@1 + temperate.rural@3` consumes the real System 00D small-town site.

It adds:

- normalized global power/water/wastewater/hydrology constraints;
- deterministic infrastructure facility/corridor reservations;
- compact connected internal paved `local_town` streets;
- semantic town blocks carved around blocking reservations;
- four small-commercial opportunities: gas station + diner + honest vacancies;
- ten residential opportunities favoring local-town frontage;
- inherited-road frontage limited to actual inherited segment extent;
- real System 19 door alignment and parking rules.

Regional roads may legitimately terminate inside the local planning window; only actual boundary contacts require authorized exits.

## 10. Rural-Scattered / Hamlet Candidate 001

Detailed design: `20B_RURAL_SCATTERED_CANDIDATE_001.md`.

`rural.scattered@1 + temperate.rural@3` covers all three current hamlet sites.

It provides:

- exact inherited regional-road truth;
- two internal 3-cell gravel `local_rural` lanes using horizontal/vertical-agnostic spine selection;
- zero commercial center;
- exactly 4 residential + 2 farmstead occupied opportunities;
- at least 4/6 occupied properties on local lanes;
- no semantic town blocks;
- >=72% non-road area unbuilt;
- decentralized groundwater/septic retained as service intent only;
- no fake rural substation/well/septic facilities;
- exact primary-door property access.

A regional road lying only along the mathematical local-area boundary is tangential context rather than an entering road.

## 11. Rural-Open / Countryside Candidate 001

Detailed design: `20C_RURAL_OPEN_COUNTRYSIDE_CANDIDATE_001.md`.

`rural.open@1 + temperate.rural@3` provides arbitrary **dry** countryside planning for caller-assigned logical bounds inside the broad System 00D rural-open planning context.

### 11.1 Projection

`System20AreaRequestProjector.project_rural_open_bounds(plan, area_id, bounds)`:

- rejects overlap with the five settlement area sites;
- rejects any real river/bridge intersection until local hydrology exists;
- projects zero or more actual regional roads;
- clips complete global geography context;
- projects intersecting power/water/wastewater corridors only;
- uses the global world seed so adjacent requests share one landscape field.

The method does not choose source partitions. The caller/next 00F slice owns logical source bounds.

### 11.2 Morphology

Candidate 001 creates:

- no local roads;
- no town blocks;
- no settlement parcels;
- no building requests;
- grass/meadow base;
- `ground.field_green` agriculture on eligible lowland/rolling cells only;
- no agriculture on upland/ridge;
- sparse globally coordinate-stable trees/shrubs/rocks;
- global-cell-derived natural prop IDs.

Landscape decisions use world seed + absolute global coordinates, not `cell - request.bounds.position`.

Consequently, split and combined dry countryside requests produce identical cell-level ground and natural-prop truth.

### 11.3 Implementation boundary

The rural-open path branches before the settlement reservation/parcel/building pipeline. Existing `LocalRoadPlanner` already supports the required inheritance-only result when no local spurs are configured, so no redundant road-planner special case was added.

`ParcelPlanner`, `InfrastructureReservationPlanner` and the generic validator did not require semantic changes.

## 12. System 19 boundary

System 20 uses only public System 19 contracts:

- placement descriptor;
- generated building request/plan;
- validator;
- public primary-entry and ground semantics;
- building materializer during initial area materialization.

System 20 does not inspect individual archetype internals.

Rural-Open Candidate 001 invokes no System 19 building content because it deliberately creates no properties/buildings.

## 13. Initial materialization

`AreaMaterializationCoordinator.gd` remains the lower-level one-time initial write owner:

1. validate generated area;
2. regenerate/validate System 19 subplans where present;
3. preflight stable IDs;
4. snapshot WHAT + Door State;
5. write terrain/outdoor props/buildings;
6. initialize generated doors CLOSED;
7. rollback on failure;
8. relinquish generation ownership on success.

System 20C did not modify this owner.

System 00F Slice 001 currently composes this materializer only for the five existing System 00D area-site sources. Rural-open source discovery/materialization is the next separate 00F seam.

## 14. Determinism/versioning

Intentional same-seed output-rule changes bump the owning area/environment profile.

Current versions:

- `rural.crossroads@5`;
- `smalltown.center@1`;
- `rural.scattered@1`;
- `rural.open@1`;
- `temperate.rural@3`.

Rural-open natural persistent IDs depend on physical global cells rather than caller/source ID, preventing a future source-partition change from changing countryside identity.

## 15. Verification

Dedicated System 20 smokes:

- `LocalAreaGenerationSmoke.gd` — Crossroads Candidate 006;
- `SmallTownCenterGenerationSmoke.gd`;
- `RuralScatteredGenerationSmoke.gd`;
- `RuralOpenCountrysideGenerationSmoke.gd`.

The rural-open smoke proves real roadless/roadside windows, geography/field legality, global-cell props, river/settlement rejection, deterministic replay and split-vs-combined exact seam semantics.

Workflow:

`.github/workflows/local-area-generation.yml`

Exact-head context:

`verify/system20-local-area`

First green System 20C integrated code head:

`cbc39f03d3568ca4fcbe7f294e350eb1c507bbda`

On that SHA all seven current repository gates succeeded, including System 00F and Pages.

## 16. Presentation/performance

System 20 owns no viewer/camera behavior. The live Web critique still uses Rural Crossroads Candidate 006 through System 22.

Planning is bounded caller-triggered work rather than per-frame computation. Countryside uses coordinate hashing/value fields rather than giant global noise arrays.

## 17. Failure behavior

System 20 fails rather than hiding invalid facts. Examples include:

- invalid/malformed request/profile;
- missing required inherited roads for settlement profiles;
- incomplete/malformed rural-open geography;
- unauthorized local-road boundary exits;
- insufficient settlement parcel capacity;
- invalid reservations/overlap;
- impossible building/door/access geometry;
- rural-open settlement-site overlap;
- rural-open river/bridge intersection;
- generic final-plan validation failure.

## 18. Future seams

Known next extensions include:

- **System 00F Slice 002** stable logical countryside source catalog/materialization, independent from technical stream regions;
- local physical river/bridge materialization;
- later isolated rural properties once source-boundary ownership is safe;
- addresses/ownership/zoning;
- richer System 19 settlement/agricultural content;
- private well/septic placement and local utility distribution;
- runtime utilities;
- households/businesses/jobs/population/outbreak;
- vehicles/traffic.

## 19. Approved decisions / history

1. System 20 planning areas are global-coordinate logical domains, not stream chunks.
2. Rural Crossroads Candidate 006 remains the accepted live anchor.
3. Small-Town 001 added infrastructure-aware town morphology without changing global infrastructure ownership.
4. Rural-Scattered 001 added sparse three-site hamlet morphology without a fake commercial center.
5. On 2026-08-23 the user approved System 20C Rural-Open Candidate 001.
6. Roadlessness is valid base geography; individual profiles decide whether roads are required.
7. Rural-open landscape truth uses global world seed + absolute coordinates.
8. Rural-open natural prop identity is global-cell-derived, not area/source-derived.
9. Candidate 001 is dry countryside only; known river/bridge intersections fail until physical local hydrology is separately approved.
10. System 00F remains a separate source/materialization owner and was not rewritten by 20C.

## 20. System boundary summary

System 00D owns global coherence; System 20 owns local physical generation; System 19 owns building internals; System 00F owns logical materialization orchestration/technical activation; WHAT owns persistent current reality; System 21 owns camera; System 22 owns DEV presentation. Streaming never defines physical world truth.