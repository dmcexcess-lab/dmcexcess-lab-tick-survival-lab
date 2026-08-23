# Tick Survival Lab — System 20C Rural-Open / Countryside Candidate 001

Status: **DRAFT**

Date: 2026-08-22

## 1. Goal

System 20C adds a real local-planning profile for ordinary countryside outside the five current settlement sites.

Candidate 001 is the first bounded step toward a continuously materializable world between settlements. It converts caller-assigned rural-open global bounds into deterministic semantic local terrain containing inherited regional roads, broad agricultural/wilderness land cover, and natural outdoor dressing while preserving System 00D geography and the existing System 20/19 boundaries.

The central rule is:

> **Countryside detail is computed from global world facts and global coordinates, not from streaming-region identity.**

This candidate deliberately does not make 00F choose countryside source partitions. System 20C produces a valid rural-open local plan for caller-assigned logical bounds; a later System 00F Slice 002 may discover/own a stable logical countryside-source partition and feed those bounds into this profile.

## 2. Why this must be a separate profile

The three current System 20 profiles are settlement morphology:

- `rural.crossroads` v5;
- `smalltown.center` v1;
- `rural.scattered` v1.

They all assume road-oriented human development and their current request validation requires at least one inherited road.

The broad System 00D plan already contains `region.rural.open.001` with `area_profile_hint = rural.open`, but there is no System 20 `rural.open` implementation. As a result, 00F honestly leaves technical regions with no settlement site unmaterialized.

Roadless woods/meadow and ordinary roadside acreage are not failed hamlets. They need their own morphology contract.

## 3. Candidate 001 bounded scope

Candidate 001 establishes:

1. `rural.open` area profile version 1;
2. a public global-plan -> rural-open bounded-request projection seam;
3. optional inherited-road support, including **zero-road** requests;
4. optional inherited global-geography context carried into the request;
5. exact preservation/materialization of inherited regional roads when present;
6. no locally invented roads;
7. no settlement parcels, town blocks, commercial opportunities or buildings in this first countryside candidate;
8. deterministic broad field/meadow/wilderness land cover driven by global geography + world-seed/global-coordinate noise;
9. globally coordinate-stable trees/shrubs/rocks with stable IDs derived from physical cells rather than area-local ordinals;
10. dry-land-only generation in Candidate 001: bounds intersecting the currently planned regional river/bridge intent fail explicitly instead of materializing fake grass across water;
11. pure-plan and adjacent-window seam tests;
12. no live System 22 presentation switch and no 00F source-partition change in this slice.

This is useful world content, not a placeholder: roadless countryside becomes real terrain, roadside countryside preserves the actual global road, fields are physical land-cover facts, and vegetation is deterministic persistent WHAT material once a future source owner materializes the plan.

## 4. Non-goals

Candidate 001 does not implement:

- System 00F countryside source discovery/partitioning;
- streaming-grid changes;
- memory eviction/save storage;
- physical river/water terrain;
- bridge art/collision/traversal;
- ponds/ditches/culverts/flooding;
- tactical elevation or slopes;
- new local roads/driveways;
- rural property ownership/addresses;
- isolated houses/farm buildings;
- fences, gates, crops as interactable objects or farm ownership;
- utility poles/wires or runtime electricity;
- wells/septic tanks/plumbing/runtime water or sanitation;
- population, households, jobs, vehicles, loot, corpses or outbreak state;
- renderer/camera/player/WHEN/collision changes.

Sparse roadside homes/farms are intentionally deferred until the logical countryside-source ownership seam is fixed, so property/building footprints cannot become source-boundary artifacts.

## 5. Owner / expected modules

### Existing System 20 owners extended narrowly

- `AreaProfileCatalog.gd`
  - add `RURAL_OPEN = rural.open` v1;
  - mark inherited roads optional for this profile;
  - select `inherit_only` road layout and `rural_open` land-use mode;
  - zero settlement parcel/building targets.

- `AreaGenerationRequest.gd`
  - add optional `inherited_geography: Array[Dictionary]`;
  - stop globally requiring `inherited_roads` to be non-empty;
  - continue validating every road when roads are present;
  - validate optional clipped geography records structurally.

- `LocalAreaGenerator.gd`
  - enforce profile-specific inherited-road requirements after profile resolution;
  - compose the new rural-open landscape owner only for `rural.open`;
  - leave existing profile paths semantically exact.

- `LocalRoadPlanner.gd`
  - `inherit_only` mode returns supplied inherited roads/intersections without creating local roads;
  - an empty inherited-road collection is legal only when the resolved profile authorizes it.

- `ParcelPlanner.gd`
  - `rural_open` mode returns no settlement parcels in Candidate 001.

- `GeneratedAreaValidator.gd`
  - add rural-open profile invariants rather than weakening existing settlement validations.

### New focused owner

`RuralOpenLandscapePlanner.gd`

Owns only rural-open land-cover and natural-prop planning.

Responsibilities:

- consume the request's clipped inherited geography;
- consume the existing `temperate.rural` semantic families;
- classify physical ground cells into base meadow/grass versus agricultural field using global-coordinate deterministic fields;
- vary field eligibility/density by supplied landform/elevation context without creating tactical elevation;
- avoid inherited road corridors and planning reservations;
- generate natural props from world-seed/global-coordinate samples;
- use globally stable cell-derived prop IDs;
- remain independent of renderer/art indices, WHAT mutation, streaming, population and ownership.

### Existing integration adapter extended narrowly

`System20AreaRequestProjector.gd`

Add a separate method conceptually equivalent to:

`project_rural_open_bounds(plan, area_id, bounds) -> Dictionary`

It does not alter `project_site()`.

## 6. Public request contract revision

### Existing fields remain

- area ID;
- seed;
- bounds;
- area/environment profile IDs;
- inherited roads;
- forbidden regions;
- inherited planning constraints.

### New optional field

`inherited_geography: Array[Dictionary]`

Each record contains only clipped source truth needed locally:

- stable source geography-cell ID;
- clipped `rect` inside request bounds;
- source grid coordinate if useful for provenance;
- planning elevation integer;
- semantic landform (`lowland`, `rolling`, `upland`, `ridge`).

The field defaults empty. Existing `project_site()` and all existing fixtures remain empty unless a later separately approved profile chooses to consume geography context.

### Roadless request rule

`AreaGenerationRequest.is_valid()` no longer rejects an empty road array by itself.

The resolved area profile decides whether roads are required:

- Crossroads / Small-Town / Rural-Scattered: still require at least one inherited road and fail if absent;
- Rural-Open: zero or more inherited roads are legal.

This is a deliberate public-contract correction: roadlessness is valid local geography, not an invalid request.

## 7. Rural-open projection seam

`project_rural_open_bounds()` must:

1. require a generated System 00D plan;
2. require non-empty stable area ID and positive bounds fully inside the global world;
3. require the requested bounds to belong to the broad `rural_open` planning context selected by the caller/source owner;
4. reject positive overlap with any existing settlement `area_site` in Candidate 001;
5. project actual major-road segments intersecting the bounds; zero roads is legal;
6. project clipped global geography records covering the request bounds;
7. project hydrology facts and **fail explicitly if a real river/bridge fact intersects Candidate 001 bounds**;
8. project relevant infrastructure corridor facts as read-only planning constraints where they actually intersect, without inventing local facilities/service points;
9. construct `AreaGenerationRequest` with:
   - profile `rural.open`;
   - environment `temperate.rural`;
   - `seed = global_plan.seed` so adjacent rural-open plans share one landscape field;
   - caller-supplied stable area ID/bounds;
   - clipped roads/geography/planning constraints.

The projector does not invent a countryside source grid. The caller owns logical source bounds.

## 8. Geography consumption

System 00D geography remains planning-scale truth, not tactical height.

Candidate 001 uses it only to influence surface/ecology character:

- lowland: strongest agricultural eligibility, meadow/brush mix;
- rolling: moderate agricultural eligibility, mixed meadow/woodlot;
- upland: little/no agriculture, more brush/rock/tree pressure;
- ridge: no agriculture, rock/brush/tree-biased rural ground.

No movement cost, LOS height, slope, cliff or elevation rendering is introduced.

All request cells must be covered by valid inherited geography. Missing geography fails rather than silently reverting to generic grass.

## 9. Land-cover rules

The base physical surface remains compatible with `temperate.rural` v3 semantics.

Candidate 001 creates two broad land-cover classes:

### Natural rural ground

Default grass/meadow base, with globally coherent natural-density fields.

### Agricultural field ground

Uses existing `ground.field_green` semantic.

Agricultural cells:

- are allowed only on eligible supplied landforms;
- come from low-frequency global-coordinate deterministic fields rather than per-area random rectangles;
- are excluded from inherited road corridors/road shoulders and blocking reservations;
- do not imply parcel ownership, a household, crop inventory or an active farmer;
- may continue seamlessly across adjacent rural-open request boundaries because the decision is a function of world seed + global cell, not local area origin.

Candidate 001 may group same-semantic cells into plan ground-region records for efficiency, but grouping IDs are not persistent-world identity.

## 10. Natural-prop rules

Trees/shrubs/rocks use the existing `temperate.rural` semantic families.

Unlike the existing settlement natural-noise implementation, Candidate 001 must not base patch coordinates on `cell - request.bounds.position`.

Every rural-open natural decision uses:

- the shared global world seed;
- absolute global cell coordinates;
- a stable salt/domain;
- supplied landform context;
- whether the cell is agricultural/natural/road-reserved.

This guarantees that changing caller bounds or generating adjacent windows does not shift the ecological field.

Persistent prop IDs are derived from semantic domain + global cell, for example a stable encoding of:

`rural_open:natural:<global_x>:<global_y>`

rather than `area_id + ordinal`.

A cell can therefore never gain a different countryside prop identity merely because a future logical source partition changes.

## 11. Road rules

Candidate 001 never invents a local road.

When global roads intersect the request:

- exact road IDs/classes/widths and clipped centerline geometry come from System 00D projection;
- road surfaces/centerline paint use the existing System 20 / `temperate.rural` semantics;
- legal boundary contacts remain supplied through the existing allowed-boundary-cell contract;
- global road intersection geometry may be recorded normally;
- no signal is invented for an ordinary countryside crossing;
- vegetation/field cells avoid the road corridor and configured shoulder clearance.

A roadless request is equally valid.

## 12. Hydrology boundary for Candidate 001

The current art/physics stack has no canonical physical river/water + bridge implementation.

Therefore Candidate 001 must **not** paint grass/fields across a known System 00D river and call countryside complete.

If `hydrology_constraints_for_bounds()` returns any river segment or bridge intent, `project_rural_open_bounds()` fails with an explicit unsupported-hydrology reason.

This leaves honest source gaps around river-crossing countryside until a separately approved local hydrology/bridge materialization slice exists.

The global river/bridge truth remains unchanged and protected.

## 13. Determinism / seam invariants

For rural-open plans:

1. same global plan + area ID + bounds => exact same plan signature;
2. field/natural cell classification depends on world seed + global coordinates, not request-local coordinates;
3. adjacent non-overlapping requests agree at their shared edge with no ecology reset/banding;
4. splitting a tested dry rural-open rectangle into adjacent sub-rectangles yields the same cell-level terrain/natural semantics as evaluating the combined rectangle, excluding only record grouping/order;
5. inherited global roads clip continuously across neighboring request boundaries;
6. stable natural-prop identity is cell-derived and independent of source-area ID;
7. existing three profile outputs remain exact.

## 14. Failure behavior

Candidate 001 fails explicitly for:

- invalid global plan/request bounds;
- unknown profile/environment;
- malformed inherited geography;
- incomplete geography coverage;
- settlement-area-site overlap;
- real hydrology/bridge intersection;
- malformed inherited road or planning constraint;
- any existing-profile roadless request;
- local plan validation failure.

It does not reroll, silently add a road, substitute a hamlet profile, or erase conflicting global facts.

## 15. Performance / mobile requirements

- pure deterministic generation; no per-frame work;
- cell-level landscape evaluation is bounded to caller-assigned local bounds;
- use coordinate hashing/value fields rather than maintaining giant global noise arrays;
- group terrain output where practical to avoid one Dictionary per cell;
- natural props remain sparse;
- no renderer or Safari-input dependency;
- no asynchronous-worker placeholder.

## 16. Acceptance / tests

Add dedicated `RuralOpenCountrysideGenerationSmoke.gd` and extend the System 20 exact-head workflow.

The smoke should prove at minimum:

1. `rural.open` v1 is a supported area profile;
2. all existing Crossroads/Small-Town/Rural-Scattered profile versions and exact protected signatures remain unchanged;
3. existing settlement requests still reject missing inherited roads at generation/profile validation even though the base request type now allows an empty road list;
4. a real dry **roadless** rural-open window from the canonical System 00D v6 world projects/generates successfully;
5. a real dry **roadside** rural-open window projects the exact global road IDs/geometry and generates successfully;
6. no rural-open local roads, town blocks, parcels or building requests are produced;
7. inherited geography fully covers each accepted request and affects land-cover eligibility;
8. agricultural field ground exists in at least one suitable tested lowland/rolling window while upland/ridge tests never fabricate agriculture contrary to profile rules;
9. trees/shrubs/rocks use only existing environment semantics and never occupy road/field-blocked cells illegally;
10. adjacent dry windows have seam-stable cell-level landscape results;
11. equivalent combined-vs-split dry bounds produce identical cell-level rural-open terrain/natural semantics;
12. natural-prop IDs for the same global cell are identical independent of which test request contains that cell;
13. a canonical bounds intersecting the regional river fails honestly with the explicit hydrology-not-yet-materializable reason;
14. settlement-site-overlap projection fails rather than overwriting settlement morphology;
15. System 00D v6 global signature remains unchanged;
16. System 19, System 20 protected profile regressions, System 00F Slice 001, Systems 21/22 and Pages remain green;
17. no live Web target changes.

## 17. Expected implementation impact after approval

Expected new file:

- `game/scripts/generation/areas/RuralOpenLandscapePlanner.gd`;
- `game/scripts/ci/RuralOpenCountrysideGenerationSmoke.gd`.

Expected narrow changes:

- `game/scripts/generation/areas/AreaGenerationRequest.gd`;
- `game/scripts/generation/areas/AreaProfileCatalog.gd`;
- `game/scripts/generation/areas/LocalAreaGenerator.gd`;
- `game/scripts/generation/areas/LocalRoadPlanner.gd`;
- `game/scripts/generation/areas/ParcelPlanner.gd`;
- `game/scripts/generation/areas/GeneratedAreaValidator.gd`;
- `game/scripts/generation/integration/System20AreaRequestProjector.gd`;
- System 20 workflow + durable System 20/context/changelog docs.

Protected / expected untouched:

- System 00D generated-plan/profile/version/roads/geography/hydrology/infrastructure semantics;
- System 19 building grammar/archetypes;
- `AreaMaterializationCoordinator.gd`;
- all System 00F Slice 001 source/registry/streaming code;
- WHAT/WHEN;
- collision/movement/doors;
- Art assets/catalog/renderers;
- camera/player/input/UI;
- System 22 live critique composition.

## 18. Future seams

### 00F Slice 002 — countryside logical source catalog

After 20C is proven, a separate 00F design may:

- choose stable non-overlapping logical countryside source bounds;
- keep those source IDs independent from technical stream-region coordinates;
- call `project_rural_open_bounds()` + `LocalAreaGenerator`;
- compose countryside and existing settlement sources into one materialization discovery contract;
- prove a different technical stream-region size does not alter countryside source identity or generated cell semantics.

00F does not get changed merely to make 20C tests convenient.

### Local hydrology / bridges

A later bounded System 20/global-to-local hydrology slice can turn existing river/bridge planning truth into physical semantic terrain/structures only after water/bridge art + traversal/collision ownership is explicit.

### Sparse rural properties

Later rural-open candidates may add road-fronting isolated homes/farms after logical source ownership has rules that prevent property footprints from becoming source-boundary artifacts.

### Population / ownership / addresses

Future systems can attach real ownership, addresses, households/jobs and pre-collapse land use without requiring Candidate 001 to fake those facts now.

## 19. North-star fit

Candidate 001 advances the persistent-open-world target without lying about unfinished systems.

It makes ordinary dry countryside a real deterministic physical place, preserves globally coherent roads/geography, supports roadless wilderness, and ensures adjacent local generation does not reveal source seams.

It also preserves the key 00F architecture: technical stream regions do not define the world and do not choose countryside morphology.

## 20. Decisions requiring detailed approval

1. Implement `rural.open` v1 as **dry countryside terrain/land cover only**, with no properties/buildings/local roads yet.
2. Allow zero inherited roads at the base request level, while existing settlement profiles continue to require them.
3. Add optional inherited geography context to `AreaGenerationRequest`, populated only by the new rural-open projection seam in Candidate 001.
4. Use the global world seed plus absolute world coordinates for all rural-open landscape decisions.
5. Derive natural-prop identity from global cell, not area-local ordinal/source ID.
6. Reject river/bridge-intersecting countryside honestly until local water/bridge materialization has its own approved contract.
7. Keep System 00F completely unchanged in this slice; follow with a separate 00F Slice 002 for logical countryside source discovery/materialization.
8. Keep the live System 22 Rural Crossroads presentation unchanged while proving countryside independently.
