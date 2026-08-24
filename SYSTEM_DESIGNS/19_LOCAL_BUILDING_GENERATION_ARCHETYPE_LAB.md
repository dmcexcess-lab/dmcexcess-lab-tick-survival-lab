# Tick Survival Lab — System 19 Local Building Generation / Building Grammar

Status: **IMPLEMENTED — FINALIZED**

Date: 2026-08-20; baseline profile library expanded 2026-08-23.

System 19 is the canonical local physical-building owner between higher-level parcel planning and persistent WHAT.

On 2026-08-20 the user explicitly finalized the system after accepting the grammar behavior and Rural Diner v2, superseding the earlier provisional requirement to build a second arbitrary proof building before finalization. New building profiles are ordinary content work after finalization unless the stable grammar/placement contract itself proves insufficient.

## 1. Goal

Given a caller-selected building/property slot, stable instance namespace, archetype/profile, seed, global envelope, orientation and frontage, produce a believable deterministic physical building plan that can be validated and materialized into persistent world state.

Adding a future barn, store, church, warehouse, house or other building should normally be **profile/content work**, not a rewrite of the building-generation architecture.

## 2. Architectural position

Canonical hierarchy:

1. future Global World Planning owns geography, settlement placement and cross-region infrastructure;
2. System 20 Local Area / Parcel Generation owns local roads, parcels, access, land use and building-slot selection;
3. **System 19** turns an already-chosen slot into physical local building/property detail;
4. WHAT + typed mechanic state own all later reality.

System 19 does not choose towns, roads, parcels, addresses, population, households, social/economic businesses, runtime occupancy, weather, outbreak history, camera or streaming partitions.

## 3. Stable public pipeline

`BuildingGenerationRequest -> LocalBuildingGenerator -> GeneratedBuildingPlan -> GeneratedBuildingValidator -> GeneratedBuildingMaterializer -> WHAT + CLOSED Door State`

### `BuildingGenerationRequest`
Caller-owned facts only:

- stable instance ID;
- archetype ID;
- seed;
- global bounding envelope;
- N/E/S/W orientation;
- caller-selected frontage.

### `GeneratedBuildingPlan`
Pure semantic initial-state plan:

- bounding footprint;
- ground entries;
- walls/openings;
- props/fixtures;
- generation-only room-purpose regions;
- deterministic child roles/IDs;
- archetype version/seed/orientation/frontage provenance.

No textures, atlas indices, renderer calls, UI state or runtime actors are stored here.

### `GeneratedBuildingValidator`
Owns generic physical correctness only:

- valid provenance;
- unique stable roles/cells where required;
- footprint containment;
- structure-axis correctness;
- exactly one designated primary exterior door for caller placement/access anchoring;
- additional explicit exterior doors where a multi-unit program requires independent access;
- no illegal structure/prop contradiction;
- no blocking prop in doorways;
- valid room records;
- conceptual reachability of every room from at least one legitimate exterior entrance.

Building-type-specific quality remains outside this generic validator.

### `GeneratedBuildingMaterializer`
Writes only validated initial facts through public WHAT + Door State contracts. Generated doors start CLOSED. Failed materialization restores prior state. After success, generation relinquishes ownership.

## 4. System 20 placement seam

`BuildingArchetypePlacementDescriptor` is the frozen read-only placement contract for higher-level planners.

`LocalBuildingGenerator.placement_descriptor(archetype_id)` exposes:

- archetype ID/version;
- canonical required size;
- canonical frontage;
- supported cardinal orientations;
- rotated required size;
- rotated frontage.

The descriptor exposes placement facts only. System 20 must not inspect room/furniture internals or maintain a duplicate size/frontage table.

## 5. Protected reference library

These examples produced and validated the final grammar rules:

- `residential.trailer.singlewide` v2 — accepted;
- `residential.house.farm_small` v2 — accepted;
- `residential.house.farm_large` v4 — preserved compact/no-hall reference;
- `residential.house.compact_laundry` v1 — accepted after “ok that looks perfect”;
- `commercial.gas_station.small` v1 — accepted after “perfect”;
- `commercial.diner.rural_small` v2 — accepted grammar proof after the user called the first version “very good” and requested additional tables.

These six are protected regression references. New profiles do not silently mutate them.

## 6. Baseline one-story profile library

On 2026-08-23 the callable library expanded with **18 profile-driven one-story buildings**, bringing the registered System 19 library to **24 archetypes total** while preserving the six protected references.

Canonical baseline rule:

> **Density and complexity are horizontal. A city building becomes more useful through rooms, units, adjacency and access—not through fake upper floors.**

All 18 new profiles declare `story_count = 1`, support all four cardinal rotations, use real room-purpose regions and pass the shared structural validator. Ordinary houses avoid hallway filler; corridors are used only where the program actually needs shared circulation, such as civic/office/school layouts.

Residential/lodging baseline:

- `residential.house.suburban_small`;
- `residential.house.suburban_family`;
- `residential.townhomes.row3`;
- `residential.multiunit.row4`;
- `lodging.motel.roadside`.

The baseline deliberately does **not** invent a multi-story hotel/apartment abstraction. “Hotel” density is represented as a roadside motel with individual room entrances; denser residential use is represented by horizontal townhomes or one-story multi-unit buildings with independent exterior unit access.

Commercial baseline:

- `commercial.convenience_store.small`;
- `commercial.grocery.neighborhood`;
- `commercial.pharmacy.small`;
- `commercial.hardware_store.small`;
- `commercial.office.small`.

Civic baseline:

- `civic.clinic.small`;
- `civic.police_station.small`;
- `civic.fire_station.small`;
- `civic.school.elementary_small`;
- `civic.church.small`.

Industrial/agricultural baseline:

- `industrial.warehouse.small`;
- `industrial.workshop.small`;
- `agricultural.barn.medium`.

`OneStoryBaselineProfileCatalog.gd` owns these content declarations. `OneStoryProfileBuildingGenerator.gd` owns their common one-story shell/room/opening/rotation materialization rules rather than duplicating eighteen generator implementations.

A reusable circulation invariant was added during verification: **every door-adjacent room approach is reserved from blocking dressing**. A profile may describe a blocking furnishing there, but the common generator does not materialize it in that reserved approach cell. This prevents furniture placement from invalidating an otherwise realistic floor plan and keeps circulation policy in the grammar owner rather than profile-by-profile patches.

## 7. Final building-quality grammar

Exact dimensions and prop counts from one example are **not** universal laws.

The final reusable rules are:

1. **Compact purposeful space.** Extra envelope area does not automatically inflate rooms.
2. **Circulation must have a reason.** Prefer useful adjacency/shared common circulation over unnecessary hallway bands.
3. **Primary entry must make functional sense.** Enter a public/common/customer space when the program calls for one.
4. **Every required room is real and reachable.** A room label on one undivided floor is not sufficient.
5. **Door approaches remain usable.** Door cells and immediate approaches are protected from blocking dressing.
6. **Service/work routes remain usable.** Storage/service exits and work lanes remain clear.
7. **Functional objects cluster locally.** Related furniture/fixtures normally remain within roughly one or two cells.
8. **Work runs are contiguous where appropriate.** Kitchens and similar work sequences read as usable groups.
9. **Open space is valid output.** Empty cells do not need filler.
10. **Blocking dressing is bounded.** Shared grammar currently rejects rooms above a 45% blocking-prop ratio.
11. **Frontage is physical truth.** Entrance/storefront/service sides rotate with semantic orientation.
12. **Same version + request + seed is deterministic.** Same-seed rule changes require version bumps.
13. **Seed variation must be meaningful and legal.** Profiles may alter topology/ordering without breaking functional rules.
14. **Profile-specific requirements stay profile-specific.** A bathroom, office, kitchen, storage room, etc. is required only when that profile declares it.
15. **Horizontal multi-unit access is real access.** Separate units may own separate exterior doors; one designated primary door remains the higher-level placement anchor.
16. **Art-facing quirks are presentation constraints, not architecture.** Current recovered table sprites use SOUTH/WEST facing choices where needed; System 07A remains the presentation owner.

## 8. Reusable grammar owners

### `grammar/BuildingGrammarProfile.gd`
Declares a building program: canonical envelope/frontage, room purposes, sizes/ranges, topology strategy, service requirements, semantic themes, dressing families and deterministic legal variants.

### `grammar/BuildingGrammarGenerator.gd`
Owns reusable topology/layout strategies, including envelope/frontage checks, room construction, partitions/openings/windows, reserved circulation and N/E/S/W transformation.

### `grammar/BuildingRoomDressingPlanner.gd`
Owns reusable functional dressing families rather than individual building identities. It protects reserved circulation.

### `grammar/BuildingGrammarQualityValidator.gd`
Owns profile-aware quality checks separately from generic structural validity: required program fulfillment, circulation clearance, density ceilings, local clustering, work-run continuity and other declared quality rules.

### `grammar/OneStoryProfileBuildingGenerator.gd`
Owns the broad baseline one-story profile materialization path: rooms/floors, shell and interior wall cells, explicit doors, automatic legal windows, rotation and door-approach circulation reservation.

Thin archetype wrappers/profile files provide content instead of duplicating layout algorithms.

## 9. Rural Diner grammar proof

`commercial.diner.rural_small` v2 is the accepted first shared-grammar proof.

Canonical envelope: **17×11**, SOUTH frontage.

Program:

- 15×5 dining/public hub;
- 7×3 kitchen;
- 3×3 storage with rear service exit;
- 3×3 bathroom;
- no dedicated hall/corridor;
- 5 doors;
- 11 windows;
- 30 purposeful props.

Dressing:

- six booth/table pairs;
- compact customer counter group;
- contiguous seven-cell kitchen run;
- wall-hugging storage with protected service lane;
- compact bathroom group;
- central customer aisle remains clear.

Four legal seeded back-of-house arrangements are available. The storage service exit follows the storage room rather than a fixed coordinate.

`BuildingGrammarSmoke.gd` exercises 32 consecutive diner seeds across all four rotations in addition to deterministic replay, frontage/envelope failures, materialization, collision/art coverage, door traversal and renderer diagnostics.

## 10. DEV critique control

`BuildingGrammarDevControls.gd` + `BuildingGrammarDevSeedSession.gd` are explicit DEV tooling.

`NEW BUILDING` advances the current critique seed and reloads through the normal request -> generation -> validation -> materialization path. It does not rewrite a live persistent world in place and is not normal survival/world-generation behavior.

## 11. Current callable registry

Protected reference archetypes:

- `residential.trailer.singlewide`;
- `residential.house.farm_small`;
- `residential.house.farm_large`;
- `residential.house.compact_laundry`;
- `commercial.gas_station.small`;
- `commercial.diner.rural_small`.

Baseline profile archetypes are the 18 entries listed in Section 6. Total callable library: **24**.

Additional profiles may be registered later when world/area content needs them. Doing so does not reopen System 19 unless the stable placement/profile/quality contracts themselves prove insufficient.

## 12. Frozen boundaries

Production `generation/buildings/` must not depend on:

- renderer nodes/textures/atlas coordinates/camera;
- player input/HUD;
- health/needs/skills;
- inventory/loot gameplay;
- AI/population/outbreak;
- streaming implementation;
- world-scale road/parcel planner internals;
- runtime people/vehicles.

Art is presentation truth, not physics.

## 13. Verification contract

System 19 remains protected by:

- `LocalBuildingGenerationSmoke.gd` for all six protected references plus the 18-profile baseline library across all cardinal rotations, deterministic replay, shared validation, multi-unit exterior-access rules and art-semantic coverage;
- `BuildingGrammarSmoke.gd` for descriptors, grammar quality, deterministic variation and the diner proof;
- System 18 integration checks;
- canonical startup/Web deployment checks.

Intentional output changes to a saved archetype/profile require the appropriate version bump and updated focused regression expectations.

The first exact executable head where the expanded 24-archetype library and the baseline System 20 integration were simultaneously green was `2e7a6e0da27a02f8058a3a79538cd9cb55a48cef`.

Exact-head context: `verify/system19-local-building`.

## 14. Final approved decisions

1. System 19 owns local building/property generation only.
2. Caller supplies instance ID, archetype, seed, envelope, orientation and frontage.
3. Pure plan -> structural validation -> initial materialization -> relinquish ownership.
4. Room-purpose data is generation/validation metadata, not persistent Room State.
5. Building examples are protected regression references.
6. Common grammar prioritizes compact purpose, meaningful adjacency, clear circulation, local clustering, contiguous work areas and deliberate open space.
7. Higher-level planners consume only the read-only placement descriptor plus normal public generation requests.
8. New building profiles are content work by default.
9. System 19 was explicitly finalized by the user on 2026-08-20; the earlier second-arbitrary-building gate is superseded.
10. Baseline urban density remains one-story and horizontal until a separately approved vertical-space model exists.