# Tick Survival Lab — System 00F Slice 002 Countryside Logical Source Materialization

Status: **DRAFT**

Design date: 2026-08-23

## 1. Goal

System 00F Slice 002 gives the already-implemented System 20C `rural.open` countryside a **stable logical materialization-source identity that is independent from technical streaming regions**.

The core rule is:

> **Countryside source identity comes from logical global planning geometry, never from the stream grid.**

System 20C already guarantees that dry countryside terrain and natural props are stable under split-vs-combined local bounds. Slice 002 uses that seam to define persistent logical countryside sources, discover them near the current focus, and materialize them through the existing 00F transaction without moving morphology into streaming.

## 2. Current prerequisite truth

This design assumes the following implemented contracts remain authoritative:

- System 00D v6 owns global world bounds, 128-cell geography records, settlements/sites, roads, river segments, bridge intents and regional infrastructure planning;
- System 20C `rural.open` v1 accepts arbitrary dry caller-bounded countryside inside the broad `rural_open` planning context;
- `project_rural_open_bounds()` rejects settlement overlap and any river/bridge intersection;
- rural-open landscape classification and natural prop identity use global seed + absolute global coordinates;
- rural-open natural IDs are independent from request/source ID;
- split-vs-combined dry countryside requests produce identical cell-level landscape truth;
- System 00F Slice 001 owns technical stream activation, one-way materialization, registry provenance and exact rollback;
- WHAT remains the one authoritative current persistent world.

Slice 002 therefore does **not** need another countryside generator.

## 3. Scope

Slice 002 should implement:

1. a deterministic logical countryside source catalog derived from System 00D planning truth;
2. stable countryside source IDs/versioning independent from technical stream-region coordinates or size;
3. exact exclusion of the five settlement area-site sources from countryside ownership;
4. exact exclusion of currently unsupported river corridor cells while preserving dry land immediately beside rivers;
5. a countryside materialization-source adapter that prepares each virgin source through `project_rural_open_bounds()` + `LocalAreaGenerator`;
6. a generic mixed-source materialization batch so settlement and countryside sources can be committed atomically together;
7. WorldStreamingCoordinator discovery of both current source kinds over the existing active technical regions;
8. exact no-regeneration behavior for countryside revisit;
9. persistent player/world mutations inside countryside surviving deactivation/revisit;
10. registry snapshot/restore containing both source kinds without schema ambiguity;
11. source-catalog validation proving dry countryside coverage has neither holes nor positive overlaps, except the intentionally unsupported river corridor;
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
- player cross-world traversal wiring;
- renderer/camera/UI changes;
- runtime utilities;
- changes to the live Rural Crossroads critique target.

The river corridor remains intentionally source-free until a separately approved local-hydrology slice can materialize it honestly.

## 5. Logical source model

### 5.1 Why the technical stream grid cannot own countryside sources

00F Slice 001 currently defaults to 256×256 technical stream regions with radius 1.

Those regions are explicitly replaceable implementation geometry. If countryside source IDs were simply derived from those regions, changing stream size would:

- change registry keys;
- change materialization history;
- risk rematerializing existing physical land;
- make persistence depend on a performance setting;
- violate the approved `materialization source != stream region` rule.

Therefore Slice 002 must introduce separate logical source geometry.

### 5.2 Logical base lattice: System 00D geography cells

Candidate Slice 002 uses the existing System 00D geography records as the stable coarse logical starting cells.

Current canonical geography is a 128-cell lattice, but Slice 002 must read actual `GeneratedGlobalWorldPlan.geography_cells`; it must not hardcode a 14×14 fixture or infer cells from the 256 stream grid.

Why geography is the right base seam:

- it is already global planning truth;
- records have stable IDs and global bounds;
- they exist before streaming;
- System 20C already consumes clipped geography;
- they are small enough to bound synchronous materialization work;
- using them does not make geography cells technical stream chunks.

A geography cell is the **parent logical planning cell**, not necessarily one final countryside source.

## 6. Exclusion / fragmentation rule

Each geography-cell rectangle is deterministically reduced by currently higher-priority or unsupported physical domains.

Subtractions occur in this order:

1. positive overlap with every current System 00D `area_site` rectangle;
2. positive overlap with every physical river corridor rectangle at the river segment's declared width;
3. discard zero-area pieces;
4. sort remaining dry rectangles deterministically.

Each remaining rectangle becomes one logical countryside source.

### 6.1 Settlement exclusion

Settlement area sites already have logical source ownership through:

`system20_area_site:<site_id>`

Countryside may never positively overlap those source bounds.

This remains true even when a settlement site cuts through the middle or edge of one geography record. The source catalog subtracts the exact site rectangle rather than dropping the entire geography cell.

This prevents large accidental countryside holes around settlements.

### 6.2 River exclusion

System 20C currently cannot materialize any request intersecting a real river/bridge fact.

Slice 002 therefore subtracts the **exact physical river corridor**, not the entire geography cell containing the river.

Dry land directly beside the river remains eligible countryside.

The river corridor itself remains source-free and unmaterialized. A road approaching/crossing the river may therefore materialize up to the dry edge and stop at the unsupported corridor until local hydrology/bridge materialization is implemented.

This is honest incompleteness, not fake grass over known water.

### 6.3 Corridor geometry ownership

00F must not invent a second interpretation of river width.

Implementation should expose a small public pure query from `GlobalHydrologyQuery`, such as:

`segment_corridor_rect(segment, clearance := 0) -> Rect2i`

using the same width/radius semantics already used by `rect_clear_of_rivers()`.

This is a read-only query seam only. It does not change System 00D plan data, profile version, river routing or signatures.

## 7. Rectangle subtraction contract

New pure owner:

`game/scripts/streaming/CountrysideSourceCatalog.gd`

Responsibilities:

- derive all logical dry countryside sources from one generated global plan;
- subtract axis-aligned exclusion rectangles from one geography cell deterministically;
- never call System 20 or mutate WHAT;
- expose ordered source descriptors and intersection queries;
- validate source coverage/non-overlap;
- expose a source-catalog schema/version constant.

Rectangle subtraction must:

- preserve every dry cell exactly once;
- create no positive overlap among resulting fragments;
- create no fragment outside its parent geography cell;
- create no fragment overlapping a settlement site or river corridor;
- remain deterministic independent of input-array iteration order.

The implementation may split a rectangle into multiple pieces as exclusions pass through it. It should not merge neighboring fragments merely to reduce source count in Slice 002; merging introduces unnecessary neighbor-dependent identity rules.

## 8. Source identity

New source kind:

`system20_rural_open`

Catalog version:

`1`

Each logical countryside source descriptor includes at minimum:

- `source_kind = &"system20_rural_open"`;
- stable `source_id`;
- stable `source_key`;
- `catalog_version = 1`;
- parent geography ID/grid;
- global `bounds`;
- source seed = current global world seed.

Proposed stable source ID shape:

`rural.open.v1.g<gx>.<gy>.x<x>.y<y>.w<w>.h<h>`

Source key:

`system20_rural_open:<source_id>`

The exact string format may be adjusted during implementation for safe formatting, but the following semantic rule is mandatory:

> Source identity is a deterministic function of the logical catalog version, parent geography identity and final global rectangle — never stream-region coordinates.

Changing technical stream size/radius therefore cannot change countryside keys.

A future change to countryside source decomposition is a **catalog-version migration problem**, not a silent refactor. Existing worlds may already contain registry records keyed to v1 sources.

## 9. Countryside source adapter

New owner:

`game/scripts/streaming/CountrysideMaterializationSource.gd`

Responsibilities:

- hold/inject `MaterializationRegistry`, `CountrysideSourceCatalog`, `System20AreaRequestProjector` and `LocalAreaGenerator`;
- query stable countryside source descriptors intersecting supplied bounds;
- reject unknown/malformed source IDs;
- check the registry before generation;
- prepare a virgin source only through public System 20C seams;
- never mutate WHAT.

Preparation lifecycle:

1. resolve source descriptor from catalog;
2. derive source key and reject already-materialized source;
3. call `project_rural_open_bounds(global_plan, source_id, bounds)`;
4. validate the request is `rural.open + temperate.rural`, uses global seed and exact source bounds;
5. generate through `LocalAreaGenerator.generate()`;
6. validate generated identity/bounds/seed/profile;
7. return the same prepared-result shape already used by 00F Slice 001.

No source reroll exists.

## 10. Uniform source-handle contract

Slice 002 introduces one small 00F-internal/public orchestration shape so the transaction can handle both current source kinds consistently.

A source handle contains:

- source kind;
- source ID;
- source key;
- logical bounds.

`AreaSiteMaterializationSource` should expose equivalent source-handle discovery for settlement sites while preserving its current convenience methods.

The two source adapters remain separate owners because they have different logical catalogs and preparation rules.

## 11. WorldMaterializationCoordinator revision

`WorldMaterializationCoordinator` remains the owner of the persistent cross-domain initial-write transaction.

Slice 002 should preserve:

- `ensure_area_site()`;
- `ensure_area_sites()`;

for compatibility, but implement them through a more general mixed-source path.

New/extended public seam:

`ensure_sources(global_plan, source_handles) -> Dictionary`

Behavior:

1. validate the generated global plan;
2. validate all registered full-ground source catalogs;
3. validate/deduplicate source handles by source key;
4. route each handle to the matching source adapter;
5. classify already-materialized sources before any local generation;
6. prepare every missing source before writes;
7. sort prepared entries by stable source key;
8. snapshot WHAT + Door State + Materialization Registry once;
9. materialize each prepared `GeneratedAreaPlan` through the existing `AreaMaterializationCoordinator`;
10. append a `MaterializationRecord` only after each write succeeds;
11. roll all three snapshots back if any source write or registry insert fails;
12. return ordered newly/already-materialized source keys.

A batch containing both settlement and countryside sources is therefore atomic.

The coordinator does not learn parcel/building/landscape internals.

## 12. Cross-source overlap validation

Both current source kinds write full terrain within their logical bounds.

Before materialization, 00F must be able to prove:

- settlement sources do not positively overlap each other;
- countryside sources do not positively overlap each other;
- countryside sources do not positively overlap settlement sources;
- countryside sources do not overlap unsupported river corridor cells.

A mixed full-ground source overlap is an error even if current terrain writes would technically overwrite the same semantic ground. Ownership ambiguity must fail instead of relying on write order.

## 13. WorldStreamingCoordinator revision

`WorldStreamingCoordinator` keeps ownership of **ephemeral active technical-region state only**.

The current default remains:

- 256×256 technical region size;
- radius-1 active square;
- edge clipping.

Slice 002 does not change those approved defaults.

`update_focus(cell)` becomes:

1. validate focus/global plan/grid;
2. compute target active technical regions exactly as Slice 001;
3. convert them to target bounds;
4. discover intersecting settlement source handles;
5. discover intersecting countryside source handles;
6. merge + stable-sort handles;
7. call one atomic `ensure_sources()` batch;
8. commit active-region/focus state only if required materialization succeeds;
9. emit materialized notifications for any newly committed source, regardless of source kind;
10. emit deterministic activated/deactivated technical-region deltas.

Technical regions still do not become persistent source IDs.

## 14. Revisit / persistence rule

After a countryside source key exists in the registry:

- revisiting any stream region intersecting it does not rerun System 20C;
- terrain is not reset;
- natural props are not recreated;
- removed/moved/added persistent entities are not overwritten;
- later typed mechanic state is not reset;
- WHAT, Door State and registry revisions do not advance merely because the source becomes active again.

The smoke should deliberately mutate a countryside fact after materialization, deactivate it, revisit it and prove the mutation survives.

A practical test mutation may remove one generated rural-open natural prop from WHAT and verify it stays removed after revisit. This tests generation relinquishment without inventing a new gameplay mechanic.

## 15. Registry compatibility

`MaterializationRegistry` schema v1 already stores arbitrary validated source kind/key/id plus area/environment provenance.

Slice 002 should **not** bump registry schema merely because a second source kind exists unless implementation proves the existing validation assumes `system20_area_site` specifically.

Expected outcome:

- settlement and countryside records coexist in the same registry;
- ordered snapshot/restore remains deterministic;
- a v1 registry containing only settlement records remains valid;
- adding countryside records is backward-compatible within schema v1.

## 16. Source-catalog coverage rule

For the current implemented physical domains, the global world is partitioned conceptually into:

1. settlement area-site sources;
2. dry countryside sources;
3. intentionally unsupported river corridor cells.

The catalog validator must prove every cell in the broad rural-open global region that is outside settlement sites and outside the physical river corridor belongs to exactly one countryside source.

This is a logical coverage guarantee, not WHAT materialization at startup.

No source exists merely because a technical stream region exists.

## 17. Performance / mobile requirements

- No per-frame source-catalog rebuild.
- Catalog may be built once per generated global plan and retained by the 00F composition owner.
- Source intersection queries must operate on the finite current catalog, not scan individual world cells.
- Individual countryside source bounds remain contained within one System 00D geography cell, so no source exceeds that parent logical planning cell.
- Materialization remains synchronous in Slice 002; do not fake background workers.
- Existing radius-1 active behavior remains unchanged for correctness. If profiling shows the first countryside focus materializes too much area synchronously, prefetch/materialization-radius policy becomes a separate approved 00F performance slice rather than silently redefining source identity.
- No WHEN ticks are consumed by materialization.
- Safari/browser lifecycle pause remains outside 00F.

## 18. Failure behavior

Explicit failures include:

- invalid global plan;
- missing/malformed rural-open global planning context;
- malformed geography source record;
- malformed/non-cardinal river segment;
- invalid river width/corridor;
- rectangle-subtraction or coverage inconsistency;
- duplicate/conflicting countryside source key;
- countryside/countryside or countryside/settlement positive overlap;
- unknown source kind/source ID;
- countryside source projection unexpectedly rejected by System 20C;
- generated countryside plan identity/bounds/profile mismatch;
- mixed-source materialization ID collision;
- any partial mixed-source write attempt;
- malformed/conflicting registry snapshot.

On any materialization failure, active technical state remains unchanged and WHAT + Door State + registry restore exactly to their pre-batch snapshots.

## 19. Expected implementation surface

Expected new files:

- `game/scripts/streaming/CountrysideSourceCatalog.gd`;
- `game/scripts/streaming/CountrysideMaterializationSource.gd`;
- `game/scripts/ci/CountrysideStreamingMaterializationSmoke.gd` or a bounded extension/new companion to the existing 00F smoke.

Expected narrow edits:

- `game/scripts/generation/world/GlobalHydrologyQuery.gd` — expose existing corridor-rectangle semantics read-only;
- `game/scripts/streaming/AreaSiteMaterializationSource.gd` — uniform source-handle seam only;
- `game/scripts/streaming/WorldMaterializationCoordinator.gd` — mixed-source batch routing/atomicity;
- `game/scripts/streaming/WorldStreamingCoordinator.gd` — discover both source kinds;
- `.github/workflows/streaming-materialization.yml` — run Slice 002 contract;
- exact-head publisher only if the current workflow name/context must change; preferred outcome is keeping `verify/system00f-streaming-materialization`.

Durable docs after successful implementation:

- this file -> IMPLEMENTED;
- `SYSTEM_DESIGNS/00F_STREAMING_MATERIALIZATION_ORCHESTRATION.md` summary/future seam;
- `SYSTEM_DESIGNS/README.md`;
- `README_CONTEXT.md`;
- `DESIGN_DECISIONS.md` for approved source-catalog identity/version rule;
- `CHANGELOG.md`.

## 20. Protected neighbors

Implementation must not change semantics in:

- System 00D v6 planner/profile/signature;
- System 19 building generation;
- System 20C rural-open morphology/determinism;
- Crossroads/Small-Town/Rural-Scattered System 20 profiles;
- `AreaMaterializationCoordinator.gd` unless a genuine generic-plan contract bug is discovered and surfaced before editing;
- WHAT/WHEN;
- collision/movement/doors;
- Art/render/camera/player/input/UI;
- System 22 live critique composition.

No System 20 profile version should change for a pure 00F source-orchestration implementation.

## 21. Acceptance tests

Dedicated Slice 002 verification should prove at minimum:

1. System 00D v6 canonical signature remains exact;
2. System 20C rural-open regression remains exact;
3. countryside catalog is deterministic for same global plan;
4. countryside source IDs/keys are unique and catalog-versioned;
5. source keys do not contain or depend on technical stream-region coordinates;
6. rebuilding 00F with different technical stream sizes yields the exact same countryside source catalog/keys;
7. every countryside source lies inside one parent geography cell;
8. countryside sources never positively overlap each other;
9. countryside sources never overlap any settlement area site;
10. countryside sources never overlap physical river corridor cells;
11. all dry non-settlement/non-river global cells are covered exactly once by countryside source rectangles;
12. dry land immediately beside a river remains represented instead of dropping the whole parent geography cell;
13. a focus in ordinary roadless countryside materializes real System 20C terrain/props into WHAT;
14. a focus on roadside countryside preserves the exact inherited regional road identity/geometry;
15. a focus whose active halo intersects both a settlement and countryside performs one atomic mixed-source ensure;
16. repeated focus/revisit performs zero persistent writes for already-materialized countryside;
17. removing one real generated countryside natural prop, moving away and revisiting does not regenerate it;
18. all five settlement source records still coexist with countryside records;
19. registry snapshot/restore round-trips mixed source kinds deterministically;
20. deliberately inducing a stable entity-ID collision in one virgin countryside source rolls back the entire mixed batch exactly;
21. a technical region covering only unsupported river corridor does not fabricate water or grass there;
22. source-materialization ordering is stable by source key;
23. existing 00F Slice 001 settlement-only tests remain green;
24. protected Systems 00D/19/20/21/22 and Pages remain green on the exact final SHA;
25. live Web presentation remains Rural Crossroads Candidate 006.

## 22. Future seams

### Local hydrology / bridges

When physical river/bridge materialization exists, the logical source catalog may need a new approved source kind or catalog version for currently excluded river cells. Slice 002 must not pre-decide that physical model.

### Sparse rural properties

Later rural-open content may add isolated homes/farms. Their persistent IDs and footprints can safely use the established logical countryside sources because source boundaries are now independent from streaming.

### Population / System 00E

00E may assign people/households/activities to logical physical places and use active-region information for simulation detail. 00F remains materialization/activation orchestration only.

### Save / backing store

A future save/session owner can serialize WHAT + typed domains + Materialization Registry. A later 00F residency/eviction slice may then remove cold data from hot memory without making non-resident mean nonexistent.

### Prefetch policy

Vehicle speed or profiling may justify source-specific prefetch policy later. That policy may change **when** a logical source materializes, never what the source ID/bounds are.

## 23. North-star fit

Slice 002 closes the most important gap between the current five persistent settlement islands and the intended continuous open world.

It does so without violating the architecture that makes the world trustworthy:

- global planning still owns physical coherence;
- System 20C still owns countryside morphology;
- WHAT still owns persistent current reality;
- 00F still owns only source materialization + technical activation;
- stream regions remain replaceable performance geometry;
- river cells remain honestly unfinished instead of being faked;
- player changes survive because generation relinquishes ownership permanently after first materialization.

## 24. Proposed decisions requiring approval

1. Use System 00D geography cells as the logical parent lattice for countryside source identity; do **not** use 00F technical stream regions.
2. Subtract exact settlement area-site bounds from each geography cell rather than dropping entire intersecting geography cells.
3. Subtract the exact physical river corridor at declared width, leaving only that corridor source-free until local hydrology exists.
4. Make each remaining dry rectangle a v1 `system20_rural_open` logical source with identity derived from catalog version + geography identity + global bounds.
5. Do not merge neighboring dry fragments in Slice 002; stable simple identity is more important than minimizing source count.
6. Generalize WorldMaterializationCoordinator to one atomic mixed-source transaction while preserving existing area-site convenience APIs.
7. Keep the existing 256×256 radius-1 technical stream configuration unchanged; source identity remains independent of it.
8. Keep MaterializationRegistry schema v1 if its current generic record validation accepts the new source kind.
9. Keep unsupported river cells genuinely unmaterialized rather than widening the missing area to whole geography cells or faking water/grass.
10. Keep System 22/live presentation unchanged in this slice.