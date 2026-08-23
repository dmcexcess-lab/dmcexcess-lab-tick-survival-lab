# Tick Survival Lab — System 00F Streaming / Materialization Orchestration

Status: **IMPLEMENTED — SLICE 001**

Date: 2026-08-22

Approval: user explicitly approved Slice 001 on 2026-08-22 after reviewing the DRAFT contract.

## 1. Goal

System 00F turns the already-established logical world into **on-demand persistent local reality without allowing streaming partitions to define the world**.

The current architecture already supplies:

- System 00D global geography, settlements/sites, major roads, hydrology and regional infrastructure;
- System 20 local-area generation for all five current settlement sites;
- System 19 finalized building generation;
- `AreaMaterializationCoordinator` for one transactional initial System 20 area write into WHAT + Door State;
- authoritative persistent WHAT state;
- deterministic WHEN state;
- separate render/camera presentation.

The core 00F rule is:

> **Materialization is one-way; activation is reversible.**

Once a logical source is materialized into persistent state, generation relinquishes ownership. Moving away may make technical stream regions inactive, but it never regenerates, resets or erases that place merely because it left the active set.

## 2. Critical distinction: world, source, region, active state

### Logical world truth

System 00D / System 20 / System 19 decide generated initial facts. WHAT and typed mechanic state own current persistent reality after materialization.

### Logical materialization source

A source is a deterministic logical generation domain that may create virgin persistent facts once.

Slice 001 supports:

- `system20_area_site` — one current System 00D `area_site`, projected through System 20 and written by the existing area materializer.

The five current sources are the Crossroads, Small-Town and three Rural-Scattered hamlet sites.

A source is **not** a streaming chunk.

### Technical stream region

A stream region is replaceable technical partition geometry used to decide what is near the current focus.

Changing region size may change when a source is prefetched, but must not change:

- global/local generation;
- stable WHAT IDs;
- roads, parcels or buildings;
- source keys;
- a generated plan signature;
- persistent player changes.

### Active region

An active region is currently inside 00F's technical detailed-use halo. Activation is ephemeral and reversible.

Active does not itself mean rendered, AI-simulated, populated, saved, generated or memory-resident under a future eviction cache. Those remain separate decisions.

## 3. Slice 001 implemented scope

Slice 001 implements:

1. configurable technical stream-region geometry over an existing global plan;
2. deterministic focus-cell -> active-region calculation;
3. discovery of current System 00D area-site sources intersecting active technical regions;
4. persistent-in-memory materialization provenance/registry state;
5. atomic on-demand materialization of virgin area sites through the real 00D -> 20 -> 19 -> WHAT/Door State pipeline;
6. reversible active-region bookkeeping/signals;
7. strict no-regeneration behavior on revisit;
8. registry snapshot/restore for a future save/session owner;
9. exact rollback of multi-domain state if materialization fails.

Slice 001 deliberately does **not** implement memory eviction or arbitrary open-countryside materialization.

The current System 00D world has broad rural-open planning truth between settlement sites, but no arbitrary countryside System 20 local source. A source-free active region therefore creates nothing rather than fabricating terrain or content.

## 4. Non-goals

00F Slice 001 does not own:

- global/local/building generation semantics;
- arbitrary countryside generation;
- population, households, jobs, outbreak or coarse simulation;
- player movement;
- AI detail policy;
- renderer, render-window, camera, art or UI;
- collision/traversal catalogs;
- WHEN scheduling;
- save-file/browser-storage encoding or save slots;
- true memory eviction;
- runtime electricity/water/wastewater mechanics;
- asynchronous worker behavior;
- live System 22 presentation selection.

## 5. Why inactive WHAT is not evicted

WHAT is the single authoritative current world.

Removing terrain/entities from WHAT merely because a stream region became inactive would currently be indistinguishable from destroying those facts. No persistence-backed inactive-region store exists yet to preserve authoritative truth elsewhere.

Therefore Slice 001 leaves all successfully materialized persistent facts in WHAT when regions deactivate.

A future residency/eviction slice may remove cold data from hot memory only after an explicit backing-store contract makes non-residency invisible to gameplay meaning.

## 6. Implemented owners

Canonical code lives under `game/scripts/streaming/`.

### `StreamingRegionGrid.gd`

Pure technical partition geometry.

Public behavior:

- constructed from global world bounds + injected region size;
- zero-based region coordinates relative to supplied world bounds;
- `region_coord_for_cell(cell)`;
- `region_bounds(coord)` with clipped edge regions;
- `regions_around(coord, radius)` in deterministic row-major order;
- `region_coords_for_bounds(bounds)`;
- explicit invalid result for out-of-world cells rather than clamping.

It imports no generation, WHAT, player, renderer or simulation owner.

### `MaterializationRecord.gd`

Immutable-style provenance record for one successful logical source.

Fields:

- source key/kind/id;
- global source bounds + seed;
- area profile ID/version;
- environment profile ID/version;
- deterministic generated-area plan signature;
- WHAT revision immediately after materialization;
- Door State revision immediately after materialization.

It supports validation, copy/equivalence and primitive snapshot encoding.

### `MaterializationRegistry.gd`

Owns only successful source provenance.

Public behavior:

- `has_source()`;
- copy-returning `record()`;
- sorted `source_keys()`;
- duplicate-rejecting `mark_materialized()`;
- schema-v1 deterministic `snapshot()` / atomic `load_snapshot()`.

It performs no generation, WHAT mutation or file I/O.

### `AreaSiteMaterializationSource.gd`

Read-only adapter from current System 00D sites to current System 20 local generation.

Responsibilities:

- stable `system20_area_site:<site_id>` source keys;
- validate that current full-ground area-site source bounds are inside the world and do not positively overlap;
- discover sites whose logical bounds intersect supplied technical bounds;
- check registry before local generation;
- call only public `System20AreaRequestProjector.project_site()` + `LocalAreaGenerator.generate()` seams;
- return request/plan/provenance without mutating persistent state.

### `WorldMaterializationCoordinator.gd`

Owns the cross-domain initial-write transaction.

`ensure_area_site()` / `ensure_area_sites()`:

1. validate global plan and current source-bound contract;
2. validate/deduplicate requested site IDs and derive stable source keys without local generation;
3. classify already-materialized keys and skip them without calling System 20;
4. prepare all missing sources before persistent writes;
5. snapshot WHAT, Door State and Materialization Registry;
6. materialize prepared sources in stable source-key order through existing `AreaMaterializationCoordinator`;
7. construct/validate/insert each final provenance record only after its area write succeeds, using the actual resulting WHAT/Door revisions;
8. on any area-write or registry failure, restore all three pre-batch snapshots exactly;
9. report ordered newly/already-materialized keys.

It does not inspect parcel/building internals.

### `WorldStreamingCoordinator.gd`

Owns ephemeral active technical-region state.

`update_focus(cell)`:

1. rejects focus outside global bounds;
2. resolves the focus technical region;
3. computes the configured active square/Chebyshev neighborhood;
4. discovers current area-site sources intersecting those technical bounds;
5. atomically ensures missing sources;
6. changes focus/active bookkeeping only after materialization succeeds;
7. emits deterministic source-materialized and activated/deactivated notifications.

Reads:

- explicit caller-supplied global focus cell;
- current generated global plan;
- injected grid/materialization/source collaborators.

It imports no player, renderer, camera, AI, collision or WHEN owner and consumes zero simulation ticks.

## 7. Technical profile

Slice 001 defaults:

- region size `Vector2i(256, 256)`;
- origin = `GeneratedGlobalWorldPlan.bounds.position`;
- active radius = 1 technical region using a square/Chebyshev neighborhood;
- edge regions clip to global bounds.

The current 1792×1792 fixture therefore happens to form 7×7 technical regions. **7×7 is not world identity.** A test also uses a different technical size while proving logical source identity does not change.

## 8. Materialization/revisit invariants

Once a source key exists in the registry:

- ensure returns it as already materialized;
- System 20 is not called again;
- System 19 is not rerun through area materialization;
- terrain/entities are not reset;
- door state is not reset to CLOSED;
- later typed mechanic state is not reset;
- WHAT/Door/registry revisions do not advance merely because the player revisits.

A real generated Crossroads door changed to OPEN remains OPEN after its region deactivates and later reactivates unless an actual mechanic changes it.

## 9. Active-region invariants

Deactivation in Slice 001 changes **only** technical active bookkeeping.

It does not:

- remove/unplace entities;
- clear terrain;
- unregister doors;
- mutate WHAT or Door State;
- consume ticks;
- tell render/camera/AI what to do.

If required materialization fails, the previous focus and active set remain unchanged.

## 10. Source overlap rule

Current `system20_area_site` sources materialize full ground across their logical bounds. Slice 001 therefore validates that these five source rectangles do not positively overlap before writes.

This is a source-contract safety rule, not a general statement that future logical materialization sources can never overlap. A future source type with explicit ownership/merge semantics requires its own approved contract.

## 11. Registry persistence boundary

Registry schema v1 contains:

- schema version;
- registry revision;
- ordered materialization records.

Load validates into temporary state first and swaps atomically.

This is technical provenance state, **not a user save format**. A future save/session owner must restore WHAT, typed mechanic stores and Materialization Registry coherently.

The active-region set is ephemeral and can be recomputed after restore from the caller's focus.

## 12. Failure behavior

Explicit failures include:

- invalid/un-generated global plan;
- invalid stream grid/configuration;
- focus outside world bounds;
- unknown site;
- projection/local-generation failure;
- overlapping current full-ground source bounds;
- stable entity-ID collision;
- malformed/conflicting registry state;
- any partial multi-source write attempt.

Failure never marks a source materialized.

A technical active region with no logical materialization source is valid and performs no fake world creation.

## 13. Performance/mobile rules

- No per-frame generation loop exists.
- Callers should update focus only when relevant spatial focus changes or explicit prefetch is desired.
- Source discovery is bounded by active technical regions and the finite source catalog.
- Materialization remains synchronous because no approved worker/background contract exists.
- Correct persistence ownership takes priority over premature eviction optimization.
- WHEN/browser hard-pause semantics remain separate.

## 14. Verification

Dedicated smoke:

`game/scripts/ci/StreamingMaterializationSmoke.gd`

Workflow:

`.github/workflows/streaming-materialization.yml`

Exact-head context:

`verify/system00f-streaming-materialization`

The smoke proves:

1. System 00D v6 deterministic truth remains unchanged;
2. Crossroads Candidate 006 projected/generated semantic signature remains exact;
3. default 256-cell grid gives the current fixture a technical 7×7 lattice;
4. origin/corners/interior boundaries/out-of-world lookup behave correctly;
5. negative/non-zero origins and clipped final regions work;
6. all five sites have unique logical source keys independent of stream size;
7. current full-ground source bounds do not overlap;
8. Crossroads materializes through the real public pipeline on focus;
9. provenance records profile/environment versions, area signature and persistent revisions;
10. repeated focus performs no persistent writes;
11. a real generated Crossroads door changed to OPEN survives deactivation and revisit with no regeneration revision changes;
12. a deliberately installed future-site entity-ID collision causes failure and exact rollback of WHAT, Door State and registry;
13. all five current sites can coexist in one authoritative WHAT and registry;
14. repeated all-site ensure performs no writes;
15. registry snapshot/restore round-trips exactly;
16. out-of-world focus leaves active and persistent state unchanged;
17. a source-free active technical region creates no countryside terrain/entities;
18. protected System 00D/19/20/21/22 and Pages gates remain green.

First fully green integrated code head:

`1841dc99e9f6731388dc9b730bb2959e38d575ba`

00F run:

`32621475876`

All exact-head contexts on that code head succeeded:

- `verify/system00d-global-world`;
- `verify/system00f-streaming-materialization`;
- `verify/system19-local-building`;
- `verify/system20-local-area`;
- `verify/system21-camera-view`;
- `verify/system22-area-critique`;
- `verify/pages-deploy`.

## 15. Protected neighbors

Slice 001 leaves unchanged:

- System 00D profile/version/plan semantics;
- System 19 generation;
- all System 20 area morphology/contracts;
- existing `AreaMaterializationCoordinator` behavior;
- WHAT/WHEN foundation contracts;
- collision/movement/door mechanics;
- Art/render/camera/player/input/UI;
- System 22 live Crossroads critique target.

## 16. Future seams

### Full countryside materialization

A future logical rural-open/countryside source should supply detailed world between current settlement sites. 00F should discover/consume that source rather than define its morphology.

### Population / System 00E

00E may use active/residency information as an input to detailed-vs-coarse actor simulation. 00F does not own AI/outbreak resolution.

### Save / persistent storage

A future save/session owner can serialize WHAT + typed mechanic state + Materialization Registry.

### Real memory eviction

A later 00F residency slice may move persistent inactive data out of hot memory only behind an authoritative backing store.

### Presentation

Renderers may eventually consume active/resident bounds, but presentation never owns source/materialization truth.

### Prefetch

Future composition may choose focus/prefetch cells using player movement, vehicles, teleport destinations or other semantic intent without changing source identity or stream-grid rules.

## 17. Approved decisions

Approved by the user on 2026-08-22:

1. logical materialization sources and technical stream regions are distinct identities;
2. materialization is one-way for a world lifetime; revisit never regenerates persistent places;
3. activation is reversible, ephemeral and non-destructive;
4. Slice 001 uses an injected 256×256 technical grid with radius-1 default, not as world identity;
5. any active-region intersection with a virgin current area site materializes the entire logical site rather than clipping it to stream boundaries;
6. inactive materialized facts stay in authoritative WHAT until a persistence-backed eviction contract exists;
7. Slice 001 supports only the five real current System 00D area-site sources and does not fake arbitrary countryside;
8. System 22 remains on the accepted Crossroads critique world while 00F is independently proven.

## 18. North-star fit

00F is the bridge from globally coherent generated places to a persistent open world while preserving the project's core promises:

- one continuous coordinate space;
- no raid-instance reality;
- no chunk-defined roads/utilities/parcels;
- persistent consequences on revisit;
- generation creates initial truth only;
- technical partitions remain replaceable implementation details;
- future population/outbreak simulation may scale detail by relevance without changing what exists.
