# Terrain Bulk-Write Optimization Closure

Date: 2026-09-10

## Scope

Bounded performance operation to remove the production streaming-region terrain commit freeze without changing authoritative WHAT terrain semantics or generated-plan identity.

Starting main head: `64d8a9f9022e623b40e0a5edac6560bd8814d5ec`

Successful functional head: `39b2710ef56ec7565de55b6c7dcc1f69fb723e73`

## Baseline

The production action-65 streaming seam at player anchor `[1708,1488] -> [1708,1487]`, region `[16,7] -> [16,6]`, measured:

- ground terrain commit: `9,925,013 us`
- full boundary action: `12,089,586 us`
- rollback world snapshot: `1,584,293 us`
- incoming terrain workload: 49,152 cells
- incoming buildings: 0
- outdoor props: 67, approximately 10 ms

The seam was therefore dominated by ground terrain projection/write work rather than procedural planning, building generation, or prop materialization.

## Investigation corrections

The first optimization assumed most incoming terrain cells were already known and could be skipped. Production instrumentation disproved that assumption: all 49,152 cells at this seam were virgin terrain from the TerrainStore's perspective.

A second compact full-chunk representation also failed to materially improve the seam because the production materializer was not submitting large 128x128 rectangles. The same workload arrived as 784 small rectangle mutations.

Tracing those mutations found the amplification source in `IslandSurfaceAreaGenerator._surface_runs()`: the generated island-surface plan intentionally authors horizontal semantic runs row by row. `AreaMaterializationCoordinator._materialize_ground()` had been committing each authored run independently, turning one incoming terrain layer into hundreds of WHAT mutation/notification boundaries.

## Implemented optimization

### TerrainStore

`TerrainStore` now groups cell storage into fixed 16x16 chunks rather than relying on one global `Dictionary<Vector2i, semantic>` entry per terrain cell. Cell-level `has`, `get_type`, `set_type`, erase, and snapshot behavior remain authoritative and compatible with the existing snapshot schema.

Bulk rectangle writes operate per chunk. Fully covered chunks use one native array fill/update instead of 256 global hash-table mutations; partial chunks reuse one chunk lookup and local indices.

### World mutation path

`WorldState` exposes the TerrainStore bulk rectangle mutation internally, and `WorldMutationService.set_terrain_rect()` delegates to it while retaining the existing external contract: one replay-safe `TERRAIN_BATCH_SET` change for a successful changed rectangle and no revision advance for an exact no-op.

Bulk-write telemetry was added for requested, changed, visited, and skipped terrain cells/chunks.

### Materialization write scheduling

`AreaMaterializationCoordinator` now conservatively coalesces eligible terrain row runs immediately before WHAT mutation.

Coalescing is allowed only when a same-priority group is proven to consist exclusively of positive one-row rectangles with non-overlapping intervals. Vertically adjacent runs are fused only when their x-span and semantic match. Any ambiguous group falls back to its original write schedule.

The generated `GeneratedAreaPlan` is not modified. Plan signatures, source identity, procedural provenance, priority ordering, and final cell semantics therefore remain unchanged.

## Production result

Focused verifier run: `34552814772`

Owning functional head: `39b2710ef56ec7565de55b6c7dcc1f69fb723e73`

At the same real production seam and same 49,152-cell terrain workload:

- rectangle mutations: `784 -> 17` (~97.8% fewer; ~46x reduction)
- scalar terrain visits: `49,152 -> 6,144` (87.5% fewer)
- ground commit: `9,925,013 us -> 260,523 us` (~97.4% lower; ~38.1x faster)
- full boundary action: `12,089,586 us -> 1,234,618 us` (~89.8% lower; ~9.8x faster)
- rollback world snapshot: `1,584,293 us -> 308,084 us` (~80.6% lower; ~5.1x faster)

The focused production verifier passed with `PROMPT_TERRAIN_BULK_WRITE_OPTIMIZATION_OK`.

## Semantics/regressions verified

The owning verifier covers:

- exact mixed-terrain overwrite semantics;
- one terrain-revision advance for a real bulk rewrite;
- no terrain-revision advance for an exact no-op;
- negative-coordinate terrain chunk lookup;
- terrain erase and single-cell rewrite;
- snapshot round-trip through the existing schema;
- production `main.tscn -> NEW GAME -> gameplay.tscn` startup;
- real `PlayerActionController` movement to the same streaming seam;
- the same 49,152-cell production terrain workload;
- ground-commit performance below the prior measured baseline and below the 3-second regression ceiling.

Functional-head GitHub Pages run `34552814773` completed successfully: Web export/build and deploy both passed.

## Prompt-owned verifier

Current prompt-owned verifier pair:

- `game/scripts/ci/PromptTerrainBulkWriteOptimizationSmoke.gd`
- `.github/workflows/prompt-terrain-bulk-write-optimization.yml`

Retire this pair at the start of the next code operation.

## Remaining performance boundary

This operation intentionally does not broaden into unrelated per-action optimization. The boundary action is now approximately 1.23 seconds rather than approximately 12.09 seconds; remaining cost includes the rollback snapshot and the game's ordinary per-action work. Any further optimization should be a separately authorized bounded operation based on fresh profiling.
