# Tick Survival Lab — System 20 Local Area / Parcel Generation

Status: **DRAFT — design discussion only; implementation is not approved**

Date: 2026-08-20

Depends conceptually on implemented WHERE / WHAT, implemented System 19 Local Building Generation, and the future higher-level Global World Planning owner. Streaming/materialization, population/outbreak, utilities, vehicles, weather and camera remain separate systems.

## 1. Goal

Plan believable local areas in global tactical coordinates after higher-level world planning has already established the major facts that must cross area boundaries.

System 20 answers:

> Given a bounded global area, stable seed, settlement/area profile, environment profile, and inherited major-road constraints, how are minor roads, parcels, accesses, land uses, building slots and property-scale outdoor dressing arranged inside that area?

The system exists to bridge broad world planning and System 19 building generation without turning either one into a god generator.

## 2. North-star position / generation hierarchy

Canonical hierarchy:

1. **Future Global World Planning** owns geography, settlements/districts/rural regions, major road topology, major utilities/infrastructure, rivers and other cross-region facts.
2. **System 20 Local Area / Parcel Generation** refines one caller-assigned global area into local roads, parcels, access, land use, building placement requests and property/environment dressing.
3. **System 19 Local Building Generation** consumes an already-chosen building/property envelope, orientation, frontage, archetype, instance ID and seed and creates the physical building/property detail.
4. **WHAT / Door State** own the resulting persistent reality after initial materialization.

A System 20 area is a **planning domain, not a streaming chunk**. The same logical plan must remain valid regardless of how future streaming/storage partitions are chosen.

System 20 may create local/minor roads inside its assigned area, but it may not invent new major road exits across the area boundary. All cross-boundary road continuations come from the caller.

## 3. Non-goals

System 20 does **not** own:

- continent/world geography;
- town placement or regional settlement selection;
- major road network topology outside the request;
- rivers or terrain elevation/topography;
- major utility-network topology;
- building interiors, room programs or furniture placement;
- people, households, businesses as social/economic actors;
- loot, parked vehicles, corpses or outbreak damage;
- runtime construction/destruction;
- weather, seasons, lighting, perception or sound;
- camera, zoom, renderer or UI;
- streaming-region size or save-storage partitioning;
- traffic simulation or functional traffic-signal cycles.

A static traffic-signal object may be generated as physical/civic dressing. Traffic behavior is a future system.

## 4. Area profile vs environment profile

The draft deliberately separates two concepts that are often both called a “biome.”

### Area / settlement profile

Controls **human settlement morphology**:

- road density and local-road style;
- parcel size/distribution;
- land-use weights;
- vacancy/open-space rate;
- setbacks;
- density gradients;
- driveway/parking expectations;
- intersection-control expectations;
- building-archetype selection policy.

Examples:

- `rural.crossroads`
- `rural.scattered`
- `suburban.low_density`
- `smalltown.center`
- `urban.grid`
- `industrial.edge`

### Environment profile

Controls **ecological/local surface dressing**:

- base ground-cover families;
- tree/bush/scrub families and density;
- vegetation clustering;
- agricultural suitability/dressing;
- rocks/debris/natural open-space dressing;
- edge blending in global coordinates.

Examples:

- `temperate.rural`
- `desert.scrub`
- `forest.temperate`
- `grassland.plains`
- `mountain.foothill`

The same settlement profile must be reusable with different environments. For example, `rural.crossroads + desert.scrub` and `rural.crossroads + forest.temperate` use the same settlement logic while producing different ecological dressing.

Environment profiles store semantic world choices only, never atlas indices or renderer facts.

## 5. Planned owners

Names may change slightly during implementation, but these responsibility boundaries are the draft target.

### `AreaGenerationRequest.gd`

Pure caller constraints:

- stable `area_id`;
- deterministic `seed`;
- global `Rect2i bounds`;
- `area_profile_id`;
- `environment_profile_id`;
- inherited major-road constraints / allowed boundary connections;
- optional higher-level reserved/forbidden regions when future global planning supplies them.

### `GeneratedAreaPlan.gd`

Pure semantic result containing:

- provenance/version facts;
- road records;
- intersection records;
- parcel records;
- parcel access/driveway facts;
- land-use/property zones;
- System 19 building-generation requests;
- local ground/surface facts;
- outdoor semantic prop placements.

It contains no Nodes, textures, atlas coordinates, camera values or runtime actors.

### `AreaProfileCatalog.gd`

Owns morphology/profile definitions and versioning. It does not place individual buildings or props.

### `EnvironmentProfileCatalog.gd`

Owns environment semantic families/distributions and profile versioning. It does not know settlement policy.

### `LocalRoadPlanner.gd`

Consumes inherited road constraints and may add profile-permitted **minor/local** road segments. It may not create unapproved boundary exits.

### `ParcelPlanner.gd`

Subdivides buildable road-facing land into stable non-overlapping parcels/property regions.

### `ParcelAccessPlanner.gd`

Chooses legal parcel access points, driveways and parking approaches while protecting intersections and road connectivity.

### `BuildingPlacementPlanner.gd`

Chooses eligible System 19 archetypes and exact building/property envelopes/orientations/frontages that fit each parcel.

### `OutdoorPropertyDressingPlanner.gd`

Places semantic parcel-scale facts such as fences, mailboxes, yard vegetation, field regions and commercial parking/dressing while preserving roads, driveways and building approaches.

### `GeneratedAreaValidator.gd`

Owns generic area-plan correctness: bounds, road continuity, parcel overlap, access, building fit and required clearances. Profile-specific expectations remain in focused profile tests rather than becoming one giant catalog validator.

### `AreaMaterializationCoordinator.gd`

Future implementation owner for initial WHAT writes. It materializes System-20-owned terrain/outdoor facts and invokes System 19 only through System 19 public contracts for each building request. After successful initial materialization, System 20 relinquishes runtime ownership.

## 6. Public request contract

Draft request facts:

```text
AreaGenerationRequest
- area_id: String
- seed: int
- bounds: Rect2i                 # global tactical cells
- area_profile_id: StringName
- environment_profile_id: StringName
- inherited_roads: Array[RoadConstraint]
- forbidden_regions: optional typed regions supplied by higher planning
```

`RoadConstraint` should carry stable road identity, class, required global path/anchors within the area and explicit allowed boundary continuation cells. Exact representation is implementation detail, but the important rule is that inherited/cross-region road facts are immutable inputs to System 20.

Requests are invalid if bounds are empty, IDs are invalid, a required profile is unknown, or inherited road constraints are mutually impossible.

## 7. Generated road / intersection contract

A generated road record should expose at minimum:

- stable road ID;
- semantic road class;
- deterministic global centerline/path cells;
- width/surface class where needed;
- whether the segment is inherited or System-20-local;
- legal connections to other road records.

Intersection records should expose:

- stable ID;
- global intersection cell/region;
- participating road IDs;
- semantic control class: `uncontrolled`, `yield`, `stop`, or `signalized`.

System 20 may place static civic props appropriate to the control class, but traffic-law simulation and light cycling are non-goals.

Road rules:

1. inherited road constraints are preserved;
2. local roads must connect to the inherited/local network or terminate legally;
3. no local road may leave request bounds except through a caller-authorized boundary connection;
4. parcels/buildings may not cover road corridors;
5. driveways connect to road edges/access points, not by painting through arbitrary parcels;
6. rural profiles must not accidentally produce suburban street-grid density.

## 8. Parcel contract

A parcel is a stable planning record, not a gameplay inventory/container object.

Each parcel needs:

- stable parcel ID;
- global bounds plus a deterministic whole-cell region/mask;
- land-use class;
- frontage road ID;
- legal access point(s);
- profile-owned setback/buildable region;
- optional primary building request;
- optional future secondary-building capacity;
- property zones such as yard, agricultural field, work yard or parking.

Initial land-use vocabulary:

- `residential`
- `farmstead`
- `commercial_small`
- `agricultural`
- `vacant`
- `wilderness`

Rules:

- parcels never overlap one another;
- parcels never include road corridors;
- occupied parcels must have legal access;
- buildings must remain inside their parcel buildable region;
- an impossible or unsuitable parcel may remain intentionally vacant instead of distorting a building to force occupancy;
- agricultural/wilderness land is allowed to remain genuinely open.

## 9. System 19 placement seam

System 20 must **not** inspect individual building-generator internals or duplicate their envelope-size truth.

Before System 20 implementation, System 19 needs a narrow public placement-description seam, conceptually:

```text
BuildingArchetypePlacementDescriptor
- archetype_id
- archetype_version
- canonical envelope size
- canonical frontage
- supported orientations / oriented required size
```

System 19 owns these geometric placement facts because they must stay synchronized with its archetypes.

System 20 owns **selection policy**: which archetypes are appropriate for `residential`, `farmstead`, `commercial_small`, etc., and with what profile-specific weights.

The System 19 extension must remain read-only and must not expose room/furniture internals.

## 10. Determinism / version isolation

Same request + same System 20/profile/environment versions + same System 19 archetype versions must produce the same semantic plan/signature.

Randomness should be derived by stable named sub-seeds rather than one long mutable RNG sequence. Example conceptual domains:

- roads;
- parcels;
- land use;
- building selection;
- driveways;
- property dressing;
- environment dressing.

Adding a new vegetation decision later must not silently reshuffle all roads and house assignments merely because one shared RNG consumed another number.

Stable child identities derive from `area_id` + deterministic roles, for example:

```text
area.rural.001.road.main
area.rural.001.intersection.center
area.rural.001.parcel.007
area.rural.001.parcel.007.driveway.primary
area.rural.001.parcel.007.building.primary
```

Profile/environment rule changes that intentionally change same-seed output require version bumps.

## 11. Generation pipeline

Proposed deterministic pipeline:

1. validate/normalize request;
2. install inherited major-road constraints exactly;
3. derive profile settlement focus/density fields from inherited road topology and profile rules;
4. generate permitted minor/local roads;
5. reserve road/intersection exclusion corridors;
6. derive buildable frontage regions;
7. subdivide into parcels;
8. classify parcel land use using profile + location/suitability;
9. create access points, driveways and parking approaches;
10. query System 19 placement descriptors and choose only archetypes that physically fit;
11. emit exact System 19 building-generation requests;
12. generate property-scale zones/dressing;
13. apply environment-profile natural dressing in remaining legal space;
14. validate the complete pure area plan;
15. pre-generate/validate all System 19 subplans before any initial world materialization;
16. materialize through public WHAT/System 19 contracts.

There must be no unbounded “keep rerolling until it looks good” loop. Candidate choices are finite, deterministic and fail/leave vacancy cleanly.

## 12. Density / centrality model

Area profiles may define a **density field** or equivalent suitability score based on meaningful local facts such as:

- distance/network distance from a settlement focus/intersection;
- road class/frontage quality;
- parcel size;
- intersection setback;
- inherited reserved terrain;
- environmental/agricultural suitability.

For `rural.crossroads`, density is highest around the central crossroads and falls sharply outward.

Near the center:

- smaller parcels;
- higher chance of `commercial_small`/residential use;
- shorter setbacks;
- possible limited sidewalk/parking treatment.

Farther out:

- larger residential/farmstead parcels;
- longer driveways;
- agricultural/wilderness/vacant land dominates;
- buildings become sparse.

“Rural” must not mean evenly scattering the same density across the entire rectangle.

## 13. Environment dressing / seam safety

Environment profiles use global coordinates and stable environment seeds so adjacent planning areas do not get arbitrary vegetation discontinuities merely because a planning boundary exists.

Natural dressing should use meaningful clusters/zones rather than uniform confetti:

- tree lines along field/property boundaries;
- bushes/trees near houses;
- windbreaks around farms;
- sparse roadside vegetation near sight lines;
- larger untouched wilderness patches;
- open agricultural fields that remain visually open.

Roads, intersections, driveways, parking paths and building approaches have priority over decorative natural dressing.

Environment profiles do not simulate weather/seasons. They define initial semantic ground/vegetation tendencies only.

## 14. Farmstead behavior

A `farmstead` is not merely a farmhouse on a huge generic lawn.

Initial farmstead zones may include:

- primary house/building site;
- yard;
- driveway;
- agricultural field regions;
- work-yard/open equipment region;
- boundary vegetation/fence opportunities.

The system must support future secondary-building slots, but Candidate 001 must **not fake barns/silos/outbuildings** before matching System 19 archetypes exist. Open farm land is valid output.

## 15. Commercial behavior

Commercial parcels are concentrated around higher-quality road frontage and the settlement center according to the area profile.

System 20 positions the System 19 property envelope. It does not recreate gas pumps/parking/interior details already owned by the gas-station archetype.

Current content limitation: System 19 currently has one commercial archetype, `commercial.gas_station.small`. The rural profile may generate additional `commercial_small` parcels, but they remain vacant until real store archetypes are added. System 20 must not generate fake stores merely to satisfy a density target.

## 16. Materialization / persistence rule

`GeneratedAreaPlan` is planning truth only. Initial materialization creates WHAT through public mutation contracts.

Before writes:

- validate the entire area plan;
- generate/validate every selected System 19 building subplan;
- preflight overlaps/required semantic coverage.

A failed virgin-area materialization must not leave a partially generated area. Preferred implementation is preflight plus public snapshot/restore/transaction seams. If current WHAT/Door State public contracts cannot support safe rollback, implementation must stop and return to design rather than reach into internals.

After successful materialization, System 20 does not continuously regenerate the area. Broken doors, new construction, cut trees, moved props and other later changes belong to persistent gameplay truth.

Future save/global-plan systems must preserve enough generation provenance/versioning that old worlds are not silently rewritten by newer generator versions.

## 17. Validation contract

Generic validation should prove at minimum:

1. all generated facts lie within request bounds;
2. inherited major-road constraints are preserved;
3. no unauthorized road exits cross the boundary;
4. road graph connectivity/termination is legal;
5. intersections reference valid road records;
6. parcels are non-overlapping and do not consume road corridors;
7. occupied parcels have legal road access;
8. driveways connect parcel/building access to the frontage network;
9. building envelopes fit inside parcel buildable regions;
10. building envelopes/driveways/required clearances do not overlap illegally;
11. every building request is accepted by the System 19 public placement/generation contract;
12. environment/property props do not block required roads, entrances or driveways;
13. stable IDs/roles are unique;
14. profile/environment IDs and versions are known;
15. deterministic replay produces an identical plan signature.

Profile-specific rules belong in dedicated tests.

## 18. Failure cases

Whole-plan failure:

- invalid request/profile/environment;
- contradictory inherited roads;
- impossible required boundary connectivity;
- duplicate stable identities;
- structural overlap that violates plan invariants;
- System 19 public contract mismatch for an already-selected mandatory building.

Valid local outcomes rather than failures:

- a parcel has no eligible building -> leave it vacant;
- a farm has no barn archetype -> keep its open work/agricultural zone;
- a commercial parcel has no implemented store archetype -> leave it vacant;
- optional vegetation cannot fit without blocking access -> omit that dressing.

## 19. Performance

System 20 is bounded deterministic generation, never per-frame work.

Requirements:

- no full-world scan;
- no unbounded retries;
- avoid naive all-cell-vs-all-cell O(N²) checks;
- use occupancy/spatial indexes or masks for road/parcel/building exclusion;
- stable sub-seeds allow stages to be regenerated/tested independently;
- large candidate areas may be generated before play or in controlled staged work, but wall-clock threading belongs to future loading/streaming orchestration, not this design.

## 20. Safari / mobile

No System 20 logic depends on hover, pointer geometry, frame time or mobile input.

The first rural plan is intentionally larger than the current one-screen critique fixtures. **Camera/large-area presentation is not owned by System 20.** Headless plan tests must be sufficient to validate System 20 itself.

If a user-visible large-area critique viewer or scrolling camera is needed, it must have its own presentation owner rather than adding camera/zoom logic to generation.

## 21. Candidate 001 — `rural.crossroads`

Candidate 001 is the first profile/acceptance target, not a permanent hard-coded map.

### Request

- **256×256 global tactical cells**;
- `area_profile_id = rural.crossroads`;
- initial environment profile: `temperate.rural`;
- fixed critique seed selected for deterministic inspection;
- two caller-supplied cross-region road constraints intersect near the local center: one primary road and one lower-class secondary road;
- SOUTH/NORTH/EAST/WEST boundary continuations come only from those inherited road constraints.

### Target feel

Mostly open rural land with sparse homes/farms, a tiny denser crossroads center, a few commercial parcel opportunities and one visually memorable traffic signal.

### Candidate-specific requirements

1. exactly **one `signalized` intersection**, at the central inherited crossroads;
2. no other traffic lights in Candidate 001;
3. gas station placed on a suitable commercial parcel at/near the central crossroads using the preserved `commercial.gas_station.small` System 19 archetype;
4. at least two additional `commercial_small` parcel opportunities around the center, allowed to remain vacant until real store archetypes exist;
5. approximately **8–12 occupied residential/farmstead parcels** for the critique seed;
6. deterministic critique seed should exercise the accepted residential library rather than inventing new houses: trailer, Small Farmhouse, Large Farmhouse and Compact Laundry House all remain eligible;
7. at least two farmstead parcels with agricultural/open field zones and materially longer driveways than center residences;
8. substantial vacant/agricultural/wilderness area — target **at least 60% of non-road area unbuilt by buildings**;
9. density visibly falls with distance from the central crossroads;
10. no suburban street grid; zero or very few generated local road spurs;
11. intersection approaches remain visually/openly clear enough that vegetation/property dressing does not choke the crossroads;
12. rural homes face/access the road they actually belong to;
13. mailboxes/fences/tree lines/yard clusters may dress properties where supported, but open land remains open;
14. no fake barns, fake stores, people, cars, loot or outbreak scenes;
15. same request/profile/environment versions/seed produce the exact same area signature.

## 22. Candidate 001 visualization dependency

System 20 Candidate 001 can be implemented and validated headlessly before a camera exists.

To *walk* or inspect a 256×256 area comfortably in the live game, the project will need a separate camera/large-visible-window presentation solution. That is not a reason to shrink or corrupt System 20's planning contract.

A future implementation prompt should decide whether to:

- implement System 20 pure-plan generation first, then camera/presentation separately; or
- approve a separately owned DEV area-critique viewer after the planner is green.

## 23. Recovery sources for implementation archaeology

Potential historical sources named by the modular master design:

- golden `ProceduralRegionGenerator.gd` — mine algorithms/data only, never restore as a master generator;
- golden `StreetscapePass.gd` — mine road/street/property/civic placement lessons, not pass-chain architecture;
- frozen reboot rural-generation work — inspect useful rural density/road/property lessons without extending `game/scripts/reboot/`.

Current System 19 accepted archetypes are canonical building-content dependencies, not historical recovery sources.

## 24. Future extension seams

System 20 should accept future higher-level facts without owning their simulation:

- utility corridors/pole/line constraints;
- rivers/water/topography exclusion regions;
- addresses/property identifiers;
- household/business assignments selecting among already-fit building slots;
- zoning/land-value/economic planning;
- secondary farm/commercial outbuildings;
- parking/vehicle spawn facts;
- sidewalks/civic objects for denser profiles;
- world-plan persistence and streaming/materialization orchestration.

Adding those systems should extend typed request/plan seams rather than make System 20 inspect their internals.

## 25. North-star fit

This design serves the **Ultima-style turn-based mini Zomboid** goal by producing physical places that make spatial sense before the outbreak simulation begins: roads connect, homes belong to parcels, farms have land, businesses sit on plausible frontage and open wilderness remains genuinely open.

It preserves the continuous-world rule by planning in global coordinates and treating major cross-boundary infrastructure as inherited constraints. It preserves modularity by leaving building interiors to System 19 and runtime reality to WHAT.

The complexity exists to create recognizable, persistent places and avoid procedural nonsense—not to simulate cadastral law or urban economics for their own sake.

## 26. User-set requirements carried into this DRAFT

These are explicit requirements from the 2026-08-20 discussion, but **do not constitute approval of this complete System 20 draft**:

1. begin with a **rural** area;
2. rural target includes open wilderness, houses, farms and a small crossroads/town-center feel;
3. include a few commercial opportunities and a memorable center with a **single stop light**;
4. System 20 must not be hard-coded to rural and must be designed to handle other “biomes”/area types later;
5. settlement morphology and environment should therefore remain separable so future rural/suburban/urban profiles can combine with desert/forest/grassland/etc. environments.

## 27. Approval gate / unresolved review items

Status remains **DRAFT** until the user approves or revises it.

The main review choices are:

- whether the 256×256 Candidate 001 scale feels right for the first planner test;
- whether `rural.crossroads` should generate any minor road spurs in Candidate 001 or remain purely on the two inherited crossing roads;
- whether `temperate.rural` is the right first environment profile;
- whether the target 8–12 occupied residential/farmstead parcels and >=60% unbuilt area match the desired rural density;
- whether implementation should start with pure-plan/headless System 20 before any large-area camera/viewer work.

No System 20 production code should be written until this design is explicitly approved.
