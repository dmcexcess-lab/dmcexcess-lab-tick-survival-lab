# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — TERRAIN BULK-WRITE / STREAMING-SEAM OPTIMIZATION CLOSED — 2026-09-10

The production streaming-region terrain freeze has been materially reduced without changing authoritative terrain semantics, generated-plan identity, or the single authoritative WHEN/TickKernel clock.

Starting head for this operation: `64d8a9f9022e623b40e0a5edac6560bd8814d5ec`

Successful functional head: `39b2710ef56ec7565de55b6c7dcc1f69fb723e73`

Documentation head immediately before this final context write: `2974284310a08b4b0549677e309bfb4995cf352f`

Closure ledger: `CHANGELOG_TERRAIN_BULK_WRITE_OPTIMIZATION.md`

The commit containing this file is the final repository write for this operation. After it lands, verification is read-only only.

## Baseline and diagnosis

The real production route `main.tscn -> NEW GAME -> gameplay.tscn` crossed the same streaming seam on action 65:

- player anchor `[1708,1488] -> [1708,1487]`;
- streaming region `[16,7] -> [16,6]`;
- terrain workload: 49,152 incoming cells;
- full boundary action: `12,089,586 us` (~12.09 s);
- ground terrain commit: `9,925,013 us` (~9.93 s);
- world rollback snapshot: `1,584,293 us` (~1.58 s).

Instrumentation disproved the original assumption that this seam was mostly rewriting already-known terrain. Those 49,152 cells were virgin from TerrainStore's perspective.

The decisive amplification was write shape: `IslandSurfaceAreaGenerator._surface_runs()` intentionally authored row-wise horizontal terrain runs, and the production materializer was issuing 784 independent rectangle mutations/notifications for one incoming terrain layer.

## Completed implementation

- `TerrainStore` now groups terrain in fixed 16x16 chunk arrays while preserving cell-authoritative `has`, lookup, single-cell set/erase, and existing per-cell snapshot schema behavior.
- Bulk rectangle assignment operates chunk-wise, with native full-chunk fills and local-index writes for partial chunks rather than one global `Dictionary<Vector2i, semantic>` mutation per cell.
- `WorldState` exposes an internal bulk terrain-record mutation path.
- `WorldMutationService.set_terrain_rect()` delegates to the TerrainStore bulk path while preserving the existing replay-safe `TERRAIN_BATCH_SET` contract and terrain revision semantics.
- Bulk terrain telemetry records rectangle calls and requested/changed/visited/skipped cells/chunks.
- `AreaMaterializationCoordinator` conservatively coalesces eligible same-priority, non-overlapping one-row terrain runs immediately before WHAT mutation.
- Coalescing only fuses vertically adjacent runs with identical x-span and semantic. Ambiguous groups retain their original schedule.
- Generated `GeneratedAreaPlan` contents/signatures are not rewritten, so source identity and procedural provenance remain stable.

## Production result

At the same action-65 seam and same 49,152-cell workload on functional head `39b2710ef56ec7565de55b6c7dcc1f69fb723e73`:

- terrain rectangle mutations: `784 -> 17` (~97.8% fewer, ~46x reduction);
- scalar terrain visits: `49,152 -> 6,144` (87.5% fewer);
- ground commit: `9,925,013 us -> 260,523 us` (~97.4% lower, ~38.1x faster);
- full boundary action: `12,089,586 us -> 1,234,618 us` (~89.8% lower, ~9.8x faster);
- world snapshot: `1,584,293 us -> 308,084 us` (~80.6% lower, ~5.1x faster).

The former ~10-second terrain freeze is therefore closed for this measured production seam. The remaining ~1.23-second boundary action is outside this bounded operation and includes snapshot plus ordinary per-action work.

## Focused verification

Prompt-owned verifier pair:

- `game/scripts/ci/PromptTerrainBulkWriteOptimizationSmoke.gd`
- `.github/workflows/prompt-terrain-bulk-write-optimization.yml`

The verifier checks:

- exact mixed-terrain overwrite semantics;
- exactly one terrain revision advance for a real bulk rewrite;
- no terrain revision advance for an exact no-op;
- negative-coordinate terrain lookup;
- erase and single-cell rewrite behavior;
- snapshot round-trip through the existing schema;
- production startup through `main.tscn -> NEW GAME -> gameplay.tscn`;
- real `PlayerActionController` movement to the measured seam;
- the same 49,152-cell production workload;
- ground commit below the previous measured baseline and below the 3-second regression ceiling.

Functional-head focused verifier:

- run `34552814772`: **SUCCESS**;
- marker: `PROMPT_TERRAIN_BULK_WRITE_OPTIMIZATION_OK`;
- measured boundary ground commit: `260,523 us`;
- measured full action: `1,234,618 us`.

Functional-head Pages:

- run `34552814773`: build **SUCCESS**, deploy **SUCCESS**.

Documentation-head verification on `2974284310a08b4b0549677e309bfb4995cf352f`:

- focused verifier run `34553018726`: **SUCCESS**;
- Pages run `34553018931`: build **SUCCESS**, deploy **SUCCESS**.

After this final context commit, verify its exact-head focused verifier and Pages runs read-only. Do not make another repository write in this operation.

## Previous verifier cleanup

The preceding prompt-owned streaming timing pair was retired at the start of this operation:

- `game/scripts/ci/PromptStreamingTransitionTimingSmoke.gd`;
- `.github/workflows/prompt-streaming-transition-timing.yml`.

At the start of the next code operation, retire the current terrain optimization verifier pair listed above before creating any new prompt-local verifier/workflow.

## Protected behavior

Preserve:

- one authoritative WHEN/TickKernel clock and decision-pause semantics;
- production `PlayerActionController` one-authoritative-batch-per-rendered-frame behavior;
- exact cell-authoritative WHAT terrain semantics;
- terrain revision/change-notification semantics;
- generated area/source plan identity, signatures, and provenance;
- snapshot compatibility;
- current generation, population, collision, perception, lighting, weather, interaction, vehicle, and UI ownership boundaries.

## Known performance follow-up

Ordinary same-region player actions remain substantially slower than the streaming-focus update itself. Earlier focused measurement showed same-region streaming-focus work around tens of microseconds while full actions were commonly several hundred milliseconds. That is a separate performance problem and was intentionally not modified here.

If explicitly promoted as the next target, instrument ordinary action/tick phases—including nearby infected work—before optimizing. Do not assume the terrain streamer is responsible for that remaining common-case latency.

## NEXT OPERATION — wait for explicit bounded target

Do not begin another code operation automatically.

At the start of the next approved code prompt, delete:

- `game/scripts/ci/PromptTerrainBulkWriteOptimizationSmoke.gd`
- `.github/workflows/prompt-terrain-bulk-write-optimization.yml`

Then create a fresh prompt-local verifier/workflow limited to that next target.
