# Tick Survival Lab — System 00F Streaming / Materialization Orchestration

Status: **IMPLEMENTED — SLICES 001–002**

Initial design/approval: 2026-08-22  
Slice 002 lifecycle promotion: 2026-08-23

## 1. Goal

System 00F turns the already-established logical world into **on-demand persistent local reality without allowing streaming partitions to define the world**.

The current architecture supplies:

- System 00D global geography, settlements/sites, roads, hydrology and regional infrastructure;
- System 20 local generation for all five settlement sites plus deterministic dry `rural.open` countryside;
- System 19 finalized building generation;
- `AreaMaterializationCoordinator` for transactional initial System 20 writes into WHAT + Door State;
- authoritative persistent WHAT state;
- separate WHEN and presentation owners.

Core rule:

> **Materialization is one-way; activation is reversible.**

Once a logical source is materialized into persistent state, generation relinquishes ownership. Moving away may make technical stream regions inactive, but it never regenerates, resets or erases the place merely because it left the active set.

## 2. Critical distinction: world, source, region, active state

### Logical world truth

System 00D / System 20 / System 19 decide generated initial facts. WHAT and typed mechanic state own current persistent reality after materialization.

### Logical materialization source

A source is a deterministic logical generation domain that may create virgin persistent facts once.

Current source kinds:

1. `system20_area_site` — one System 00D settlement `area_site`, projected through System 20 and written by the existing area materializer;
2. `system20_rural_open` — one catalog-v1 dry countryside fragment derived from System 00D geography and exact global exclusions, prepared through System 20C.

A source is **not** a streaming chunk.

### Technical stream region

A stream region is replaceable technical partition geometry used to decide what is near the current focus.

Changing region size/radius may change when a source is prefetched, but must not change:

- global/local generation;
- stable WHAT IDs;
- roads, parcels, buildings or countryside morphology;
- logical source keys;
- generated plan signatures;
- persistent player changes.

### Active region

An active region is currently inside 00F's detailed-use halo. Activation is ephemeral and reversible.

Active does not itself mean rendered, AI-simulated, populated, saved, newly generated or resident under a future eviction cache.

## 3. Slice 001 baseline

Slice 001 established:

1. configurable technical stream-region geometry;
2. deterministic focus -> active-region calculation;
3. discovery of settlement area-site sources intersecting active technical regions;
4. persistent in-memory materialization provenance/registry state;
5. atomic on-demand materialization through the real 00D -> 20 -> 19 -> WHAT/Door pipeline;
6. reversible active-region bookkeeping/signals;
7. strict no-regeneration behavior on revisit;
8. registry snapshot/restore;
9. exact rollback if materialization fails.

Slice 001 intentionally left arbitrary countryside source-free. That historical limitation is superseded for **dry countryside** by Slice 002. River corridor cells remain intentionally unsupported.

## 4. Slice 002 extension

Detailed design:

`SYSTEM_DESIGNS/00F2_COUNTRYSIDE_LOGICAL_SOURCE_MATERIALIZATION.md`

Slice 002 adds:

- `CountrysideSourceCatalog.gd` catalog v1;
- source kind `system20_rural_open`;
- geography-derived logical parentage independent from stream-grid geometry;
- exact settlement-site subtraction;
- exact unsupported-river-corridor subtraction;
- complete non-overlapping ownership of supported dry countryside;
- `CountrysideMaterializationSource.gd` using only public System 20C seams;
- uniform source handles across settlement/countryside source types;
- generic atomic `ensure_sources()` mixed-source transactions;
- dual-source discovery in `WorldStreamingCoordinator`;
- mixed source kinds in existing Materialization Registry schema v1;
- dedicated revisit/rollback/coverage verification.

00F still does **not** own countryside morphology. System 20C does.

## 5. Non-goals

System 00F does not own:

- global/local/building generation semantics;
- countryside morphology;
- local physical river/bridge generation;
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

## 6. Why inactive WHAT is not evicted

WHAT is the single authoritative current world.

Removing terrain/entities from WHAT merely because a stream region became inactive would currently be indistinguishable from destroying those facts. No persistence-backed inactive-region store exists yet to preserve authoritative truth elsewhere.

Therefore materialized persistent facts remain in WHAT when regions deactivate.

A future residency/eviction slice may remove cold data from hot memory only after an explicit backing-store contract makes non-residency invisible to gameplay meaning.

## 7. Implemented owners

Canonical code lives under `game/scripts/streaming/`.

### `StreamingRegionGrid.gd`

Pure technical partition geometry:

- configured from world bounds + injected region size;
- deterministic coordinate/bounds queries;
- clipped edge regions;
- invalid out-of-world lookup rather than clamping;
- no generation/WHAT/player/render/simulation ownership.

### `MaterializationRecord.gd`

Immutable-style provenance for one successful logical source:

- source key/kind/id;
- logical bounds + seed;
- area/environment profile IDs/versions;
- generated plan signature;
- WHAT revision after materialization;
- Door State revision after materialization.

### `MaterializationRegistry.gd`

Owns successful source provenance only:

- source lookup;
- sorted keys;
- duplicate-rejecting insert;
- deterministic schema-v1 snapshot/restore.

Schema v1 remains valid with both current source kinds.

### `AreaSiteMaterializationSource.gd`

Settlement-source adapter:

- stable `system20_area_site:<site_id>` keys;
- exact source-bound validation;
- technical-bound intersection discovery;
- uniform source handles;
- public `project_site()` + `LocalAreaGenerator` preparation only;
- no persistent mutation.

### `CountrysideSourceCatalog.gd`

Pure logical dry-countryside catalog:

- catalog version 1;
- source kind `system20_rural_open`;
- reads System 00D geography as parent lattice;
- subtracts exact settlement-source rectangles;
- subtracts exact currently unsupported river corridors;
- produces stable global-rectangle source IDs/keys;
- validates no overlap and exact supported-dry coverage;
- never calls System 20 or mutates WHAT.

### `CountrysideMaterializationSource.gd`

Countryside-source adapter:

- resolves catalog descriptors/handles;
- checks registry before generation;
- prepares only through `project_rural_open_bounds()` + `LocalAreaGenerator`;
- verifies exact rural-open identity/profile/bounds/seed;
- no persistent mutation.

### `WorldMaterializationCoordinator.gd`

Owns the cross-domain initial-write transaction.

Compatibility APIs:

- `ensure_area_site()`;
- `ensure_area_sites()`.

Generic API:

- `ensure_sources(global_plan, source_handles)`.

Mixed-source lifecycle:

1. validate plan/source catalogs/handles;
2. classify already-materialized keys before generation;
3. prepare all missing sources before persistent writes;
4. stable-sort by source key;
5. snapshot WHAT + Door State + registry once;
6. materialize each prepared plan through `AreaMaterializationCoordinator`;
7. record provenance after each successful area write;
8. rollback all three domains if any write/registry insert fails;
9. return ordered newly/already-materialized keys.

It does not inspect parcel/building/landscape internals.

### `WorldStreamingCoordinator.gd`

Owns ephemeral active technical-region state.

`update_focus(cell)`:

1. validates focus/grid/plan;
2. computes target technical region halo;
3. gets target region bounds;
4. discovers intersecting settlement handles;
5. discovers intersecting countryside handles;
6. stable-sorts them;
7. calls one atomic `ensure_sources()`;
8. commits focus/active bookkeeping only after materialization succeeds;
9. emits deterministic materialized and activated/deactivated notifications.

It consumes zero simulation ticks and imports no player/render/camera/AI/collision owner.

## 8. Technical profile

Current defaults remain:

- region size `Vector2i(256, 256)`;
- origin = `GeneratedGlobalWorldPlan.bounds.position`;
- active radius = 1 technical region using a square/Chebyshev neighborhood;
- edge regions clip to global bounds.

The current fixture happens to form a 7×7 technical lattice. **7×7 and 256×256 are not world identity.** Dedicated tests use a different region size while proving logical countryside source keys do not change.

## 9. Current logical-source profile

### Settlement sources

Source key:

`system20_area_site:<site_id>`

There are five current settlement sources: Crossroads, Small-Town and three hamlets.

### Dry countryside sources

Source kind:

`system20_rural_open`

Catalog version:

`1`

Identity derives from:

- catalog version;
- parent System 00D geography identity;
- final global dry rectangle.

It never derives from stream-region coordinates.

### Intentionally unsupported river corridor

Current physical river corridor cells have no logical materialization source. Dry land immediately beside those corridors remains countryside-source-owned.

Known water is therefore not replaced with grass and not widened into an unnecessary whole-geography hole.

## 10. Materialization/revisit invariants

Once a source key exists in the registry:

- ensure returns it as already materialized;
- System 20/System 19 are not rerun for it;
- terrain/entities are not reset;
- door state is not reset;
- later typed mechanic state is not reset;
- persistent revisions do not advance merely because the source re-enters the active halo.

Dedicated countryside regression removes a generated natural prop, deactivates the region and revisits; the prop remains removed.

## 11. Active-region invariants

Deactivation changes **only** technical active bookkeeping.

It does not:

- remove/unplace entities;
- clear terrain;
- unregister doors;
- mutate WHAT or Door State;
- consume ticks;
- tell renderer/camera/AI what to do.

If required materialization fails, prior focus/active state remains unchanged.

## 12. Source overlap / ownership rule

Current settlement and countryside sources both own full terrain inside their logical bounds. Positive overlap among current full-ground sources is therefore invalid.

00F verifies:

- settlement sources do not positively overlap each other;
- countryside sources do not positively overlap each other;
- countryside sources do not overlap settlement sources;
- countryside sources do not overlap unsupported river corridor cells.

Ownership ambiguity fails rather than relying on write order.

## 13. Registry persistence boundary

Registry schema v1 contains:

- schema version;
- registry revision;
- ordered materialization records.

Load validates into temporary state and swaps atomically.

This is technical provenance state, **not a user save format**. A future save/session owner must restore WHAT, typed mechanic stores and the Materialization Registry coherently.

The active-region set is ephemeral and recomputable.

## 14. Failure behavior

Explicit failures include:

- invalid/un-generated global plan;
- invalid stream grid/configuration;
- focus outside world bounds;
- malformed source catalog/handle;
- source overlap/coverage inconsistency;
- unknown source kind/id;
- projection/local-generation failure;
- stable entity-ID collision;
- malformed/conflicting registry state;
- any partial multi-source write attempt.

Failure never marks a source materialized.

A technical region containing only currently unsupported river corridor is valid and fabricates no terrain there.

## 15. Performance/mobile rules

- no per-frame generation loop;
- no per-frame countryside-catalog rebuild;
- source discovery uses the finite logical catalogs;
- callers update focus only when spatial focus changes or prefetch is explicitly desired;
- materialization remains synchronous because no approved worker contract exists;
- correctness/persistence ownership takes priority over premature eviction;
- WHEN/browser hard-pause semantics remain separate.

## 16. Verification

Workflow:

`.github/workflows/streaming-materialization.yml`

Exact-head context:

`verify/system00f-streaming-materialization`

Smokes:

- `game/scripts/ci/StreamingMaterializationSmoke.gd` — Slice 001 settlement/technical-region baseline;
- `game/scripts/ci/CountrysideStreamingMaterializationSmoke.gd` — Slice 002 catalog/mixed-source/countryside contract.

Slice 001 first fully green integrated code head:

`1841dc99e9f6731388dc9b730bb2959e38d575ba`

Slice 002 verified implementation head before documentation promotion:

`abe3d56792b74d5dd08882bd4f06dbd76107f35d`

Exact-head successes on the Slice 002 verified code head:

- `verify/system00d-global-world` — run `32655369800`;
- `verify/system00f-streaming-materialization` — run `32655369765`;
- `verify/system19-local-building` — run `32655369822`;
- `verify/system20-local-area` — run `32655369751`;
- `verify/system21-camera-view` — run `32655369771`;
- `verify/system22-area-critique` — run `32655369752`;
- `verify/pages-deploy` — run `32655369795`.

The final documentation-promotion head must independently pass those seven contexts before formal Slice 002 closure is claimed.

## 17. Protected neighbors

00F Slices 001–002 leave semantics unchanged in:

- System 00D v6 global planning/profile;
- System 19 building generation;
- all System 20 morphology/profile versions;
- existing `AreaMaterializationCoordinator` behavior;
- WHAT/WHEN foundation contracts;
- collision/movement/door mechanics;
- Art/render/camera/player/input/UI;
- System 22 live Crossroads critique target.

## 18. Future seams

### Local physical hydrology / bridges

Recommended next bounded architecture design. It must consume existing System 00D river segments/bridge intents and give currently source-free river corridor cells honest physical materialization without making 00F own hydrology morphology.

### Population / System 00E

00E may use active/residency information as one input to detailed-vs-coarse actor simulation. 00F does not own AI/outbreak resolution.

### Save / persistent storage

A future save/session owner can serialize WHAT + typed mechanic state + Materialization Registry.

### Real memory eviction

A later 00F residency slice may move persistent inactive data out of hot memory only behind an authoritative backing store.

### Sparse rural properties

Stable countryside logical ownership now exists, so a later System 20 content slice may add isolated rural properties without tying identity to technical stream boundaries.

### Presentation / prefetch

Renderers may consume active/resident bounds later, and vehicles may motivate different prefetch policy. Neither may redefine logical source identity.

## 19. Approved decisions

### Slice 001 — 2026-08-22

1. Logical materialization sources and technical stream regions are distinct identities.
2. Materialization is one-way for a world lifetime; revisit never regenerates persistent places.
3. Activation is reversible, ephemeral and non-destructive.
4. Slice 001 uses an injected 256×256 technical grid with radius-1 default, not as world identity.
5. Any active-region intersection with a virgin settlement site materializes the entire logical site rather than clipping it to stream boundaries.
6. Inactive materialized facts stay in authoritative WHAT until a persistence-backed eviction contract exists.
7. Slice 001 initially supported only the five System 00D area-site sources rather than faking countryside.
8. System 22 remains on the accepted Crossroads critique world while 00F is independently proven.

### Slice 002 — 2026-08-23

1. System 00D geography records are the logical parent lattice for dry countryside source identity.
2. Exact settlement area-site bounds are subtracted instead of dropping entire geography records.
3. Exact river corridors are subtracted, leaving only currently unsupported water cells source-free.
4. Each remaining dry rectangle is a catalog-v1 `system20_rural_open` source.
5. Source identity derives from catalog version + geography identity + global bounds, never stream coordinates.
6. Neighboring dry fragments are not merged in v1.
7. Settlement and countryside sources share one atomic mixed-source transaction while keeping separate adapters.
8. The 256×256 radius-1 technical configuration remains unchanged and non-authoritative.
9. Materialization Registry remains schema v1.
10. System 22/live presentation remains unchanged.

## 20. North-star fit

00F is the bridge from globally coherent generated places to a persistent open world while preserving the project's core promises:

- one continuous coordinate space;
- no raid-instance reality;
- no chunk-defined roads/utilities/parcels/countryside;
- persistent consequences on revisit;
- generation creates initial truth only;
- technical partitions remain replaceable implementation details;
- future population/outbreak simulation may scale detail by relevance without changing what exists;
- unfinished river cells stay honestly unfinished instead of becoming fake terrain.