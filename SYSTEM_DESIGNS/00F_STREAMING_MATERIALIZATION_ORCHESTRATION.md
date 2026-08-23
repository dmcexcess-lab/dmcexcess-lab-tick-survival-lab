# Tick Survival Lab — System 00F Streaming / Materialization Orchestration

Status: **DRAFT**

Date: 2026-08-22

## 1. Goal

System 00F turns the already-established logical world into **on-demand persistent local reality without allowing streaming partitions to define the world**.

The current architecture already has:

- System 00D global geography, settlements, major roads, hydrology and regional infrastructure;
- System 20 local-area generation for all five current settlement sites;
- System 19 finalized building generation;
- `AreaMaterializationCoordinator` for one transactional initial System 20 area write into WHAT + Door State;
- authoritative persistent WHAT state;
- deterministic WHEN state;
- bounded rendering/camera presentation.

00F should orchestrate those existing seams so the game can ask, "what detailed world needs to exist near this focus?" and materialize virgin logical places exactly once.

The core rule is:

> **Materialization is one-way; activation is reversible.**

Once a logical source has been materialized into persistent world state, generation relinquishes ownership. Moving away may make a technical stream region inactive, but it must never regenerate or erase the persistent place merely because it left the active set.

## 2. Critical distinction: world, source, region, active state

00F deliberately separates four concepts.

### Logical world truth

System 00D / System 20 / System 19 decide generated initial geography and local physical facts. WHAT and typed mechanic state own the current persistent reality after materialization.

### Logical materialization source

A materialization source is a deterministic logical generation domain that may create virgin persistent facts once.

Slice 001 supports one source type:

- `system20_area_site` — one current System 00D `area_site`, projected through System 20 and materialized through the existing `AreaMaterializationCoordinator`.

The five current sources are the Crossroads site, Small-Town site and three Rural-Scattered hamlet sites.

A source is **not a streaming chunk**.

### Technical stream region

A stream region is a replaceable technical partition used only to decide which part of the world is near the current focus.

Changing region size later must not:

- change global/local generation;
- change stable WHAT entity IDs;
- change roads, parcels or buildings;
- cause an already-materialized source to regenerate;
- invalidate persistent player changes.

### Active region

An active region is currently inside 00F's technical detailed-use halo. Activation is ephemeral and reversible.

Active does **not** automatically mean:

- rendered;
- fully simulated by AI;
- populated;
- saved to disk;
- newly generated;
- resident in a future eviction cache.

Those are separate system decisions.

## 3. Slice 001 scope

The first bounded 00F implementation should establish:

1. a configurable technical stream-region grid over one existing global world plan;
2. deterministic focus-cell -> active-region calculation;
3. discovery of current System 00D area-site materialization sources intersecting the active technical regions;
4. a persistent-in-memory materialization registry recording which logical sources have already been created;
5. atomic on-demand materialization of previously virgin area sites through the existing public 00D -> System 20 -> System 19 -> WHAT/Door State pipeline;
6. reversible active-region bookkeeping and notifications;
7. exact no-regeneration behavior on revisit;
8. snapshot/restore of the materialization registry for future save orchestration;
9. no live System 22 presentation switch in this slice.

Slice 001 is a real orchestration system, but it is **not yet memory eviction** and it is **not yet full open-countryside traversal**.

The current System 00D world has broad rural-open planning truth between settlement sites, but no System 20 local materialization profile for arbitrary countryside windows. 00F must not fabricate one. A technical active region with no current materialization source simply causes no new local WHAT facts to be generated.

## 4. Non-goals

Slice 001 does not implement:

- a new global or local generator;
- arbitrary countryside/local-open generation;
- population, households, jobs, outbreak actors or coarse simulation;
- player movement across unloaded space;
- AI activation/deactivation;
- render-window ownership, camera behavior or art;
- collision/traversal rule ownership;
- WHEN scheduling or simulation-resolution policy;
- save-file encoding, browser storage or save slots;
- memory eviction of persistent terrain/entities;
- deleting/unplacing world facts merely because a region becomes inactive;
- runtime power/water/wastewater mechanics;
- background asynchronous jobs or fake worker-thread behavior;
- changes to System 00D, System 19 or System 20 generation semantics;
- changes to the live System 22 critique target.

## 5. Why Slice 001 does not evict WHAT

WHAT is explicitly the single authoritative persistent current world.

Removing terrain/entities from WHAT because a stream region deactivated would be indistinguishable from destroying those facts unless another persistence-backed authoritative storage contract existed. That would create a second world truth and violate the implemented 00B contract.

Therefore Slice 001 keeps all materialized persistent facts in WHAT even when their technical region becomes inactive.

A future 00F eviction/residency slice is allowed only after an explicit storage/persistence contract can preserve authoritative inactive-region truth without teaching gameplay systems that "not resident" means "does not exist."

## 6. Owner modules

Proposed canonical source lives under `game/scripts/streaming/`.

### `StreamingRegionGrid.gd`

Pure technical partition geometry only.

Responsibilities:

- map a global cell to a zero-based technical region coordinate relative to supplied world bounds;
- return clipped bounds for a region coordinate;
- enumerate valid region coordinates around a focus region;
- remain deterministic for negative/non-zero global world origins;
- contain no generation, WHAT, player, renderer or simulation behavior.

### `MaterializationRecord.gd`

Immutable-style record describing one successfully materialized logical source.

Proposed fields:

- `source_key`;
- `source_kind`;
- `source_id`;
- global `bounds`;
- source seed;
- area profile ID/version;
- environment profile ID/version;
- deterministic generated-area plan signature;
- WHAT revision immediately after materialization;
- Door State revision immediately after materialization.

The record is audit/provenance state. It does not own the materialized world facts.

### `MaterializationRegistry.gd`

Owns only the set of logical sources that have successfully materialized in this world session/state.

Responsibilities:

- query whether a source is already materialized;
- atomically insert a validated record once;
- reject duplicate/conflicting source keys;
- deterministic ordered reads;
- snapshot/load_snapshot with an explicit schema version;
- no file I/O;
- no generation;
- no WHAT mutation.

### `AreaSiteMaterializationSource.gd`

Read-only adapter from current global world planning to existing local generation.

Responsibilities:

- derive stable source keys for `GeneratedGlobalWorldPlan.area_sites`;
- find area sites whose logical bounds intersect supplied technical stream-region bounds;
- validate that the current site-backed full-ground sources do not overlap each other;
- prepare an unmaterialized source by calling only public seams:
  - `System20AreaRequestProjector.project_site()`;
  - `LocalAreaGenerator.generate()`;
- return the request, generated plan and provenance required for materialization;
- never mutate WHAT.

It must check the registry **before** local generation is invoked. Revisiting a materialized source must not rerun System 20 merely for convenience.

### `WorldMaterializationCoordinator.gd`

Owns the cross-domain **initial materialization transaction**, not generation semantics.

Responsibilities:

- accept one or more logical area-site source IDs;
- deduplicate and sort them deterministically;
- ignore already-materialized sources without regenerating them;
- prepare every missing source before persistent writes begin;
- snapshot WHAT, Door State and Materialization Registry before the write phase;
- delegate each actual area write to existing `AreaMaterializationCoordinator`;
- append the matching Materialization Record only after that source succeeds;
- roll back WHAT + Door State + registry to the pre-batch snapshots if any requested source fails;
- return explicit success/failure + newly materialized/already-materialized keys.

This owner does not know parcel/building internals.

### `WorldStreamingCoordinator.gd`

Owns ephemeral active technical-region state.

Responsibilities:

- receive an already-generated global world plan and injected 00F collaborators;
- accept an explicit global focus cell from its caller;
- compute the target active technical region set;
- discover logical area-site sources intersecting those regions;
- request atomic materialization of missing sources;
- change active-region state only after required materialization succeeds;
- expose active region coordinates/bounds and `is_cell_active()`;
- emit bounded activation/deactivation/materialization notifications;
- consume zero WHEN ticks.

It does not import player, renderer, camera or AI owners. A future composition layer may pass the player's current/anticipated cell to it.

## 7. Public contract

Proposed default technical profile for Slice 001:

- stream region size: `Vector2i(256, 256)`;
- grid origin: `GeneratedGlobalWorldPlan.bounds.position`;
- active radius: 1 region using a Chebyshev/square neighborhood;
- edge regions clipped to global world bounds.

Both region size and active radius are **technical injected configuration**, not generated-world identity.

The current v6 fixture happens to be 1792×1792, so the default 256-cell grid produces a 7×7 technical region lattice. This is a test/runtime convenience only; nothing in System 00D or System 20 may depend on 7×7.

Suggested APIs:

### `StreamingRegionGrid`

- `is_valid()`;
- `region_coord_for_cell(cell) -> Vector2i`;
- `region_bounds(coord) -> Rect2i`;
- `regions_around(coord, radius) -> Array[Vector2i]`;
- `region_coords_for_bounds(bounds) -> Array[Vector2i]`.

Invalid/out-of-world cells must fail explicitly rather than clamp to a different physical place.

### `MaterializationRegistry`

- `has_source(source_key) -> bool`;
- `record(source_key) -> MaterializationRecord`;
- `source_keys() -> Array[String]`;
- `mark_materialized(record) -> bool`;
- `snapshot() -> Dictionary`;
- `load_snapshot(snapshot) -> bool`.

### `AreaSiteMaterializationSource`

- `source_key_for_site(site_id) -> String`;
- `site_ids_intersecting(global_plan, bounds_list) -> Array[String]`;
- `prepare(global_plan, site_id) -> Dictionary`.

Prepared result contains at minimum:

- `ok` / `failure_reason`;
- source key/kind/id;
- site bounds + seed;
- `AreaGenerationRequest`;
- `GeneratedAreaPlan`;
- deterministic plan signature/provenance.

### `WorldMaterializationCoordinator`

- `ensure_area_site(global_plan, site_id) -> Dictionary`;
- `ensure_area_sites(global_plan, site_ids) -> Dictionary`.

Result contains:

- `ok` / `failure_reason`;
- `newly_materialized` ordered source keys;
- `already_materialized` ordered source keys.

### `WorldStreamingCoordinator`

- `update_focus(cell) -> Dictionary`;
- `active_region_coords() -> Array[Vector2i]`;
- `active_region_bounds() -> Array[Rect2i]`;
- `is_cell_active(cell) -> bool`;
- `focus_cell()` / `focus_region_coord()` after first successful update.

Signals may include:

- `active_regions_changed(activated, deactivated)`;
- `source_materialized(source_key, source_id, bounds)`.

## 8. Technical region geometry rules

1. Technical region coordinates are zero-based relative to current global world bounds, not global cell coordinates disguised as IDs.
2. Region boundaries do not alter road/river/utility/property geometry.
3. A logical area site may intersect one or several technical regions.
4. If any active technical region intersects a virgin logical area site, 00F materializes the **entire logical site once** through its existing System 20 contract.
5. 00F never clips/replans a System 20 site to fit a technical stream boundary.
6. Different region sizes may change when a site is prefetched/activated, but cannot change the site's generated signature or persistent IDs.
7. Active-region order and source-materialization order are deterministic (row-major regions, stable source-key ordering).

## 9. Materialization lifecycle

For `ensure_area_sites()`:

1. validate global plan and requested site IDs;
2. derive source keys without generating local plans;
3. split requested sources into already-materialized and missing;
4. return already-materialized sources without calling System 20;
5. prepare every missing source through the public projector + generator;
6. validate all proposed Materialization Records before persistent writes;
7. snapshot current WHAT, Door State and Materialization Registry;
8. materialize each prepared source in stable source-key order via `AreaMaterializationCoordinator`;
9. append its Materialization Record only after its materialization succeeds;
10. if any write or record insertion fails, restore all three snapshots and report failure;
11. on success, generation relinquishes ownership permanently for those source keys.

There is no reroll loop and no "repair by regenerating the area."

## 10. Revisit / persistence rule

After a source key is in the registry:

- `ensure_*` returns it as already materialized;
- System 20 is not called;
- System 19 is not called;
- terrain is not reset;
- destroyed/created/moved entities are not replaced;
- door state is not reset to CLOSED;
- later typed mechanic state is not reset;
- WHAT revision does not change merely because the source is revisited.

This is the primary persistence contract 00F must prove.

A player-opened door that leaves the active region and later returns must still be open unless a real simulation mechanic changed it in the meantime.

## 11. Active-region lifecycle

`WorldStreamingCoordinator.update_focus(cell)`:

1. rejects focus outside global world bounds;
2. resolves the focus technical region;
3. computes the configured active neighborhood;
4. discovers all current area-site sources intersecting that neighborhood;
5. asks `WorldMaterializationCoordinator` to ensure those sources;
6. if required materialization fails, leaves previous focus/active-region state unchanged;
7. if successful, commits the new focus + active set;
8. emits deterministic activated/deactivated deltas.

Deactivation changes **only active technical bookkeeping** in Slice 001.

It does not remove entities, clear terrain, unregister doors, or change simulation ticks.

## 12. Data ownership and dependencies

00F may read:

- `GeneratedGlobalWorldPlan` / area-site metadata;
- existing System 20 projector/generator contracts through the area-site source adapter;
- WHAT and Door State snapshots/revisions through their public APIs;
- supplied focus cells.

00F may mutate:

- its own Materialization Registry;
- its own active-region state;
- initial virgin WHAT + Door State only by delegating to the existing System 20 materializer.

00F must not directly mutate:

- System 00D plan records;
- System 20 generated plans;
- System 19 building plans;
- player state;
- collision/traversal catalogs;
- renderer/camera/UI;
- WHEN;
- population/AI;
- save files.

Forbidden dependencies include reboot runtime and presentation internals.

## 13. Failure / edge behavior

Slice 001 must fail explicitly for:

- invalid/un-generated global plan;
- invalid stream-grid configuration;
- focus outside world bounds;
- unknown area site;
- unsupported System 20 profile;
- projected/local-generation failure;
- overlapping current full-ground materialization source bounds;
- materialization ID collision;
- malformed registry snapshot;
- conflicting duplicate Materialization Record;
- any partial multi-source materialization attempt.

Failure may never be hidden by silently marking a source materialized.

A technical active region containing no current logical materialization source is **not an error**. It simply creates no new detailed local world in Slice 001.

## 14. Performance / mobile requirements

- No per-frame generation or streaming recomputation.
- Callers should update focus only when the relevant global cell/technical region changes or when explicit prefetch is desired.
- Active region/source queries are bounded by the finite technical neighborhood and current source catalog.
- The active-radius default of one region gives a 3×3 lookahead neighborhood in the interior, allowing future composition to materialize nearby places before a boundary crossing.
- Materialization is currently synchronous because the project has no approved background-worker contract. Do not fake asynchronous completion.
- Existing System 20 full-area materialization may be expensive; Slice 001 establishes correct ownership first. Incremental/batched materialization requires a separately approved performance contract if profiling proves necessary.
- Safari/mobile lifecycle pause semantics remain owned by WHEN/app lifecycle; 00F does not advance simulation while materializing.

## 15. Registry snapshot boundary

The Materialization Registry snapshot is a small deterministic technical-state snapshot, not a user save file.

Schema v1 should contain:

- schema version;
- registry revision;
- ordered materialization records.

Loading validates into temporary state first and swaps atomically.

A future save/session owner must restore WHAT + typed mechanic stores + Materialization Registry coherently. 00F itself does not choose disk/browser encoding or save-slot policy.

The ephemeral active-region set does not need to be save-critical; it can be recomputed from the controlled actor/focus after restore.

## 16. Acceptance / tests for Slice 001

Add dedicated `StreamingMaterializationSmoke.gd` and exact-head context `verify/system00f-streaming-materialization`.

The smoke should prove at minimum:

1. the current System 00D v6 world generates before 00F consumes it;
2. default 256-cell technical grid maps the current 1792×1792 fixture to 7×7 regions without changing global truth;
3. region lookup works at world origin, corners, interior boundaries and non-zero global coordinates;
4. radius-1 active neighborhoods are deterministic and correctly clipped at world edges;
5. all five current area sites remain logical source IDs independent of technical region coordinates;
6. current site-backed full-ground source bounds are non-overlapping;
7. focusing near the Crossroads materializes it through the real 00D -> 20 -> 19 -> WHAT/Door State pipeline;
8. registry records profile/environment versions + deterministic plan signature + revisions;
9. repeating the same focus does not rerun materialization and leaves WHAT/Door revisions unchanged;
10. moving focus away deactivates technical regions without clearing the Crossroads from WHAT;
11. changing a real Crossroads door to OPEN, moving away, and revisiting does not reset it to CLOSED;
12. sequential focus updates can materialize Small-Town and all three hamlets into the same authoritative WHAT without stable-ID collision;
13. all five registry records coexist and repeated ensures leave WHAT/Door revisions unchanged;
14. registry snapshot/restore round-trips deterministically;
15. a deliberately induced future-site entity-ID collision causes materialization failure with WHAT/Door/registry restored to the exact pre-attempt snapshots;
16. a focus outside world bounds fails without active-state or persistent-state mutation;
17. an active region with no current area-site source creates no fake countryside terrain/entities;
18. System 00D v6 signatures and all three System 20 profile regressions remain unchanged;
19. protected System 19, System 21 and System 22 gates remain green;
20. no live Web presentation target changes in Slice 001.

## 17. Future seams

Once Slice 001 is proven, later designs may attach without rewriting its core distinction.

### Full rural/open-world local materialization

A future System 20 rural-open profile or other logical local source can provide detailed countryside between the five current settlement sites. 00F then discovers that source; it does not invent the morphology itself.

### Population / System 00E

00E may use 00F active-region information as one input to choose detailed vs coarse actor simulation. 00F must not decide AI/outbreak resolution itself.

### Save / persistent storage

A future save/session owner can serialize WHAT, typed mechanic domains and Materialization Registry.

### Real memory eviction / residency

A later explicit design may allow persistent inactive world facts to leave hot memory only if an authoritative backing-store contract makes that invisible to gameplay meaning. Stream deactivation alone never means destruction.

### Rendering

Renderers/System 22 may later consume active/resident bounds, but presentation never owns materialization truth.

### Prefetch policy

Future composition may choose focus/prefetch cells based on player velocity, vehicles, camera or teleport destinations without changing the stream grid or materialization registry semantics.

## 18. North-star fit

This system is the bridge from globally coherent generated places to one persistent open world.

It preserves the game's central promises:

- one continuous coordinate space;
- no raid-instance reality;
- no chunk-defined roads or utilities;
- persistent consequences on revisit;
- generation creates initial truth only;
- technical partitions are replaceable implementation details;
- future population/outbreak simulation can scale detail by relevance without changing who or what exists.

## 19. Expected implementation surface after approval

Expected new files:

- `game/scripts/streaming/StreamingRegionGrid.gd`;
- `game/scripts/streaming/MaterializationRecord.gd`;
- `game/scripts/streaming/MaterializationRegistry.gd`;
- `game/scripts/streaming/AreaSiteMaterializationSource.gd`;
- `game/scripts/streaming/WorldMaterializationCoordinator.gd`;
- `game/scripts/streaming/WorldStreamingCoordinator.gd`;
- `game/scripts/ci/StreamingMaterializationSmoke.gd`;
- `.github/workflows/streaming-materialization.yml`.

Narrow documentation/status updates:

- `SYSTEM_DESIGNS/README.md`;
- `README_CONTEXT.md`;
- `CHANGELOG.md` after successful implementation;
- `DESIGN_DECISIONS.md` only if the user approves the explicit materialization-vs-activation distinction as a cross-system rule.

Protected source expected to remain unchanged unless implementation reveals an approved-contract bug:

- System 00D planner/profile/version;
- System 19 generation;
- System 20 generation profiles/semantics;
- `AreaMaterializationCoordinator.gd` behavior;
- WHAT/WHEN foundation contracts;
- collision/movement/doors mechanics;
- Art/render/camera/player/input/UI;
- System 22 live critique runtime.

## 20. Proposed decisions requiring approval

1. Distinguish logical materialization sources from technical stream regions.
2. Make materialization one-way for a world lifetime; revisit never regenerates persistent places.
3. Make activation reversible/ephemeral and non-destructive.
4. Use a configurable technical 256×256 region grid with radius-1 default for Slice 001; this configuration is not world identity.
5. Materialize an entire logical System 20 area site when any active technical region intersects it; never clip/replan the site to the stream grid.
6. Keep materialized inactive facts in authoritative WHAT for Slice 001; defer true memory eviction until a persistence-backed contract exists.
7. Support only the five real current System 00D area sites as materialization sources in Slice 001; do not fake arbitrary countryside.
8. Keep the live System 22 world unchanged while proving 00F independently against the real five-site global/local pipeline.
