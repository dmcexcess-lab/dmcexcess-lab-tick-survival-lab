# Tick Survival Lab — System 00F Streaming / Materialization Orchestration

Status: **IMPLEMENTED — settlement + dry countryside logical sources**

System 00F decides **when already-planned logical places are materialized** and which technical stream regions are currently active. It does not own world geography, local morphology, rendering, simulation time or persistence storage.

Core rule:

> **Materialization is one-way; activation is reversible.**

A technical streaming region is not a logical world region and never becomes persistent source identity.

The former Slice 001/002 discussion documents are consolidated here. Their detailed drafting history remains in Git/changelog.

## 1. Four distinct concepts

### Logical world truth

System 00D/20/19 determine virgin generated facts. After materialization, WHAT + typed mechanic stores own current persistent reality.

### Logical materialization source

A deterministic generation domain that may create virgin persistent facts exactly once.

### Technical stream region

Replaceable proximity/activation geometry used only to decide which logical sources should be ensured near the current focus.

### Active region

A technical region inside the current detailed-use halo. Activation does not itself mean rendered, simulated, saved, newly generated or resident in a future cache.

## 2. Current logical source kinds

### `system20_area_site`

The five current System 00D settlement `area_site` records.

Source key:

`system20_area_site:<site_id>`

A site materializes through the real public System 00D -> System 20 -> System 19 -> area materialization -> WHAT/Door State path.

### `system20_rural_open`

Catalog-v1 dry countryside fragments.

Countryside logical identity derives from:

- System 00D geography parent identity;
- final dry global rectangle after exact subtraction;
- catalog version.

It does **not** derive from technical stream-region coordinates or stream size.

Catalog v1 subtracts:

- the five settlement area-site rectangles;
- exact physical river corridor rectangles.

Every supported dry non-settlement/non-river cell belongs to exactly one countryside source. Dry land directly beside the river remains source-owned.

## 3. Provider contract

Materialization/streaming coordinators consume source adapters through one provider contract rather than one coordinator field/branch per source kind.

A provider must expose:

- `is_ready() -> bool`;
- `source_kind() -> StringName`;
- `source_handle(global_plan, source_id) -> Dictionary`;
- `source_handles_intersecting(global_plan, bounds_list) -> Array[Dictionary]` for streaming discovery;
- `validate_source_bounds(global_plan) -> Dictionary`;
- `prepare(global_plan, source_id) -> Dictionary`.

Required source-handle fields:

- `source_kind`;
- `source_id`;
- `source_key`;
- `bounds`.

Prepared source results additionally carry the validated System 20 request/plan, source seed and deterministic plan signature.

The current area-site and countryside adapters implement this contract. Legacy convenience constructor arguments/APIs remain supported, but coordinators normalize providers internally into a kind-indexed collection.

**Future rule:** adding a river, building-cache, or other logical source provider must not add another hardcoded `_foo_source` field or `if source_kind == ...` branch to the coordinators.

## 4. Technical stream grid

`StreamingRegionGrid.gd` is pure technical geometry.

Current default configuration:

- region size `Vector2i(256,256)`;
- origin = global world bounds position;
- active radius = 1 Chebyshev/square neighborhood;
- edge regions clipped to global bounds.

The current 1792×1792 test world therefore happens to be 7×7 technical regions. That is a configuration coincidence, not world identity.

Changing technical region size/radius must not change:

- System 00D plans;
- System 20 generated signatures for the same logical request;
- stable entity IDs;
- logical materialization source IDs/keys;
- persistent player/world mutations.

## 5. Materialization Registry

`MaterializationRegistry.gd` records which logical sources have successfully materialized.

Current snapshot schema: **v1**.

A `MaterializationRecord` stores provenance/audit facts such as:

- source key/kind/id;
- bounds/seed;
- area/environment profile IDs + versions;
- generated-area plan signature;
- WHAT revision immediately after materialization;
- Door State revision immediately after materialization.

The registry is technical provenance, not a second world truth and not the final user save-file format.

## 6. Atomic materialization transaction

`WorldMaterializationCoordinator.ensure_sources()`:

1. validates the global plan and all registered source providers;
2. canonicalizes supplied handles through the owning provider;
3. deduplicates/sorts by stable source key;
4. classifies already-materialized vs missing sources **before generation**;
5. never calls System 20 for an already-materialized source;
6. prepares all missing sources through their providers before persistent writes;
7. takes the **one enclosing persistent-state rollback snapshot** for WHAT, Door State and Materialization Registry;
8. materializes prepared plans in stable source-key order through `AreaMaterializationCoordinator.materialize_in_transaction()`;
9. area materialization in turn uses the enclosing-transaction seam of generated-building materialization, so neither the area nor each building copies the entire accumulated world again;
10. appends a registry record only after each source succeeds;
11. restores all three outer snapshots exactly if any later source/materialization/registry step fails.

Standalone System 20/building materializer APIs remain independently transactional. The no-nested-snapshot seam is used only when an enclosing owner already guarantees rollback.

Legacy `ensure_area_site()` / `ensure_area_sites()` remain convenience APIs layered on the common provider path.

## 7. Revisit invariant

Once the registry contains a source key:

- no System 20 generation reruns;
- no System 19 generation reruns;
- original terrain is not reset;
- destroyed/removed/moved/created entities are not recreated from baseline;
- door state is not reset;
- WHAT/Door/registry revisions do not change merely because the player revisits.

Tests prove both a player-opened settlement door and a persistently removed countryside prop survive deactivation/revisit without regeneration.

## 8. Active-region lifecycle

`WorldStreamingCoordinator.update_focus(cell)`:

1. rejects focus outside world bounds;
2. resolves the technical focus region;
3. if focus remains inside the already-active technical focus region, updates the precise focus cell and returns through a **same-region fast path** with zero provider discovery, catalog validation, ensure/materialization work or activation delta;
4. otherwise computes the configured active neighborhood;
5. asks every registered discovery provider for logical sources intersecting the active technical bounds;
6. atomically ensures all discovered sources;
7. commits focus/active-region changes only after required materialization succeeds;
8. emits deterministic activation/deactivation/materialization notifications.

This consumes zero WHEN ticks. Callers may therefore update focus on every relevant player-cell movement without paying discovery/materialization overhead until the technical region actually changes.

## 9. Deactivation is non-destructive

Current deactivation changes only technical active bookkeeping.

It does not:

- remove terrain/entities from WHAT;
- unregister doors;
- revert gameplay mutations;
- advance simulation time.

True memory eviction is **not implemented** because WHAT is the authoritative current world. Removing facts merely because they became inactive would mean destruction unless a separately approved persistence-backed inactive-region store owns those facts safely.

## 10. Current river boundary

System 20 now has real `rural.watercourse` physical generation for System 00D river/bridge truth.

00F still intentionally has **no river logical source provider**. Catalog-v1 countryside identity remains unchanged and continues excluding the exact river corridor.

A future river-source provider can plug into the common provider contract without rewriting coordinator internals. Its source partition/identity must be designed explicitly and must preserve current countryside source IDs.

That seam exists, but implementing it is not automatically the next project priority.

## 11. Performance

The approved 2026-08-23 performance razor preserves the ownership architecture while reducing hot-path copying and mutation traffic:

- no per-frame regeneration;
- provider discovery is bounded to the active technical neighborhood;
- same-region focus movement bypasses discovery/ensure completely;
- already-materialized sources return without local generation;
- System 20 ground regions and generated-building floor runs use coalesced WHAT terrain mutations rather than one revision/change signal per cell;
- the Ground renderer consumes coalesced terrain dirty geometry and requests at most one redraw per relevant batch;
- a multi-source 00F transaction owns one full WHAT + Door State + registry rollback snapshot; nested area/building materializers reuse that transaction instead of taking additional whole-world snapshots;
- standalone materializer APIs keep their original independent transaction behavior;
- current materialization remains synchronous because there is no approved worker/background persistence contract.

Measured on the same GitHub runner class and the same multi-scenario 00F regressions, settlement materialization improved from about **55.6s to 13.9s** (~75% faster / ~4.0× throughput) and countryside from about **63.4s to 10.7s** (~83% faster / ~5.9× throughput). These are CI regression-suite timings, not literal player-facing load latency.

The remaining scale concern is the **one outer full-state snapshot** plus non-evicting WHAT residency as the explored world grows. A future write-journal/transaction representation and persistence-backed inactive-region residency may address that only when profiling/world-size pressure justifies a separately approved storage contract.

Ownership correctness still takes priority over speculative async/cache complexity.

Verified performance code head: `0b10957bb586162634e9da3c1a4415aef528fd2d`.

## 12. Tests

Current exact-head context:

`verify/system00f-streaming-materialization`

The System 00F suite proves:

- technical grid mapping/config replaceability;
- settlement and countryside source identity;
- dry coverage + river exclusion;
- shared WHAT materialization across all five settlements and countryside;
- deterministic registry snapshot/restore;
- revisit persistence with zero writes;
- mixed-source stable ordering;
- exact rollback on deliberately induced future-source ID collisions;
- invalid-focus no-op behavior;
- source-free river cells remain unmaterialized;
- same-region focus performs zero provider discovery/materialization work;
- coalesced 4096-cell terrain writes advance WHAT revision once and invalidate visible ground once;
- standalone materializers retain rollback snapshots while enclosing transactions take no nested full-world snapshots;
- protected System 00D/19/20/21/22 behavior remains compatible.

## 13. Non-goals

System 00F does not own:

- morphology/generation algorithms;
- physical river geometry;
- population/AI simulation resolution;
- save-file/browser serialization;
- memory eviction;
- rendering/camera;
- player movement/input;
- WHEN timing.
