# Tick Survival Lab — System 20C Rural-Open / Countryside Candidate 001

Status: **IMPLEMENTED — CANDIDATE 001**

Design date: 2026-08-22  
Approval: user explicitly approved implementation on 2026-08-23.

## 1. Goal

System 20C provides real deterministic local planning for ordinary dry countryside outside the five current settlement sites.

The core rule is:

> **Countryside detail is computed from global world facts and global coordinates, not from streaming-region identity.**

System 20C accepts caller-assigned logical bounds and creates dry rural-open terrain while preserving System 00D geography, regional roads and infrastructure corridors. **System 20C itself does not choose logical countryside source partitions.** Downstream implemented System 00F Slice 002 now owns that separate source-partition/materialization responsibility and consumes System 20C only through its public arbitrary-bounds seam.

## 2. Implemented scope

Candidate 001 implements:

1. `rural.open` area profile v1;
2. public `System20AreaRequestProjector.project_rural_open_bounds()`;
3. roadless local requests as a valid base request shape;
4. profile-level road requirements so Crossroads, Small-Town and Rural-Scattered still require inherited roads;
5. optional clipped `inherited_geography` records on `AreaGenerationRequest`;
6. exact preservation of zero or more inherited System 00D regional roads;
7. no local roads, settlement parcels, town blocks or buildings;
8. deterministic dry grass/meadow base plus agricultural field cover on eligible geography;
9. deterministic sparse tree/shrub/rock dressing using world seed + absolute global coordinates;
10. stable natural-prop IDs derived from physical global cells;
11. read-only consumption of intersecting power/water/wastewater corridors;
12. explicit rejection of any bounds containing real river/bridge facts;
13. exact split-vs-combined landscape seam equivalence tests;
14. **no System 00F source-catalog change inside the 20C implementation itself** and no live System 22 presentation switch.

## 3. Non-goals

Candidate 001 itself does not implement:

- System 00F countryside source discovery/partitioning — implemented later by 00F2, outside this System 20 slice;
- stream-region changes or memory eviction;
- physical river/water terrain or bridge traversal/art/collision;
- tactical elevation/slopes;
- local roads, driveways, addresses or property ownership;
- isolated homes/farms or agricultural outbuildings;
- utility poles/wires, wells, septic hardware, or runtime utilities;
- population, vehicles, loot, corpses or outbreak state;
- rendering, camera, player, collision or WHEN changes.

Sparse rural properties remain deferred from Candidate 001. Stable logical countryside-source ownership now exists downstream through System 00F2, so a later System 20 content candidate may add such properties without making them technical-stream-boundary artifacts.

## 4. Public contract revision

### `AreaGenerationRequest`

The request carries:

`inherited_geography: Array[Dictionary]`

Each geography record contains:

- stable source geography ID;
- source grid coordinate;
- clipped rect inside request bounds;
- planning elevation `0..100`;
- landform `lowland`, `rolling`, `upland`, or `ridge`.

The field defaults empty, preserving old callers.

The base request type no longer declares an empty road collection invalid. Roadless world space is valid geometry.

`LocalAreaGenerator` enforces resolved-profile road requirements:

- `rural.crossroads` — inherited road required;
- `smalltown.center` — inherited road required;
- `rural.scattered` — inherited road required;
- `rural.open` — zero or more inherited roads permitted.

### `GeneratedAreaPlan`

A generated `rural.open` plan may legally contain zero roads. Existing profile completeness semantics remain unchanged.

## 5. Rural-open profile

`AreaProfileCatalog.RURAL_OPEN = &"rural.open"`

Current version: **1**.

Profile behavior:

- road layout: `inherit_only`;
- inherited roads optional;
- zero local-road creation;
- zero commercial/residential/farmstead targets;
- no building archetype pools;
- global-coordinate field/noise parameters;
- explicit road/infrastructure clearance for countryside dressing.

`temperate.rural` remains v3 and supplies the existing ground/tree/shrub/rock semantic families.

## 6. Projection seam

`System20AreaRequestProjector.project_rural_open_bounds(plan, area_id, bounds)`:

1. requires a generated System 00D plan and positive bounds inside that world;
2. requires the broad `rural_open` planning context to contain the bounds;
3. rejects positive overlap with any existing settlement `area_site`;
4. queries hydrology and rejects any river/bridge intersection with `rural_open_hydrology_not_materializable`;
5. projects real regional roads; zero roads is valid;
6. clips System 00D geography so every request cell is covered exactly once;
7. projects only intersecting power/potable-water/wastewater corridor facts, not service/facility inventions;
8. builds a `rural.open + temperate.rural` request using the **global world seed**.

`project_site()` remains unchanged for the five settlement sites.

This method deliberately accepts caller-assigned logical bounds rather than deriving source partitions. System 00F2 now supplies stable geography-derived dry-countryside source bounds and IDs to this seam without changing its behavior.

## 7. Landscape owner

Owner:

`game/scripts/generation/areas/RuralOpenLandscapePlanner.gd`

It owns only countryside land cover and natural props.

### Geography

Every accepted request cell must have one inherited geography record. Missing, overlapping or malformed coverage fails.

Geography affects ecology only; it does not create tactical height.

- lowland: strongest agricultural eligibility;
- rolling: moderate agricultural eligibility;
- upland: no agricultural field cover;
- ridge: no agricultural field cover.

### Agricultural ground

Agricultural cells use existing `ground.field_green`.

Field eligibility derives from:

- global world seed;
- absolute global cell coordinates;
- low-frequency deterministic value noise;
- inherited landform/elevation;
- road/infrastructure clearance.

Fields do not imply ownership, crops-as-items, households or active farming.

### Natural props

Candidate 001 uses only existing `temperate.rural` tree/shrub/rock families.

All decisions use world seed + absolute global coordinates. IDs are:

`rural_open.natural.<global_x>.<global_y>`

Therefore changing caller/source bounds cannot change the persistent identity of a countryside prop at a given physical cell.

Natural props avoid agricultural cells, inherited road corridors and projected infrastructure corridors.

## 8. Road behavior

`rural.open` never creates a local road.

When a global road enters the request:

- ID/class/width/clipped geometry come from System 00D;
- ordinary existing System 20 road surface/centerline semantics are reused;
- intersections are uncontrolled;
- legal boundary contacts retain existing authorization semantics;
- landscape dressing clears the road corridor and shoulder.

A completely roadless request is equally valid.

Implementation did **not** need to modify `LocalRoadPlanner`: its existing inherited-road installation plus zero configured local spurs already provides the required `inherit_only` result.

## 9. Settlement-pipeline boundary

`LocalAreaGenerator` branches to a focused rural-open path before settlement reservations/parcels/buildings.

Candidate 001 therefore did not require semantic changes to:

- `InfrastructureReservationPlanner.gd`;
- `ParcelPlanner.gd`;
- `GeneratedAreaValidator.gd`.

This is an implementation simplification, not a reduced contract. The rural-open plan still passes the generic validator, while the dedicated smoke locks profile-specific zero-parcel/zero-building/road/hydrology/geography invariants.

Crossroads/Small-Town/Rural-Scattered generation remains structurally unchanged.

## 10. Determinism / seam contract

For Candidate 001:

1. same global plan + area ID + bounds gives the same plan signature;
2. landscape classification is independent of request-local origin;
3. natural prop identity is independent of area ID;
4. adjacent requests do not restart ecological fields;
5. evaluating two adjacent dry windows separately produces the same cell-level ground and prop truth as evaluating their combined rectangle;
6. inherited regional roads retain exact identity/geometry;
7. all settlement-profile regressions remain protected.

These guarantees are what allow System 00F2 to partition dry countryside logically without making physical landscape truth depend on those partitions.

## 11. Failure behavior

Explicit failures include:

- invalid global plan/bounds/area ID;
- no broad rural-open planning context;
- overlap with a settlement area site;
- malformed/incomplete inherited geography;
- malformed inherited road or planning corridor;
- river/bridge intersection;
- an existing settlement profile requested without inherited roads;
- generic final-plan validation failure.

The profile does not reroll, fabricate roads, substitute settlement morphology, or paint grass over known water.

## 12. Verification

Dedicated smoke:

`game/scripts/ci/RuralOpenCountrysideGenerationSmoke.gd`

Workflow:

`.github/workflows/local-area-generation.yml`

Exact-head context:

`verify/system20-local-area`

The smoke dynamically discovers real test windows from the canonical System 00D v6 world and proves:

- roadless and roadside dry countryside;
- exact regional-road inheritance;
- full inherited-geography coverage;
- lowland/rolling field legality;
- upland/ridge no-agriculture behavior;
- global-cell-stable natural prop identity;
- natural/field/road/corridor exclusion;
- deterministic replay;
- split-vs-combined exact cell semantics;
- real regional-river rejection;
- settlement-site overlap rejection;
- base roadless request validity plus continued settlement-profile road requirements.

First fully green integrated code head:

`cbc39f03d3568ca4fcbe7f294e350eb1c507bbda`

On that exact SHA all seven current contexts succeeded:

- `verify/system00d-global-world` — run `32625507767`;
- `verify/system00f-streaming-materialization` — run `32625507886`;
- `verify/system19-local-building` — run `32625507803`;
- `verify/system20-local-area` — run `32625507729`;
- `verify/system21-camera-view` — run `32625507813`;
- `verify/system22-area-critique` — run `32625507775`;
- `verify/pages-deploy` — run `32625507820`.

Downstream System 00F2 integration later consumed `project_rural_open_bounds()` on verified code head `abe3d56792b74d5dd08882bd4f06dbd76107f35d` while System 20 remained green and `rural.open` stayed v1.

## 13. Protected neighbors

Candidate 001 changes no semantics in:

- System 00D v6 planning;
- System 19 building grammar/archetypes;
- `AreaMaterializationCoordinator.gd`;
- System 00F Slice 001 registry/source/stream-grid orchestration;
- WHAT/WHEN;
- collision/movement/doors;
- Art/rendering;
- camera/player/input/UI;
- System 22 live critique composition.

The live Web world remains Rural Crossroads Candidate 006.

System 00F2 was implemented later as a downstream source/materialization consumer. It did not revise this profile, its deterministic morphology, or its public projection contract.

## 14. Downstream integration and future seams

### Implemented downstream integration — System 00F Slice 002

System 00F2 now defines stable non-overlapping dry-countryside source bounds/IDs independently from technical stream-region coordinates. It derives those bounds from System 00D geography after subtracting exact settlement source bounds and exact unsupported river corridors, then calls `project_rural_open_bounds()`.

This confirms the intended System 20C boundary: **00F owns source/materialization timing; 20C owns countryside morphology.**

### Local hydrology / bridges

A separate approved slice must convert existing global river/bridge intent into physical water/bridge terrain and traversal before river corridor cells can materialize honestly.

### Sparse rural properties

Later rural-open candidates may add isolated road-fronting homes/farms. Stable logical countryside-source ownership now exists, so such content no longer needs to depend on technical stream boundaries.

### Save / memory residency

A future persistence-backed store is still required before true inactive-world memory eviction can exist without confusing non-residency with nonexistence.

## 15. North-star fit

System 20C turns ordinary dry countryside into real deterministic physical world content without pretending unfinished water, properties, population or streaming ownership exists.

It advances the continuous open-world goal while preserving the central architectural rule that logical world facts precede and outlive technical streaming partitions. Downstream 00F2 now proves that this seam works: physical countryside remains stable while source and stream partitioning stay separate.