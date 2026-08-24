# Tick Survival Lab — System 20 Local Area Generation

Status: **IMPLEMENTED — ten current area profiles**

System 20 turns caller-bounded global planning facts into deterministic local physical area plans. It owns local roads/blocks/parcels/access/property dressing where the selected profile authorizes them, but it never owns global geography, regional road routing, river routing, persistent gameplay truth, streaming activation, rendering or building interiors.

Core rule:

> **System 00D decides large-scale world truth; System 20 preserves that truth while adding profile-authorized local physical detail.**

Current environment profiles:

- `temperate.rural` v3;
- `temperate.suburban` v1;
- `temperate.urban` v1;
- `temperate.industrial` v1;
- `temperate.woodland` v1;
- `temperate.coastal` v1;
- `temperate.marsh` v1.

Current area profiles:

- `rural.crossroads` v5;
- `smalltown.center` v1;
- `rural.scattered` v1;
- `rural.open` v1;
- `rural.watercourse` v1;
- `suburban.neighborhood` v1;
- `urban.mixed` v1;
- `commercial.corridor` v1;
- `industrial.district` v1;
- `civic.campus` v1.

The former Candidate 001/006 documents are implementation history. Their final rules are consolidated here; detailed drafting history remains in Git/changelog.

## 1. Ownership

### System 20 owns

- projection-ready local request interpretation;
- inherited-road installation inside the local bounds;
- profile-authorized local-road layout;
- infrastructure reservation geometry used to protect local planning space;
- semantic blocks/parcels/land use where the profile uses them;
- building placement descriptors sent to System 19;
- deterministic selection among profile-authorized building archetypes that physically fit a parcel;
- access/driveway/parking alignment to real generated building entries;
- local environmental/property dressing;
- rural-open landscape generation;
- physical river/bridge semantic terrain from already-established System 00D hydrology;
- deterministic `GeneratedAreaPlan` output and validation.

### System 20 reads but does not own

- System 00D geography, settlements/sites, roads, utilities, river segments and bridge intents;
- System 19 building grammar/archetypes;
- WHERE geometry rules.

### System 20 does not own

- WHAT after materialization;
- WHEN;
- 00F source identity/activation;
- art/render/camera/input/UI;
- population/outbreak/AI;
- runtime utility behavior;
- swimming/wading/flood simulation.

## 2. Public request contract

`AreaGenerationRequest` carries:

- `area_id`;
- seed;
- positive global `bounds`;
- area/environment profile IDs;
- `inherited_roads`;
- `forbidden_regions`;
- `inherited_planning_constraints`;
- optional `inherited_geography`;
- optional `inherited_hydrology`.

Optional collections default empty so existing profile callers remain compatible.

Profile-specific legality belongs in the generator/validator, not in generic record existence checks.

## 3. Generated plan contract

`GeneratedAreaPlan` carries provenance plus:

- reservations;
- roads/intersections;
- blocks;
- parcels;
- System 19 building requests;
- hydrology features;
- semantic ground regions;
- outdoor props.

`GeneratedAreaPlan.is_generated()` checks only generic structural completion/provenance. It does **not** know that a named profile requires roads, parcels, hydrology or any other profile-specific content. Those requirements belong to `LocalAreaGenerator` and `GeneratedAreaValidator`.

`signature()` deterministically includes all generated semantic/provenance collections.

## 4. Integration projector

Primary integration owner:

`game/scripts/generation/integration/System20AreaRequestProjector.gd`

Public seams include:

- `project_site(plan, site_id)`;
- `project_rural_open_bounds(plan, area_id, bounds)`;
- `project_watercourse_bounds(plan, area_id, bounds)`;
- read-only road/hydrology/power/water/wastewater queries for bounds.

`System20WatercourseRequestProjection.gd` is an **internal cohesive projection helper**, not a peer system. It contains the physical-corridor/bridge-deck projection logic so the already broad integration owner does not become a single giant method file.

Projection never reroutes upstream truth.

The five new baseline settlement morphology profiles are currently callable local content profiles; they do not imply that System 00D already places those district types in the canonical rural-region fixture. A future global planner may select them when its own geography/settlement truth authorizes them.

## 5. Settlement pipeline

For settlement-style profiles the canonical pipeline is:

1. validate request/profile;
2. convert inherited planning constraints into local reservations where relevant;
3. install inherited roads exactly;
4. add profile-authorized local roads;
5. derive intersections;
6. optionally derive semantic town blocks;
7. plan parcels/frontage;
8. classify land use;
9. determine road/property access anchors;
10. read System 19 placement descriptors for the profile-authorized archetype pool;
11. choose deterministically from archetypes that physically fit the parcel;
12. generate/validate the chosen System 19 building plan;
13. align property access to the actual primary exterior door;
14. finalize frontage-normal driveway/access paths for any occupied residential, farmstead, commercial, civic or industrial parcel;
15. detect actual public System 19 parking ground;
16. create frontage-normal approaches/parking extension where legal;
17. apply environment/property dressing;
18. validate the complete area;
19. return pure plan.

System 20 never reaches into System 19 private room/furniture internals.

Fit filtering is not a reroll loop. Given the same request/profile/seed/parcel, the ordered allowed pool and first legal fit are deterministic. If no allowed archetype fits, generation fails honestly instead of clipping a building or silently violating parcel geometry.

## 6. `rural.crossroads` v5

Protected live/reference local profile.

Canonical current fixture retains:

- inherited E/W primary + N/S secondary crossing;
- two deterministic internal 3-cell gravel local-rural roads;
- majority residential/farm local-road frontage;
- current gas station + diner + honest commercial vacancy;
- residential/farm use from the current finalized System 19 library;
- compact setbacks;
- real generated primary-door approaches;
- road-flush parking only when the generated building actually exposes public `ground.parking*`;
- at least 60% non-road unbuilt area;
- deterministic natural/property dressing.

This remains the live System 22 critique target.

## 7. `smalltown.center` v1

Consumes actual System 00D inherited roads plus power, potable-water, wastewater and hydrology planning facts.

Canonical rules:

- deterministic infrastructure reservations protect local planning land without pretending to be finished runtime utility facilities;
- four connected 3-cell paved local-town streets supplement the inherited regional spine;
- semantic town blocks are reservation/road aware;
- four compact main-road commercial opportunities currently contain one Small Gas Station, one Rural Diner and honest vacancies where the protected historical pool has no additional entries;
- ten residential opportunities use the current residential library;
- real primary-door access and actual parking-frontage rules are preserved;
- regional road segments may legitimately end inside the local site;
- inherited frontage is clipped to actual inherited segment extent.

The protected small-town profile retains its historical selection behavior. Baseline fit-filter selection is additive and does not rewrite this reference morphology/signature.

## 8. `rural.scattered` v1

Covers all three current hamlet sites.

Canonical rules:

- exact inherited regional roads remain authoritative;
- exactly two deterministic internal 3-cell gravel local-rural lanes;
- zero commercial center;
- exactly four residential + two farmstead occupied opportunities in the current profile;
- at least four of six occupied properties use local-lane frontage, including at least three homes and one farmstead;
- at least 72% of non-road area remains physically unbuilt;
- decentralized groundwater and onsite-septic records are service intent only—no fake well/tank/drainfield coordinate is invented;
- no semantic town blocks or traffic signal;
- actual System 19 entry/access rules remain shared with other settlement profiles.

A regional road that only lies tangentially along a local mathematical boundary is not treated as entering inherited road geometry.

## 9. `rural.open` v1

Arbitrary caller-bounded **dry countryside** inside the broad System 00D rural-open planning context.

Rules:

- bounds may not positively overlap a settlement area site;
- zero or more inherited regional roads are legal;
- clipped System 00D geography must explain the request area;
- intersecting regional utility corridors are read-only planning context;
- no local roads, settlement parcels, town blocks or buildings are created;
- lowland/rolling land may receive globally coherent agricultural `ground.field_green` cover; upland/ridge do not receive fabricated fields;
- sparse tree/shrub/rock decisions use global world seed + absolute global coordinates;
- natural prop IDs are global-cell based (`rural_open.natural.<x>.<y>`) rather than source/request-local identity;
- split-vs-combined accepted dry bounds must produce identical cell-level landscape truth;
- any real river/bridge intersection is rejected by the dry profile rather than replaced with fake dry terrain.

00F catalog-v1 countryside sources consume this seam without changing morphology.

## 10. `rural.watercourse` v1

Physical local river/bridge terrain from existing System 00D hydrology.

Rules:

- request bounds must be wholly covered by real physical System 00D river corridor geometry;
- physical overlap uses declared river width, not centerline-only intersection;
- river ground semantic is `ground.water_river`;
- only an explicit matching System 00D bridge intent may overwrite water with bridge-deck road terrain;
- Candidate 001 bridge deck geometry is exactly road width × river width centered on the global crossing, oriented by bridge axis;
- bridge-deck ground currently reuses `ground.road_plain` for traversal truth; bridge identity remains explicit hydrology provenance rather than art-driven physics;
- a road crossing water without bridge intent never silently becomes traversable bridge terrain;
- no local roads, parcels, blocks, buildings or decorative water props are generated;
- split-vs-combined accepted watercourse bounds must produce identical final terrain, including partial bridge-deck fragments;
- System 20 does not create 00F logical river source identity.

`LocalRiverBridgePlanner.gd` is the focused local physical-water/bridge owner. `GlobalHydrologyQuery.bridge_deck_rect()` is read-only geometry derived from the already-authoritative bridge intent.

## 11. Baseline settlement morphology library

On 2026-08-23 System 20 gained five reusable one-story settlement/district morphology profiles. They all reuse the proven paved `smalltown_grid` road grammar but own different density, parcel-depth, land-use and System 19 archetype pools.

### `suburban.neighborhood` v1

Recommended environment: `temperate.suburban` v1.

Baseline composition:

- 2 small-commercial parcels;
- 10 residential parcels;
- 1 civic parcel;
- residential pool includes small/family houses and horizontal townhomes;
- civic anchor uses the small clinic profile.

### `urban.mixed` v1

Recommended environment: `temperate.urban` v1.

Baseline composition:

- 5 small-commercial parcels;
- 8 residential parcels;
- 2 civic parcels;
- residential density is represented by one-story townhomes/multi-unit rows rather than upper floors;
- commercial/civic pools use the baseline System 19 store/office/clinic/police profiles.

### `commercial.corridor` v1

Recommended environment: `temperate.suburban` v1.

Baseline composition:

- 6 commercial parcels;
- 2 residential parcels;
- 1 civic parcel;
- 1 industrial parcel;
- commercial pool includes the one-story roadside motel plus grocery/hardware/pharmacy/convenience/office profiles.

This profile exposed and now protects the parcel-fit selection rule: the planner filters to legal descriptor fits before committing an archetype, rather than selecting a large building and failing after placement.

### `industrial.district` v1

Recommended environment: `temperate.industrial` v1.

Baseline composition:

- 2 commercial parcels;
- 6 industrial parcels;
- industrial pool uses one-story warehouse/workshop profiles.

Industrial parcels use the same real frontage-to-primary-entry access invariant as every other occupied property; they are not allowed to become inaccessible simply because their land-use token differs from residential/commercial.

### `civic.campus` v1

Recommended environment: `temperate.suburban` v1.

Baseline composition:

- 1 commercial parcel;
- 2 residential parcels;
- 5 civic parcels;
- civic pool contains school, fire station, police station, clinic and church.

Civic parcels likewise receive real finalized access paths to their generated primary entrances.

## 12. Environment palette library

Environment profiles describe local surface/dressing choices. They do **not** create global geography.

Current palettes:

- `temperate.rural` v3 — established rural baseline;
- `temperate.suburban` v1 — lawns, cleaner paved access, lower natural density;
- `temperate.urban` v1 — concrete/alley surfaces, very sparse vegetation;
- `temperate.industrial` v1 — cracked/oily concrete, chainlink, sparse rough vegetation;
- `temperate.woodland` v1 — forest floor, denser trees/shrubs/rocks;
- `temperate.coastal` v1 — sand/light gravel/coastal vegetation palette;
- `temperate.marsh` v1 — marsh ground, reeds/cattails/wet rough vegetation palette.

Critical boundary:

> **A palette is presentation-ready local environment vocabulary, not permission to invent a coast, marsh, forest region, river or other global landform.**

System 00D or another future global geography owner must establish the corresponding world truth before an integrated world generator selects a geography-dependent palette. Synthetic/focused System 20 tests may invoke a palette directly to validate the content contract.

## 13. Materialization boundary

`AreaMaterializationCoordinator` writes a valid generated area into WHAT + Door State using existing world mutation contracts. Materialization performance must not change generated plan morphology, IDs, profile versions or signatures.

Transaction ownership is explicit:

- standalone `AreaMaterializationCoordinator.materialize()` owns one WHAT + Door State rollback snapshot;
- when System 00F already owns a larger atomic source batch, it calls `materialize_in_transaction()` so the area does not copy the entire accumulated world again;
- generated-building materialization follows the same rule: standalone callers retain an independent transaction, while System 20 calls the building `materialize_in_transaction()` seam under the area/00F transaction.

Ground materialization is coalesced:

- rectangular semantic ground regions use one bulk WHAT terrain mutation/change record per region;
- sparse semantic ground regions use one deterministic sparse terrain batch per region;
- generated-building floor entries preserve their original order while consecutive equal-semantic runs are emitted as sparse batches rather than one mutation/revision/signal per floor cell.

System 20 does not retain authority after successful materialization. A revisit must never regenerate a materialized place merely because its generator can reproduce the original plan.

Hydrology provenance itself is generation metadata; physical water/bridge truth reaches WHAT through ordinary semantic ground regions.

## 14. Validation principles

The generic validator enforces structural/global invariants such as:

- unique stable generated IDs;
- bounds containment;
- legal inherited/local road boundary behavior;
- parcel/road/reservation separation;
- actual access/building coherence;
- ground/prop containment;
- System 19 subplan validity;
- hydrology-feature coherence and bridge authorization for the watercourse profile.

Every parcel gets deterministic road/property access anchors during planning. Final driveway/access cells are emitted only when a supported land-use parcel actually contains a generated building. Occupied residential, farmstead, commercial, civic and industrial parcels all share that invariant.

Profile-specific cardinality/content rules are kept out of `GeneratedAreaPlan.is_generated()`.

## 15. Protected replacement boundaries

A System 20 rewrite must not require changes to:

- System 00D world identity/routing;
- System 19 building internals;
- WHAT/WHEN;
- renderer/art/camera/player/input/UI;
- 00F technical partition geometry.

Likewise changing technical streaming size must not change a System 20 plan for the same logical request.

## 16. Tests

Current System 20 workflow exercises:

- Rural Crossroads regression;
- Small-Town Center generation;
- Rural-Scattered generation across all three hamlets;
- Rural-Open roadless/roadside/landform and split-vs-combined invariance;
- Rural-Watercourse physical width, bridge authorization, split-vs-combined invariance, materialization and traversal-policy proof;
- the five-profile baseline settlement morphology library;
- all seven environment palettes and their art-semantic coverage;
- every baseline target producing a real System 19 building request that passes System 19 validation;
- deterministic replay of every baseline area profile;
- canonical demo startup regression.

System 00F's performance contract additionally proves coalesced terrain change/revision behavior, renderer invalidation compatibility, standalone-vs-enclosing transaction snapshot ownership, and the same-region streaming fast path without changing System 20 generation output.

Exact-head context:

`verify/system20-local-area`

The first exact executable head where the baseline building/area/environment libraries and the complete protected world stack were simultaneously green was `2e7a6e0da27a02f8058a3a79538cd9cb55a48cef`.

System 20D's first clean watercourse implementation head was `1ef3bd08e9d1a4ef258a2013c3af133ce6605002`.

## 17. Future extensions

Future additions such as sparse isolated rural properties, more building/content families, addresses/ownership/zoning, water gameplay, bridge condition/destruction, flooding/wetlands, or new area morphology should extend this owning System 20 contract unless they introduce a genuinely independent state/lifecycle domain.

Do not create another permanent “System 20X” document merely because a new profile is implemented.