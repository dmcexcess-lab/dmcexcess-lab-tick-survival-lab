# Tick Survival Lab — System 19 Local Building Generation / Archetype Critique Lab

Status: **DRAFT — design only; no implementation authorized yet**

Date: 2026-08-16

Depends on:

- implemented WHERE / WHAT foundations;
- implemented Art Catalog and Ground / Structure / Prop renderers;
- implemented Door State for generated doors;
- System 18 Door Interaction once approved/implemented for actually entering generated buildings;
- future Global World Planning remains a separate higher-level system.

## 1. Goal

Create a real reusable **local building generator** that can turn an already-chosen property/building slot into a believable physical building, beginning with one single-wide trailer.

The development loop is intentionally taste-guided:

> generate one trailer -> user plays/looks at it -> user critiques it -> refine archetype rules -> then add the next house archetype

This is not a disposable screenshot generator and not a full world generator. It is the lower-level building materialization engine that a future parcel/property/world planner can call after that higher-level system has decided *where* a building belongs.

## 2. Architectural boundary

System 19 answers:

> “Given this global-space envelope, orientation, archetype, instance ID, and seed, what physical building exists here?”

It does **not** answer:

- where towns are;
- where roads run;
- where parcels are;
- which parcel gets a trailer versus a ranch house;
- addresses;
- utility networks;
- household occupants;
- loot;
- outbreak damage/history;
- streaming boundaries.

Those remain future Global World Planning / Population / Streaming responsibilities.

This distinction preserves the North Star rule:

> global planning decides large-scale coherence first; local materialization fills detail inside already-decided facts.

## 3. Non-goals

V1 does **not** implement:

- full neighborhood generation;
- roads/parcels/property access planning;
- camera or map streaming;
- multi-floor buildings;
- basements;
- roofs/roof visibility systems;
- procedural loot or containers;
- zombies/NPCs;
- power/water functionality;
- locked doors;
- construction/destruction;
- room-based loot tables;
- persistent household/building-record systems not already designed;
- arbitrary architectural grammar;
- automatic furniture physics inference from art.

V1 is one real local-building generation contract plus the first trailer archetype and a critique/showcase integration.

## 4. Existing recovery lessons

Golden generator v6 already contained useful ideas but should not be restored architecturally.

Recovered useful facts:

- functional rooms are better than generic front/back rectangles;
- furniture should imply room purpose;
- special archetypes should own their own layout rules;
- generation must be validated deterministically;
- generation-only code should not own loot/combat/runtime state.

The old trailer implementation was too coarse:

- `trailer_living_kitchen`;
- `trailer_bed_bath`.

System 19's first candidate deliberately improves that target to:

- living/kitchen zone;
- **distinct bathroom**;
- **distinct bedroom**;
- real exterior entrance;
- interior doorway(s);
- windows;
- traversable one-cell circulation.

The old pass is a recovery source for fixture vocabulary, not the new architecture.

## 5. Intended production modules

### Pure request / plan data

`game/scripts/generation/buildings/BuildingGenerationRequest.gd`

Contains only caller-supplied generation facts such as:

- `instance_id: String` — stable caller-owned building instance namespace;
- `archetype_id: StringName`;
- `seed: int`;
- `envelope: Rect2i` in global WHERE coordinates;
- `orientation: int` using canonical N/E/S/W rotation language;
- `frontage_side: int` or equivalent caller-decided entrance-facing constraint.

It contains no texture paths, atlas indices, Nodes, camera state, player state, or loot data.

`game/scripts/generation/buildings/GeneratedBuildingPlan.gd`

Pure semantic result containing:

- selected footprint cells / envelope usage;
- interior ground semantic assignments;
- structure entries: walls, doors, windows with global cells + structure axis;
- prop entries with semantic IDs, anchors, facing, footprints where applicable;
- generation-only room-purpose regions/tags for validation/debug critique;
- deterministic role labels used to construct stable child entity IDs;
- generator/archetype version + seed provenance.

Room-purpose tags in V1 are **plan metadata**, not a new authoritative persistent Room State domain. Physical WHAT facts are the gameplay truth once materialized. If future gameplay needs persistent room identity/type, that gets its own approved domain rather than smuggling room state into WHAT metadata.

### Generator coordinator

`game/scripts/generation/buildings/LocalBuildingGenerator.gd`

- registry/coordinator only;
- maps `archetype_id` to a focused archetype generator;
- validates request basics;
- calls one generator;
- returns plan or explicit failure;
- contains no trailer-specific room logic.

### First archetype

`game/scripts/generation/buildings/archetypes/TrailerBuildingGenerator.gd`

Owns only the `residential.trailer.singlewide` family.

Later house archetypes are added as separate modules under the same contract instead of making one procedural-building god script.

### Validation

`game/scripts/generation/buildings/GeneratedBuildingValidator.gd`

Pure geometry/semantic plan validation:

- no overlap contradictions;
- legal WHERE structure geometry;
- door/window replaces wall cell rather than overlaps it;
- connectivity;
- circulation clearance;
- room-purpose requirements;
- footprint/envelope containment;
- deterministic ID-role uniqueness;
- no generator-specific art or Collision ownership.

Art and Collision semantic coverage are checked separately by integration tests so generation does not become dependent on renderer/physics implementation.

### Initial-world materialization

`game/scripts/generation/buildings/GeneratedBuildingMaterializer.gd`

Consumes a **validated** plan and uses existing public state APIs to create initial physical facts:

- set interior ground terrain semantics in WHAT;
- create/position `wall.*`, `door.*`, `window.*`, `prop.*` entities with deterministic stable IDs;
- explicitly enroll every generated door in 06A with an explicit initial state;
- V1 generated residential doors begin **CLOSED**.

It does not register Collision Catalog rules, render art, or own runtime door interaction.

The caller/composition layer must provide compatible semantic collision profiles and rendering coverage.

## 6. Replaceability / global-planner seam

Future global generation should be able to do:

1. plan road network globally;
2. plan parcel/property globally;
3. decide property use/building archetype;
4. choose a legal building envelope/orientation/frontage;
5. call **System 19** with that request;
6. materialize the returned plan into initial WHAT;
7. afterward, persistent world state owns all gameplay mutations.

System 19 therefore must never scan the world looking for a “nice random place” to build a house. Placement decisions arrive from the caller.

For the current critique lab, a small demo fixture plays the role of the caller by supplying one fixed legal showcase envelope. That is an explicit test/DEV integration, not the long-term property planner.

## 7. Determinism

Same:

- archetype version;
- request data;
- seed

must produce the same semantic plan and deterministic child role IDs.

Randomness is local and seeded. No wall-clock/random-global state.

Changing the archetype algorithm/version may change new generation, but it must not rewrite already-materialized saved buildings. Once materialized, WHAT/Door State own current reality.

## 8. Stable entity IDs

The caller supplies a stable `instance_id` namespace.

Materialized child IDs are deterministically derived from that namespace + semantic role, for example conceptually:

- `<instance>.wall.exterior.001`
- `<instance>.door.exterior.001`
- `<instance>.door.bedroom.001`
- `<instance>.window.living.001`
- `<instance>.prop.kitchen.stove.001`

Exact valid formatting follows current `WorldEntityId` rules.

Generator output must not depend on insertion order to define identity.

## 9. First archetype: single-wide trailer

Canonical archetype ID proposal:

`residential.trailer.singlewide`

### Shape target

- long narrow single-story shell;
- rotates deterministically with request orientation;
- coarse 1 m tactical cells mean proportions are gameplay-readable approximations rather than architectural CAD dimensions;
- initial target envelope should support roughly **5–6 cells exterior width** and **10–12 cells exterior length**, depending on orientation and requested envelope.

The generator chooses only among sizes that fit the supplied envelope.

### Functional program

A valid V1 trailer must contain recognizable physical zones for:

1. **Living / kitchen**
2. **Bathroom**
3. **Bedroom**

The bathroom and bedroom may be compact but must be distinct rather than one `bed_bath` blob.

### Exterior entrance

- exactly one primary exterior door in the first candidate;
- placed on a long side consistent with supplied frontage constraint;
- opens directly into the living/kitchen zone rather than through a nonsensical bedroom/bath entrance;
- exterior access cell remains free of blocking props.

Future archetype variants may add rear doors, porches, utility doors, double-wides, etc.; V1 does not.

### Interior doors

At least the bedroom/bath privacy layout must use physical interior opening(s) where the wall topology requires them.

All generated doors are real `door.*` structure entities, not gaps disguised as doors.

### Windows

Trailer candidate should include a small believable set of windows:

- living/kitchen gets exterior light/window coverage;
- bedroom gets at least one window when geometry permits;
- bathroom window is optional/small and may be omitted in V1.

Windows remain static structure blockers until a future window-state/breaking system exists.

### Interior floor semantics

Use existing semantic art vocabulary where appropriate, for example:

- living/kitchen: `ground.linoleum_green` / other supported domestic surface;
- bedroom: `ground.carpet_beige` or similar;
- bathroom: `ground.tile_white` / `ground.tile_mosaic`.

Generator chooses semantic IDs only; Art Catalog owns presentation.

### Wall / opening semantics

Initial proposal:

- exterior wall: `wall.rural_wood` or another supported residential exterior token;
- interior partition: `wall.interior`;
- exterior door: `door.rural_wood` / `door.house` compatible family;
- interior doors may use `door.house`/residential family;
- windows: `window.rural_wood` / `window.house`.

Exact content token can be tuned before implementation, but all selected semantics must already be renderable and receive explicit collision classification in demo composition.

### Fixture / prop target

The first candidate should physically communicate use with a restrained fixture set, not clutter spam.

Living/kitchen candidate vocabulary:

- stove range;
- refrigerator;
- kitchen sink/counter;
- sofa or loveseat;
- optional small table/chair if circulation permits.

Bedroom:

- single or double bed depending on size;
- small dresser/nightstand if circulation permits.

Bathroom:

- toilet;
- vanity/pedestal sink;
- shower/tub only if footprint supports it without destroying navigation.

Props use existing semantic Art Catalog vocabulary such as `prop.stove_range`, `prop.refrigerator_white`, `prop.kitchen_sink`, `prop.sofa`, `prop.bed_single`, `prop.toilet_modern`, etc. Generator never uses atlas numbers.

## 10. Circulation / tactical quality rules

A generated home must be playable, not merely recognizable in a static image.

V1 rules:

- at least one 1-cell-wide traversable route from exterior door to every functional room;
- no required route through a blocking furniture cell;
- no blocking prop directly on a door/opening cell;
- no “sealed bathroom/bedroom” due to partition mistakes;
- no accidental wall/door/window overlap;
- no structure overlap with the player spawn/access path in the critique fixture;
- doors should create meaningful but not absurd chokepoints;
- furniture may narrow a room but must not make ordinary movement impossible.

Connectivity validation should conceptually test the floor plan with doors treated as open/passable. Runtime Door State remains separate.

## 11. Materialization rules

Materialization is initial-world creation, not runtime regeneration.

Before writing:

- plan must pass `GeneratedBuildingValidator`;
- target envelope may contain caller-provided base terrain, which interior floor assignments may replace;
- existing non-terrain entity occupancy inside intended building cells causes materialization to fail rather than deleting unrelated persistent facts;
- materializer never “cleans up” existing buildings to make its result fit.

After successful materialization:

- generator does not own those entities anymore;
- runtime Door Interaction changes Door State normally;
- future destruction/loot/construction mutate canonical persistent domains;
- regenerating the seed must not overwrite a changed existing building.

## 12. Critique/showcase integration before camera

System 19 should be testable **without building the camera system first**.

Initial live/demo integration proposal:

- keep the current fixed one-screen tactical view;
- use a 13×13 or similarly one-screen **single-building critique lot**;
- road/yard/access is simple authored context around the generated structure;
- one generated trailer occupies the showcase envelope;
- player starts outside its exterior entrance;
- System 18 doors make it enterable;
- no NPCs/zombies/loot are required for the first layout critique.

This may intentionally revise the current authored sample-map content while preserving the old fixture/regression where useful. The implementation design must keep movement/foundation regression coverage even if the live test lot changes.

The purpose is to answer visually and tactically:

- does it look like a trailer?
- do the room sizes feel right?
- is the entrance believable?
- is circulation annoying or interesting?
- does furniture placement make sense?
- are there too many/few windows?
- does it feel too empty or too cluttered?

No camera is necessary until we want multiple buildings / a map larger than one screen.

## 13. User-guided archetype iteration

The first generated trailer is intentionally a **candidate**, not a claim that trailer design is finished.

Recommended content-development loop:

1. implement System 19 architecture + trailer generator;
2. spawn deterministic `Trailer Candidate 001`;
3. user critiques physical layout/playability;
4. change trailer archetype rules based on critique;
5. regenerate/retest candidate(s);
6. once trailer rules feel good, freeze a trailer archetype version;
7. add next archetype, likely `residential.house.small_ranch`;
8. repeat critique cycle.

If an archetype addition fits the existing System 19 public contract, it is a focused content/rule extension rather than a new global-generation architecture rewrite.

If critique reveals the request/plan/materialization contract itself is wrong, revise System 19 explicitly instead of stacking corrective passes.

## 14. Next house after trailer

The intended second archetype is a small ordinary house/ranch, not a mansion.

It should eventually target distinct:

- living room;
- kitchen;
- bathroom;
- primary bedroom;
- optional second bedroom when footprint supports it;
- sensible exterior entrance/frontage;
- windows and domestic fixtures.

But **house generation is not implemented in V1** until the trailer loop has taught us what spatial density/readability works at the current 1 m tactical scale.

## 15. Validation / acceptance criteria

Pure generator tests must prove:

1. same request+seed -> byte-equivalent semantic plan/snapshot;
2. different supported orientation rotates geometry correctly inside envelope;
3. output never exceeds envelope;
4. all structure entries use legal structure axes;
5. no duplicate occupancy contradictions among walls/doors/windows;
6. exactly one primary exterior trailer door;
7. living/kitchen, bathroom, bedroom purpose regions all exist;
8. exterior entrance leads to living/kitchen;
9. every room is reachable with doors treated open;
10. no blocking prop occupies required circulation/door cells;
11. every role/entity ID is deterministic and unique;
12. malformed/too-small request fails explicitly rather than producing a broken building.

Materialization smoke must prove:

13. validated plan becomes canonical WHAT terrain/entities/placements;
14. every generated door is explicitly enrolled CLOSED in 06A;
15. generator/materializer does not mutate existing unrelated occupied cells;
16. resulting semantic IDs are independently covered by current Art Catalog / renderers;
17. resulting blocking structure/prop semantics are independently classified in Collision so no UNKNOWN holes exist;
18. System 18 can auto-open the generated exterior/interior doors through public contracts;
19. current foundation/movement/render/player-shell regressions remain green.

## 16. Performance

V1 building generation is bounded by one local building envelope and should be inexpensive.

Requirements:

- no full-world scan;
- no per-frame generator work;
- deterministic bounded layout attempts;
- avoid unbounded random retry loops;
- validation proportional to plan/envelope size;
- generation occurs only when initial local detail is being created, not continuously during gameplay.

Future streaming may call this for newly materialized virgin properties, but System 19 must not depend on streaming internals.

## 17. Safari/mobile

The generator itself has no Safari/input behavior.

The critique result must remain playable on phone through existing tactical controls and System 18 tap interaction.

No generator rule may depend on desktop-only hover or debug UI.

## 18. Forbidden dependencies

Generation production code must not import:

- renderers;
- texture paths/atlas indices;
- camera/zoom;
- player input;
- HUD/UI geometry;
- Health/Needs/Skills;
- loot/inventory actions;
- AI;
- Reboot runtime;
- world-scale road/parcel planner internals;
- future streaming implementation.

Materializer may use only the public initial-state mutation contracts explicitly approved: WHAT and Door State for V1 physical building creation.

## 19. Future seams

System 19 should later accept/add archetypes for:

- small ranch house;
- larger house;
- duplex;
- apartment units/buildings;
- gas station;
- convenience store;
- standalone retail;
- office;
- warehouse/industrial;
- farm/rural house;
- cabin;
- sheds/garages/outbuildings.

Future higher-level systems may supply:

- parcel/property envelope;
- address/property identity;
- utility connection points;
- household/business identity;
- socioeconomic/building-age/style parameters;
- pre-collapse furnishing variation;
- damage/outbreak scenario state.

Those extend the request/catalog ecosystem; they do not let local building generation choose global geography.

## 20. North-star fit

Believable enterable houses are one of the core experiences of “Ultima-style turn-based mini Zomboid.”

The system preserves depth where it matters—recognizable room purpose, spatial navigation, doors/windows/furniture, persistent physical consequences—without becoming architectural simulation software.

The critique loop is especially valuable at the coarse 1 m tactical scale: we can learn the right density and proportions from actual play before multiplying bad assumptions across an infinite world.

## 21. Decisions currently proposed for approval

1. System 19 is a local building materializer, not the global world planner.
2. Caller supplies envelope/orientation/frontage/instance ID/seed; generator never hunts the world for placement.
3. Pure semantic plan is generated and validated before any WHAT mutation.
4. Initial materialization writes physical WHAT facts and explicitly enrolls generated doors CLOSED in 06A.
5. Room-purpose data is generation/validation metadata in V1, not a hidden new persistent Room State domain.
6. First archetype is `residential.trailer.singlewide`.
7. Trailer target is roughly 5–6 cells wide × 10–12 long before rotation, subject to envelope fit.
8. First trailer must have distinct living/kitchen, bathroom, and bedroom rather than the old combined bed/bath zone.
9. First trailer has one main exterior side entrance, interior doors as needed, windows, and restrained functional furniture.
10. Connectivity/circulation is validated as gameplay geometry, not judged only by appearance.
11. First live critique uses a single-building one-screen lot; camera stays deferred.
12. After trailer critique/refinement, next archetype is a small ordinary house/ranch under the same generator contract.
