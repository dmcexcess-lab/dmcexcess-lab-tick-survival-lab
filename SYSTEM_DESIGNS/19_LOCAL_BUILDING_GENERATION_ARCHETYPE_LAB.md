# Tick Survival Lab — System 19 Local Building Generation / Building Grammar

Status: **IMPLEMENTED — HARDENING TRIAL 001 ACTIVE**

Date: 2026-08-20

System 19 is the local physical-building owner between higher-level parcel planning and persistent WHAT. The original archetype critique lab produced five saved reference buildings. The current hardening phase converts the recurring lessons from those references into reusable building rules, then proves the rules on buildings that were not hand-authored cell-by-cell.

The user-approved finish condition is now explicit:

> Build two arbitrary buildings successfully from the extracted grammar. If both look right in playtest, finalize System 19 and move on to System 20.

Trial 001 is `commercial.diner.rural_small`.

## 1. Goal

Given a caller-selected building/property slot, stable instance namespace, archetype/profile, seed, global envelope, orientation and frontage, produce a believable deterministic physical building plan that can be validated and materialized into the persistent world.

System 19 should make adding a barn, diner, store, church, warehouse or another house primarily **profile/content work**, not another rewrite of generation architecture.

## 2. Architectural position

Generation hierarchy:

1. future Global World Planning decides geography, settlements and cross-area infrastructure;
2. System 20 Local Area / Parcel Generation decides local roads, parcels, accesses, land use and which building slot/archetype belongs on a property;
3. **System 19** turns that already-chosen slot into physical local building/property detail;
4. WHAT + typed mechanic state own all later reality.

System 19 does not choose towns, roads, parcels, addresses, households, businesses as social/economic actors, population, runtime occupancy, weather, outbreak history, camera, streaming partitions or world-scale utilities.

A commercial archetype may own immediate inseparable property detail inside its supplied envelope, such as the accepted gas station's pump forecourt. That never gives System 19 ownership of the road or parcel network.

## 3. Stable public pipeline

Canonical flow:

`BuildingGenerationRequest -> LocalBuildingGenerator -> GeneratedBuildingPlan -> GeneratedBuildingValidator -> GeneratedBuildingMaterializer -> WHAT + CLOSED Door State`

### `BuildingGenerationRequest.gd`

Caller facts only:

- stable instance ID;
- archetype ID;
- seed;
- global bounding envelope;
- N/E/S/W orientation;
- caller-selected frontage.

### `GeneratedBuildingPlan.gd`

Pure semantic initial-state plan:

- bounding footprint;
- ground entries;
- structures/openings;
- props/fixtures;
- generation-only room-purpose regions;
- deterministic child roles/IDs;
- archetype version/seed/orientation/frontage provenance.

It contains no atlas indices, texture paths, renderer calls, UI state, runtime people or mutable gameplay ownership.

### `GeneratedBuildingValidator.gd`

Shared structural validator owns only generic correctness:

- valid generated plan/provenance;
- unique cells/roles where required;
- footprint containment;
- valid structure axes;
- one primary exterior door;
- no illegal structure/prop contradiction;
- no blocking prop on a doorway;
- valid room records;
- reachability from the primary entrance with doors conceptually passable.

It must **not** become a catalog of diner/house/store-specific room programs.

### `GeneratedBuildingMaterializer.gd`

Writes only validated initial world facts through public WHAT + Door State contracts. Generated doors begin CLOSED. If materialization fails part-way, it restores the prior state. After success, generation relinquishes ownership.

## 4. Read-only placement seam for System 20

### `BuildingArchetypePlacementDescriptor.gd`

System 20 must not copy sizes/frontage rules out of individual System 19 files.

`LocalBuildingGenerator.placement_descriptor(archetype_id)` therefore exposes a narrow read-only description derived through the archetype's own public generation behavior:

- archetype ID/version;
- canonical required size;
- canonical frontage;
- supported cardinal orientations;
- rotated required size;
- rotated frontage.

Legacy accepted generators remain untouched. The registry probes their own public contract to derive the descriptor and caches the result, so there is one source of truth rather than a second hand-maintained size table.

This descriptor exposes placement facts only. It does not expose rooms, furniture or generator internals.

## 5. Saved reference library

These examples are the golden regression/training set used to extract rules. Peer critique must not silently mutate them.

### Trailer v2 — accepted

`residential.trailer.singlewide`

- 5×12;
- compact living/kitchen + bath + bedroom;
- contiguous small kitchen work group;
- very little circulation waste.

### Small Farmhouse v2 — accepted

`residential.house.farm_small`

- 13×9;
- two bedrooms + bath;
- 11×3 open living/kitchen;
- private rooms directly behind one partition row;
- no inflated hallway band.

### Large Farmhouse v4 — preserved reference

`residential.house.farm_large`

- 21×9;
- separate living and kitchen;
- three bedrooms + two bathrooms;
- no dedicated hallway/corridor;
- doorless lower living/kitchen passage;
- clear kitchen runner;
- furniture clustered by function rather than stretched across open rooms.

### Compact Laundry House v1 — accepted

`residential.house.compact_laundry`

User acceptance: **“ok that looks perfect.”**

- 17×13 irregular occupied footprint;
- two bedrooms + one bath;
- separate kitchen;
- central living circulation;
- real 3×3 laundry/utility room;
- small entry bump;
- kitchen work run and local furniture clusters;
- open space intentionally left open.

### Small Gas Station v1 — accepted

`commercial.gas_station.small`

User acceptance: **“perfect.”**

- 19×15 property envelope;
- compact roadside convenience store, not a travel center;
- real sales floor, office, bathroom and storage room;
- rear storage/service exit;
- checkout/retail/cooler clusters;
- two pump islands / four pumps;
- clear customer route from forecourt to storefront.

The gas station is now a protected fifth reference rather than the active critique target.

## 6. Extracted hard-rule hierarchy

The examples do **not** imply universal exact dimensions or prop counts. A 3×3 bathroom, ten windows or thirty-three props can be correct for one archetype without becoming a law for every building.

Rules are separated into three levels.

### 6.1 Universal building-quality rules

These are the reusable lessons System 19 is hardening:

1. **Compact purposeful space.** Extra envelope area does not automatically inflate rooms.
2. **Circulation must have a reason.** Prefer useful room adjacency and shared public/common circulation over dedicated hallways when the program does not need a hall.
3. **Primary entry must make functional sense.** The player should enter a public/common/customer space, not teleport conceptually into a private/service room.
4. **Every required room is physically real and reachable.** A label on one undivided floor is not a room.
5. **Door approaches remain usable.** Reserve the doorway and immediate approach cells from blocking dressing.
6. **Service routes remain usable.** Storage/service exits and work lanes are protected from decorative filling.
7. **Functional objects cluster.** Related objects normally stay within roughly one or two cells rather than being distributed across a room to fill space.
8. **Work runs are contiguous where appropriate.** Kitchen appliances/counters and similar sequences should read as one usable work area.
9. **Open space is allowed.** Do not add props simply because a tile is empty.
10. **Room dressing has a density ceiling.** The current grammar rejects rooms where blocking dressing exceeds 45% of room cells; profiles may be stricter later.
11. **Frontage is physical truth.** Entrances/storefronts/service sides rotate with semantic building orientation.
12. **Same version + request + seed is deterministic.** Intentional same-seed rule changes bump the archetype/profile version.
13. **Different seeds should matter when a profile declares variants.** Variation changes legal spatial choices, not random decoration noise that breaks functional rules.

### 6.2 Profile-specific rules

A profile owns facts that are not universal:

- required/optional room purposes;
- room widths/depths or ranges;
- adjacency/order variants;
- whether a service room needs an exterior exit;
- window expectations;
- public-space type;
- wall/opening semantic themes;
- dressing families;
- canonical envelope/frontage;
- whether a dedicated hall is allowed/required;
- immediate archetype-owned exterior property detail.

The shared quality layer asks whether the declared program is satisfied. It must not decide that every building needs a bathroom, office, kitchen, bedroom or storage room.

### 6.3 Presentation-only art-facing rules

Recovered art currently makes table-like sprites in canonical NORTH layouts read correctly when authored SOUTH/WEST rather than NORTH. New grammar dressing therefore enforces SOUTH/WEST semantic facings for recovered table-like groups it owns.

This is **not architecture/physics truth**. System 07A remains the presentation owner for native sprite orientation. If art is replaced later, presentation metadata/rules may change without rewriting building topology.

## 7. Reusable hardening owners

### `grammar/BuildingGrammarProfile.gd`

Data contract for grammar-driven archetypes. Trial 001 supports the first layout strategy, `front_hub_back_strip`:

- one broad public/common front hub;
- compact service rooms across the rear;
- direct service-room doors into the hub;
- optional rear service exit;
- no dedicated hallway unless a future profile/strategy explicitly needs one.

Profiles may provide deterministic legal service-room order variants.

### `grammar/BuildingGrammarGenerator.gd`

Owns reusable topology for the selected strategy:

- envelope/frontage checks;
- room rectangle construction;
- separator/partition placement;
- primary and service opening placement;
- frontage/side/rear window grammar;
- reserved circulation cells;
- N/E/S/W transformation;
- final semantic plan assembly.

It does not know renderer art internals or gameplay state.

### `grammar/BuildingRoomDressingPlanner.gd`

Owns reusable functional dressing patterns rather than building identities.

Trial 001 hardens:

- restaurant booth/table clusters;
- small customer counter cluster;
- contiguous seven-cell kitchen work line;
- storage wall dressing with clear middle service lane;
- compact bathroom fixture cluster.

The planner refuses blocking props on reserved circulation cells.

### `grammar/BuildingGrammarQualityValidator.gd`

Second validation layer for generation quality/profile fulfillment. It is separate from `GeneratedBuildingValidator` so generic physical validity does not become coupled to content style.

Current checks include:

- declared rooms exist;
- forbidden hall/corridor purposes do not appear;
- reserved circulation remains clear;
- room blocking-prop density stays <=45%;
- kitchen work run remains contiguous when a kitchen exists;
- restaurant tables stay adjacent to booths for the restaurant dressing family;
- storage middle service lane remains clear when storage exists;
- bathroom contains its required basic fixtures when bathroom exists;
- grammar-owned table-like props obey the current recovered-art facing rule.

## 8. Hardening Trial 001 — Rural Roadside Diner

Archetype: `commercial.diner.rural_small`

Version: **1**

Canonical envelope: **17×11**, SOUTH frontage.

The archetype wrapper is intentionally thin. It delegates to `RuralDinerBuildingProfile.gd` + the shared grammar rather than owning a hand-written floor plan.

### Program

Public hub:

- `dining_room`: 15×5 = 75 cells, restaurant floor.

Rear service strip:

- `kitchen`: 7×3 = 21 cells;
- `storage`: 3×3 = 9 cells;
- `bathroom`: 3×3 = 9 cells;
- two one-cell separator walls between the service rooms.

No hall/corridor room exists.

### Seeded topology variation

The profile currently declares two legal service-room orderings:

- kitchen -> storage -> bathroom;
- bathroom -> kitchen -> storage.

Seed 19006 uses the first ordering. Seed 19007 uses the second. The storage rear service exit follows the storage room rather than remaining at a hard-coded coordinate.

This is the first proof that seed variation can change topology while the same quality rules continue to hold.

### Seed 19006 openings

Local canonical cells:

- primary SOUTH storefront door `(8,10)`;
- rear storage service door `(10,0)`;
- kitchen door `(4,4)`;
- storage door `(10,4)`;
- bathroom door `(14,4)`.

Total: **5 doors**.

Windows: **11** total — six storefront windows, two dining side windows, two kitchen rear windows and one bathroom rear window.

### Dressing

The diner emits **26 blocking props**, leaving most of the building open:

- four booth/table pairs;
- two counter segments + two nearby counter chairs;
- seven contiguous kitchen work-line pieces: refrigerator, counter, sink, counter, stove, counter, pantry;
- storage: two racks, pallet and tool cabinet with the middle service lane clear;
- bathroom: toilet, sink and towel rack.

The central customer aisle from the front door through the dining room is reserved clear.

### Live critique fixture

`RuralDinerCritiqueFixture.gd`:

- 19×13 lot;
- 28 px/cell;
- envelope `Rect2i(1,1,17,11)`;
- seed `19006`;
- NORTH orientation / SOUTH frontage;
- player `(9,12)` facing NORTH toward closed primary door `(9,11)` global;
- road on the south/bottom row;
- no NPCs or runtime content injected by System 19.

Canonical demo currently points at this fixture for playtest.

## 9. Registry

Current callable archetypes:

- `residential.trailer.singlewide`
- `residential.house.farm_small`
- `residential.house.farm_large`
- `residential.house.compact_laundry`
- `commercial.gas_station.small`
- `commercial.diner.rural_small`

The first five are saved references. The diner is hardening Trial 001 until the user accepts/rejects it.

## 10. Verification contract

The original `LocalBuildingGenerationSmoke.gd` continues protecting the saved reference behavior.

New `BuildingGrammarSmoke.gd` must prove:

1. all six callable archetypes expose valid placement facts;
2. the five saved generators retain their expected canonical size/frontage/version without editing their source;
3. diner v1 is deterministic for one seed;
4. diner room program is 75 dining / 21 kitchen / 9 storage / 9 bathroom cells;
5. no diner hall/corridor exists;
6. diner has 5 doors, 11 windows and 26 props;
7. primary/service/interior door cells match seed-19006 program;
8. kitchen work line is contiguous;
9. central customer aisle remains clear;
10. storage service lane remains clear;
11. booth/table clusters remain adjacent;
12. recovered table-facing rule remains satisfied;
13. seed 19007 produces a different valid topology/signature;
14. 32 consecutive seeds × all four cardinal orientations generate and pass the shared structural validator;
15. undersized envelopes and incompatible frontage fail explicitly;
16. critique fixture materializes into WHAT + CLOSED Door State;
17. collision and art coverage are complete;
18. System 18 automatic front-door Walk works;
19. renderer has zero planned diagnostics;
20. canonical demo boots on the diner fixture.

Exact-final-head Web/Pages validation remains required before Trial 001 is presented as successfully deployed.

## 11. Performance / mobile

- generation is bounded to one caller-supplied local envelope;
- no world scan, unbounded retry or per-frame generation;
- grammar/layout work is proportional to one small building;
- quality validation is proportional to local rooms/props;
- descriptor probing is cached and only uses public generation contracts;
- critique fixture remains one bounded mobile-friendly visible window;
- no hover dependency or desktop-only input is introduced.

## 12. Forbidden dependencies

Production code under `generation/buildings/` must not depend on:

- renderer nodes, textures, atlas coordinates or camera;
- player input/HUD;
- health/needs/skills;
- item/container gameplay actions;
- AI/population/outbreak behavior;
- future streaming implementation;
- world-scale road/parcel planner internals;
- runtime people/vehicles/occupancy.

Art remains presentation truth; generated semantic type/facing remains world truth.

Saved peer archetype generators do not import or mutate one another.

## 13. Trial process / finish condition

1. **Trial 001:** Rural Roadside Diner generated through the shared grammar. User playtests and critiques it.
2. If accepted, save it as another reference and make **Trial 002: another arbitrary building chosen without copying a previous exact layout**.
3. Trial 002 should preferably exercise either another profile arrangement or another reusable dressing family so it proves the grammar is not secretly diner-specific.
4. If Trial 002 is also accepted, promote the hardened grammar contract to the final System 19 implementation state.
5. Freeze the placement/profile/quality seams, leave future archetypes as profile/content additions, and move primary development to System 20 Local Area / Parcel Generation.

## 14. Approved decisions through 2026-08-20

1. System 19 owns local building/property generation, not global planning.
2. Caller supplies stable instance ID, archetype, seed, envelope, orientation and frontage.
3. Pure plan -> shared structural validation -> materialize initial WHAT + Door State -> relinquish ownership.
4. Room-purpose regions are generation/validation metadata, not persistent Room State.
5. Saved examples must not be mutated while extracting common rules.
6. Trailer v2 and Small Farmhouse v2 are accepted baselines.
7. Large Farmhouse v4 is a preserved compact/no-hall/clustering reference.
8. Compact Laundry House v1 is accepted after the user said it looked perfect.
9. Small Gas Station v1 is accepted after the user said “perfect.”
10. Exact dimensions/prop counts from one example are not universal laws.
11. Common hard rules are compact purposeful space, logical adjacency, minimal wasted circulation, clear door/service paths, functional clustering, contiguous work runs where appropriate and permission for open space to remain empty.
12. System 20 receives placement facts through a narrow System 19 descriptor rather than copying archetype internals.
13. Hardening should prove itself by generating arbitrary new buildings, not by manually authoring more exact examples.
14. The first arbitrary proof building is a rural roadside diner.
15. Two successful arbitrary grammar-generated buildings are the agreed finish condition before System 19 is finalized and primary work moves to System 20.
