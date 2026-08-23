# Tick Survival Lab — System 00F Slice 002 Countryside Logical Source Materialization

Status: **IMPLEMENTED**

Design date: 2026-08-23  
Lifecycle promotion approved: 2026-08-23

## 1. Goal

System 00F Slice 002 gives the already-implemented System 20C `rural.open` countryside a **stable logical materialization-source identity that is independent from technical streaming regions**.

Core rule:

> **Countryside source identity comes from logical global planning geometry, never from the stream grid.**

System 20C remains the owner of countryside morphology. Slice 002 only decides which stable logical dry-countryside sources exist, discovers them near the active technical halo, and materializes each virgin source exactly once through the existing public 00F transaction.

## 2. Prerequisite truth

The implementation consumes these already-canonical contracts:

- System 00D v6 owns global bounds, geography, settlements/sites, roads, river segments, bridge intents and regional infrastructure planning;
- System 20C `rural.open` v1 accepts arbitrary dry caller-bounded countryside inside the broad `rural_open` planning context;
- `project_rural_open_bounds()` rejects settlement overlap and any river/bridge intersection;
- rural-open landscape classification and natural prop identity use global seed + absolute global coordinates;
- split-vs-combined dry countryside requests produce identical cell-level landscape truth;
- System 00F Slice 001 owns technical stream activation, one-way materialization, registry provenance and exact rollback;
- WHAT remains the one authoritative current persistent world.

Slice 002 adds no second countryside generator.

## 3. Implemented scope

Slice 002 implements:

1. a deterministic logical countryside source catalog derived from System 00D planning truth;
2. stable countryside source IDs/versioning independent from technical stream-region coordinates or size;
3. exact exclusion of the five settlement area-site sources from countryside ownership;
4. exact exclusion of currently unsupported river corridor cells while preserving dry land immediately beside rivers;
5. a countryside materialization-source adapter that prepares each virgin source through `project_rural_open_bounds()` + `LocalAreaGenerator`;
6. a generic mixed-source materialization batch so settlement and countryside sources commit atomically together;
7. `WorldStreamingCoordinator` discovery of both current source kinds over the existing active technical regions;
8. exact no-regeneration behavior for countryside revisit;
9. persistent world mutations inside countryside surviving deactivation/revisit;
10. registry snapshot/restore containing both source kinds without schema ambiguity;
11. source-catalog validation proving dry countryside coverage has neither holes nor positive overlaps outside the intentionally unsupported river corridor;
12. no live System 22 presentation switch.

## 4. Non-goals

Slice 002 does not implement:

- new countryside morphology;
- new System 00D geography/settlement/road/infrastructure semantics;
- local physical rivers, bridges, water art/collision/traversal or flooding;
- sparse isolated rural properties;
- population/households/jobs/outbreak;
- AI activation/detail policy;
- save slots, file/browser persistence encoding or a backing store;
- true memory eviction;
- asynchronous/background workers;
- renderer/camera/UI changes;
- runtime utilities;
- changes to the live Rural Crossroads critique target.

The river corridor remains intentionally source-free until a separately approved local-hydrology/bridge slice can materialize it honestly.

## 5. Logical source model

### 5.1 Technical stream regions are not sources

Slice 001 currently defaults to 256×256 technical stream regions with radius 1. Those regions are replaceable activation geometry.

If countryside source IDs were derived from them, changing a performance setting would change registry keys and materialization history. Slice 002 therefore keeps logical source identity completely separate from the technical stream grid.

### 5.2 System 00D geography is the parent lattice

`CountrysideSourceCatalog` reads actual `GeneratedGlobalWorldPlan.geography_cells` as stable logical parent records.

Current canonical geography happens to use 128-cell records, but the catalog does not infer source identity from the 256 stream grid and does not hardcode the fixture dimensions.

A geography record is a parent planning cell, not necessarily one final countryside source.

## 6. Exclusion / fragmentation rule

Each geography parent is reduced deterministically by higher-priority or currently unsupported physical domains:

1. subtract positive overlap with every current System 00D `area_site` rectangle;
2. subtract positive overlap with every physical river corridor rectangle at the river segment's declared width;
3. discard zero-area pieces;
4. sort remaining dry rectangles deterministically.

Each remaining rectangle becomes one logical countryside source.

### Settlement exclusion

Settlement area sites already own full-ground source identity through:

`system20_area_site:<site_id>`

Countryside never positively overlaps those bounds. Exact site rectangles are subtracted rather than dropping an entire geography parent.

### River exclusion

System 20C still cannot materialize a request intersecting a real river/bridge fact. Slice 002 therefore excludes the exact river corridor rather than the entire geography parent containing it.

Dry land directly beside the river stays source-owned. The river corridor itself remains source-free/unmaterialized.

### Hydrology geometry seam

The catalog consumes System 00D hydrology through the read-only `GlobalHydrologyQuery` corridor geometry semantics. 00F does not redefine river width, routing or profile data.

## 7. `CountrysideSourceCatalog.gd`

Owner:

`game/scripts/streaming/CountrysideSourceCatalog.gd`

Responsibilities:

- derive all logical dry countryside sources from one generated global plan;
- subtract axis-aligned exclusions deterministically;
- never call System 20 or mutate WHAT;
- expose ordered source descriptors and intersection queries;
- validate source coverage/non-overlap;
- expose explicit catalog versioning.

Implemented constants:

- `CATALOG_VERSION = 1`;
- `SOURCE_KIND = &"system20_rural_open"`.

A valid catalog guarantees:

- every source stays inside one parent geography record;
- no countryside source overlaps another countryside source;
- no countryside source overlaps a settlement source;
- no countryside source overlaps the unsupported river corridor;
- every supported dry non-settlement/non-river cell belongs to exactly one countryside source.

Neighboring dry fragments are not merged in v1; simple stable identity is preferred over source-count minimization.

## 8. Source identity

Each descriptor carries:

- `source_kind = &"system20_rural_open"`;
- stable `source_id`;
- stable `source_key`;
- `catalog_version = 1`;
- parent geography ID/grid;
- global `bounds`;
- source seed = global world seed.

Source IDs use the `rural.open.v1...` namespace and source keys use:

`system20_rural_open:<source_id>`

Mandatory semantic rule:

> **Source identity is a deterministic function of logical catalog version + parent geography identity + final global rectangle, never technical stream-region coordinates.**

A future source-decomposition change is therefore a catalog-version/migration problem, not a silent refactor.

## 9. `CountrysideMaterializationSource.gd`

Owner:

`game/scripts/streaming/CountrysideMaterializationSource.gd`

It:

- resolves catalog descriptors/handles;
- validates the current global plan/catalog;
- rejects unknown or already-materialized sources;
- calls only public `project_rural_open_bounds()` + `LocalAreaGenerator.generate()` seams;
- verifies exact source ID/bounds/seed/profile/environment identity;
- returns prepared data without mutating WHAT.

No source reroll exists.

## 10. Uniform source-handle contract

Current 00F source handles carry:

- source kind;
- source ID;
- source key;
- logical bounds.

`AreaSiteMaterializationSource` exposes equivalent handles for settlement sites. Settlement and countryside adapters remain separate because their logical catalogs/preparation rules differ.

## 11. `WorldMaterializationCoordinator` mixed-source transaction

Existing convenience APIs remain:

- `ensure_area_site()`;
- `ensure_area_sites()`.

Generic seam:

`ensure_sources(global_plan, source_handles) -> Dictionary`

Behavior:

1. validate global plan and all configured source catalogs;
2. validate/deduplicate canonical handles by source key;
3. classify already-materialized sources before local generation;
4. prepare every missing source before writes;
5. stable-sort prepared sources by source key;
6. snapshot WHAT + Door State + Materialization Registry once;
7. materialize each prepared `GeneratedAreaPlan` through `AreaMaterializationCoordinator`;
8. append one `MaterializationRecord` only after each write succeeds;
9. roll all three snapshots back if any source write or registry insert fails;
10. return ordered newly/already-materialized source keys.

A batch containing settlement and countryside sources is atomic. The coordinator still knows no parcel/building/landscape internals.

## 12. Cross-source ownership rule

Both current source kinds write full terrain within their logical bounds. Therefore positive overlap between full-ground sources is an error rather than a write-order convention.

00F validates:

- settlement/settlement non-overlap;
- countryside/countryside non-overlap;
- countryside/settlement non-overlap;
- countryside/unsupported-river non-overlap.

## 13. `WorldStreamingCoordinator` integration

Technical defaults remain unchanged:

- 256×256 region size;
- radius-1 active square;
- edge clipping.

`update_focus(cell)` now:

1. validates focus/global plan/grid;
2. computes target active technical regions;
3. converts them to target bounds;
4. discovers intersecting settlement handles;
5. discovers intersecting countryside handles;
6. merges and stable-sorts them;
7. calls one atomic `ensure_sources()` batch;
8. commits focus/active state only if required materialization succeeds;
9. emits materialized notifications for newly committed sources;
10. emits deterministic activated/deactivated technical-region deltas.

Technical regions still never become persistent source IDs.

## 14. Revisit / persistence rule

After a countryside source key exists in the registry:

- revisiting does not rerun System 20C;
- terrain is not reset;
- natural props are not recreated;
- removed/moved/added persistent entities are not overwritten;
- later typed mechanic state is not reset;
- WHAT, Door State and registry revisions do not advance merely because the source becomes active again.

Dedicated CI removes a real generated countryside natural prop, deactivates the relevant technical region and revisits it. The prop stays removed and persistent revisions remain unchanged.

## 15. Registry compatibility

`MaterializationRegistry` remains snapshot schema **v1**.

Its generic source kind/key/id/provenance shape already supports the second source kind, so no schema bump was required.

Settlement and countryside records coexist and round-trip deterministically.

## 16. Coverage model

For current implemented physical domains, the broad rural-open context is partitioned conceptually into:

1. settlement area-site sources;
2. dry countryside sources;
3. intentionally unsupported river corridor cells.

This is a logical ownership guarantee, not eager startup materialization.

No source exists merely because a technical stream region exists.

## 17. Performance / mobile requirements

- no per-frame source-catalog rebuild;
- catalog is built per generated global plan and retained by composition;
- source intersection operates on the finite catalog rather than scanning the world cell-by-cell during ordinary focus updates;
- each countryside source remains within one geography parent;
- materialization is synchronous because no approved worker contract exists;
- current radius-1 activation remains unchanged;
- no WHEN ticks are consumed by materialization;
- Safari/browser lifecycle pause remains outside 00F.

If later profiling requires different prefetch policy, that may change **when** sources materialize, not source identity.

## 18. Failure behavior

Explicit failures include:

- invalid global plan/context/geography;
- malformed river geometry;
- rectangle-subtraction/coverage inconsistency;
- duplicate/conflicting source identity;
- countryside/countryside or countryside/settlement overlap;
- unknown source kind/source ID;
- System 20C projection/generation mismatch;
- mixed-source entity-ID collision;
- registry conflict;
- any partial mixed-source write attempt.

On materialization failure, active technical state stays unchanged and WHAT + Door State + registry restore exactly to their pre-batch snapshots.

## 19. Implemented surface

New owners:

- `game/scripts/streaming/CountrysideSourceCatalog.gd`;
- `game/scripts/streaming/CountrysideMaterializationSource.gd`;
- `game/scripts/ci/CountrysideStreamingMaterializationSmoke.gd`.

Narrow integration edits:

- `GlobalHydrologyQuery.gd` read-only corridor geometry seam;
- `AreaSiteMaterializationSource.gd` uniform source-handle seam;
- `WorldMaterializationCoordinator.gd` mixed-source routing/atomicity;
- `WorldStreamingCoordinator.gd` dual-source discovery;
- `.github/workflows/streaming-materialization.yml` dedicated coverage.

No System 20 profile version changed.

## 20. Protected neighbors

Implementation preserves semantics in:

- System 00D v6 planner/profile/signature;
- System 19 building generation;
- System 20C rural-open morphology/determinism;
- Crossroads/Small-Town/Rural-Scattered System 20 profiles;
- `AreaMaterializationCoordinator`;
- WHAT/WHEN;
- collision/movement/doors;
- Art/render/camera/player/input/UI;
- System 22 live critique composition.

## 21. Verification contract

Dedicated coverage proves:

1. System 00D canonical replay remains exact;
2. System 20C remains valid/unchanged;
3. countryside catalog determinism;
4. unique catalog-versioned source IDs/keys;
5. technical stream size does not affect source identity;
6. each source stays inside one geography parent;
7. no countryside overlap with countryside/settlement/river;
8. exact dry coverage;
9. dry land immediately beside rivers remains represented;
10. roadless countryside prepares without fake roads;
11. roadside countryside preserves inherited regional roads only;
12. settlement+countryside mixed batches commit in stable order;
13. all five settlement records coexist with countryside records;
14. registry schema v1 mixed-source snapshot/restore round-trips;
15. countryside revisit causes zero persistent writes;
16. removed natural props do not regenerate;
17. induced countryside ID collision rolls a mixed batch back exactly;
18. river corridor remains source-free/unmaterialized;
19. existing Slice 001 settlement behavior remains protected;
20. Systems 00D/19/20/21/22 and Pages remain green.

Verified implementation head before documentation promotion:

`abe3d56792b74d5dd08882bd4f06dbd76107f35d`

Exact-head successes on that SHA:

- `verify/system00d-global-world` — run `32655369800`;
- `verify/system00f-streaming-materialization` — run `32655369765`;
- `verify/system19-local-building` — run `32655369822`;
- `verify/system20-local-area` — run `32655369751`;
- `verify/system21-camera-view` — run `32655369771`;
- `verify/system22-area-critique` — run `32655369752`;
- `verify/pages-deploy` — run `32655369795`.

The final documentation-promotion head is separately required to pass the same seven exact-head gates before the lifecycle is formally closed.

## 22. Future seams

### Local hydrology / bridges

The next recommended bounded architecture design is physical local river/bridge materialization. The currently excluded river cells may require a new source kind or explicit catalog-version migration; Slice 002 does not pre-decide that model.

### Sparse rural properties

Isolated homes/farms can now be designed without tying their identity to technical stream boundaries because stable countryside source ownership exists.

### Population / System 00E

00E may assign people/households/activities to real physical places and use active-region information for simulation detail. 00F remains materialization/activation orchestration only.

### Save / backing store

A future save/session owner can serialize WHAT + typed domains + Materialization Registry. A later residency/eviction slice may then remove cold data from hot memory without making non-resident mean nonexistent.

### Prefetch policy

Vehicle speed or profiling may justify different prefetch policy later. It may change **when** a source materializes, never its ID/bounds.

## 23. North-star fit

Slice 002 closes the dry-countryside source-ownership gap between the five settlement sources and the intended continuous open world while preserving the core architecture:

- global planning owns physical coherence;
- System 20C owns countryside morphology;
- WHAT owns persistent current reality;
- 00F owns source materialization + technical activation;
- stream regions remain replaceable performance geometry;
- river cells remain honestly unfinished rather than faked;
- player changes survive because generation relinquishes ownership permanently after first materialization.

## 24. Approved decisions

Approved design decisions:

1. Use System 00D geography cells as the logical parent lattice for countryside source identity; do **not** use 00F technical stream regions.
2. Subtract exact settlement area-site bounds from each geography cell rather than dropping entire intersecting geography cells.
3. Subtract the exact physical river corridor at declared width, leaving only that corridor source-free until local hydrology exists.
4. Make each remaining dry rectangle a v1 `system20_rural_open` logical source with identity derived from catalog version + geography identity + global bounds.
5. Do not merge neighboring dry fragments in Slice 002; stable simple identity is more important than minimizing source count.
6. Generalize `WorldMaterializationCoordinator` to one atomic mixed-source transaction while preserving existing area-site convenience APIs.
7. Keep the existing 256×256 radius-1 technical stream configuration unchanged; source identity remains independent of it.
8. Keep `MaterializationRegistry` schema v1 because its generic record validation supports the new source kind.
9. Keep unsupported river cells genuinely unmaterialized rather than widening the missing area to whole geography cells or faking water/grass.
10. Keep System 22/live presentation unchanged in this slice.

## 25. Implementation result

The approved design is present in canonical source and its dedicated contract is green on the verified implementation head above. Integration refinements after the initial coding pass were bounded CI/performance/assertion corrections; they did not change the approved source-identity, ownership, mixed-transaction or persistence architecture.

System 00F Slice 002 is therefore **IMPLEMENTED**. Formal repository lifecycle closure is completed when this promoted document and the synchronized durable routing docs pass the seven exact-head repository gates.