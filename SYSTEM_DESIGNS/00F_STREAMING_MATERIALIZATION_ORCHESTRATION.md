# Tick Survival Lab — System 00F Streaming / Materialization Orchestration

Status: **IMPLEMENTED — settlement + countryside + complete-island surface + river sources**

Updated: **2026-08-24**

## 1. Core rule

> **Materialization is one-way; activation is reversible.**

System 00F decides when already-planned logical places are materialized and which technical stream regions are active. It does not own geography, local morphology, rendering, simulation time or final persistence storage.

A technical streaming region is never logical world identity.

## 2. Distinct concepts

### Logical world truth
System 00D/20/19 determine virgin generated facts. After successful materialization, WHAT + typed mechanic stores own current persistent reality.

### Logical materialization source
A stable deterministic generation domain that may create virgin persistent facts once.

### Technical stream region
Replaceable proximity geometry used only for activation/discovery.

### Active region
A technical region in the current detailed-use halo. Active does not mean newly generated, rendered, saved or newly existent.

## 3. Provider contract

Every materialization-source adapter exposes the same narrow contract:

- `is_ready()`;
- `source_kind()`;
- `source_handle(global_plan, source_id)`;
- `source_handles_intersecting(global_plan, bounds_list)`;
- `validate_source_bounds(global_plan)`;
- `prepare(global_plan, source_id)`.

Source handles contain stable source kind/id/key + bounds. Prepared results contain the validated local request/plan and deterministic provenance.

`WorldMaterializationCoordinator` and `WorldStreamingCoordinator` consume providers generically; adding a source kind must not require another hardcoded coordinator branch.

## 4. Current source kinds

### `system20_area_site`

Materializes System 00D settlement/local-area sites through the real:

`00D -> System 20 -> System 19 -> WHAT/Door State`

path.

### `system20_rural_open`

The original rural-region catalog-v1 dry countryside source remains supported for the protected rural world profile. Its stable source identity derives from geography parent identity + final dry bounds + catalog version, never stream coordinates.

The rural-open catalog continues to exclude settlement sites and the physical river corridor so its existing source identities are not rewritten.

### `island_surface`

The complete-island profile uses `IslandSurfaceSourceCatalog` / `IslandSurfaceMaterializationSource` for all island-world cells outside settlement sites and river corridors.

The source prepares bounded `IslandSurfaceAreaGenerator` plans containing deterministic:

- ordinary land;
- shore transition terrain;
- ocean;
- inherited island roads where authorized.

Source identity derives from the island world plan and stable source bounds, not the technical streaming grid.

### `system20_watercourse`

`WatercourseSourceCatalog` / `WatercourseMaterializationSource` close the former river hole.

They project the real System 00D physical river corridor through the existing System 20 `rural.watercourse` profile. Bridge-deck terrain appears only from matching explicit System 00D bridge intent.

River cells therefore become real persistent WHAT terrain instead of source-free technical gaps.

## 5. Complete-island partition

For `temperate.island.region` v1, the logical physical-world partition is:

1. area-site sources for the five globally planned settlements;
2. watercourse sources for the exact river corridor;
3. island-surface sources for everything else inside world bounds.

These sources are non-overlapping and together cover the bounded island world.

The complete-island smoke samples the whole world and requires each sampled cell to belong to exactly one of those logical source families.

This partition is geography/materialization identity. It is independent from technical active-region size.

## 6. Atomic materialization

`WorldMaterializationCoordinator.ensure_sources()` continues to:

1. validate global plan + providers;
2. canonicalize/deduplicate/sort handles;
3. identify already-materialized sources before generation;
4. prepare every missing source before persistent writes;
5. take one enclosing WHAT + Door State + registry rollback snapshot;
6. materialize plans in stable source-key order;
7. append registry provenance only after successful materialization;
8. restore all outer state exactly if any later source fails.

Nested System 20/System 19 materializers use the enclosing transaction seam instead of taking redundant full-world snapshots.

## 7. Revisit invariant

Once a source key is in the registry:

- generation does not rerun;
- original terrain is not restored;
- removed/moved/created entities are not reset;
- doors are not reset;
- revisiting alone produces no persistent writes.

This applies equally to settlement, rural-open, island-surface and watercourse sources.

## 8. Player-following streaming

The canonical playable island now uses the real `WorldStreamingCoordinator`.

`PlayerStreamingFocusAdapter` follows the controlled survivor's real global placement and updates streaming focus after movement. Same-region movement uses the existing fast path; crossing a technical region boundary discovers/ensures the intersecting logical island sources.

Current playable-island technical configuration:

- region size: 128×128 cells;
- active radius: 1;
- global island bounds: 1792×1792 cells.

Those values are performance/configuration choices, not world identity.

Streaming focus updates spend zero WHEN ticks.

## 9. Deactivation

Deactivation remains non-destructive bookkeeping only. It does not remove WHAT, reset doors or reverse player mutations.

True persistence-backed memory eviction remains deferred because current WHAT is authoritative current truth. Inactive may not be silently treated as nonexistent.

## 10. Performance

Existing rules remain:

- no per-frame regeneration;
- provider discovery only in the active technical neighborhood;
- same-region focus bypasses discovery/ensure;
- materialized sources no-op on revisit;
- coalesced ground/floor writes;
- one outer transaction snapshot for multi-source materialization;
- synchronous materialization until a separately approved worker/persistence contract exists.

The previous performance razor remains valid evidence: representative settlement/countryside regression workloads improved from ~55.6s/~63.4s to ~13.9s/~10.7s on the same runner class. These are CI-suite timings, not direct user load latency.

The remaining scale concern is non-evicting persistent WHAT plus the enclosing transaction snapshot as explored world size grows.

## 11. Verification

Exact-head context:

`verify/system00f-streaming-materialization`

Current tests protect:

- technical-grid replaceability;
- stable source identity;
- one-way materialization/revisit persistence;
- mixed-source atomic rollback;
- same-region fast path;
- coalesced materialization writes;
- original rural countryside source behavior;
- complete-island surface source validation;
- physical watercourse source validation;
- island area-site + surface + river source partition;
- canonical player-following island streaming startup.

Complete-island generator head `41b243501acffa480ddde61b498d743a4e4e1d97` and canonical playable-island head `3f1a98c3daea879cf7ffdbea717d88461e39438f` both passed all 13 required exact-head contexts including Pages.

## 12. Non-goals

System 00F still does not own:

- morphology/generation algorithms;
- river/coast shape;
- terrain traversal rules;
- rendering/art;
- population/AI simulation resolution;
- save-file/browser serialization;
- persistence-backed memory eviction;
- WHEN timing.
