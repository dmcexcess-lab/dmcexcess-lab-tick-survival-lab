# Tick Survival Lab — System 33B Physical Power Network Condition

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING**

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`

Parent: `33_POWER_WATER_UTILITIES.md`

## 1. Purpose

System 33B gives visible distribution infrastructure persistent physical condition and causal outage consequences without continuously simulating the grid.

Visible spans/supports are real failure targets. Failed assets stay visible, but mapped System-33 service links become unavailable until the physical fault is repaired.

## 2. Current topology boundary

The current playable topology is generated from actual local-area building manifests:

- buildings are grouped with a target of 10 buildings per local substation;
- each local substation is a fenced transformer/utility-box compound;
- the regional source/ingress -> local-substation relationship is logical/wireless for gameplay presentation;
- no long-distance transmission wire is materialized between the source and local substations;
- each substation feeds real customer poles placed near its generated buildings;
- visible spans carry the building/service mapping needed for causal local outages.

Global 00D4 power facts remain upstream planning/provenance. The playable local topology does not invent a second service authority; `NeighborhoodUtilityRuntimeState` translates the generated local topology into canonical System-33 power components/links/bindings.

## 3. Stable physical identity

Physical spans use stable `power.asset.span.*` IDs. Persistent supports/substation equipment use stable WHAT entity IDs.

Each wire record carries enough immutable provenance to map failure to the correct local service, including its start/end IDs, segment/service identity and the served building where applicable.

Presentation topology is cached separately from energized state, so a dead wire does not disappear simply because its service failed.

## 4. Condition owner

`UtilityNetworkConditionStore` is the data-only physical condition substrate. It stores durable condition/damage/repair truth without per-asset Nodes, Timers or `_process()` work.

Direct damage and repair are event-driven. System 33B does not create a duplicate `powered` property on presentation objects.

## 5. Daily deterministic line-snap rule

The old continuous analytic wear/future-threshold scheduler is superseded.

`UtilityPowerNetworkRuntime` now performs one deterministic eligible-span pass each time authoritative world time crosses into a new game day.

Current rule:

- denominator: `1,000,000`;
- base daily snap chance: `100` = **0.01% per eligible span/day**;
- each quiet day adds `100` = **+0.01%**;
- maximum chance: `10,000` = **1.00% per eligible span/day**;
- roll key: authoritative day index + stable span ID;
- already-failed spans are not eligible;
- the first successful snap ends that day's pass;
- a successful snap resets quiet-day accumulation to zero;
- a quiet eligible day increments quiet-day accumulation by one.

This creates rare real infrastructure failure without frame polling, per-span scheduled events or a continuously evolving wear equation.

## 6. Authoritative-time processing

`advance_to_tick(world_tick)` processes only missing day boundaries since the last processed authoritative day. No work occurs because a render frame passed.

`next_failure_tick()` is retained as a compatibility/query seam and now means the **next daily test boundary**, not a predicted wear threshold.

Snapshot state includes the condition store, last processed day and quiet-day count so save/restore cannot reroll already-resolved history.

## 7. Failure consequence

When a span snaps or an asset is explicitly damaged past failure threshold:

1. the real physical asset condition becomes failed;
2. System 33B looks up only the mapped power services for that asset;
3. it damages the existing canonical distribution link for those services;
4. System-33 power derivation propagates the outage to real consumers;
5. unrelated services remain available when their mapped assets are healthy.

Lighting, refrigeration and other consumers are never toggled directly by the span runtime.

## 8. Sound consequence

A daily span failure emits:

`line_snapped(asset_id, cell)`

The live composition forwards that real event through System 26 spatial sound with the textual sound presentation `*SNAP*`. There is no audio-file playback requirement.

## 9. Repair seam

The existing mechanical repair seam remains authoritative:

- distribution span: Electrical 2 + 1 material unit;
- distribution support: Electrical 2 + 2 material units.

Successful repair restores the physical asset's condition and only clears service outage state that System 33B itself owns for that fault.

Final user-facing repair actions, tool consumption, timing/interruption and skill balance remain future work and must call this same condition/service seam.

## 10. Performance contract

System 33B must not introduce:

- per-asset Nodes or Timers;
- `_process()` utility simulation;
- full-network scans on render frames or ordinary player actions;
- one scheduled WHEN event per span;
- repeated graph discovery after each failure.

Topology/mappings are built once. Daily work happens only at day boundaries; direct mutation work is bounded to affected services/assets.

## 11. Verification

`System33PowerPhysicalNetworkSmoke.gd` and `System33PowerInfrastructureSmoke.gd`, run by `verify/system33-power-water`, prove:

- stable physical identities;
- real local-service causality and sibling isolation;
- direct damage/repair;
- daily deterministic snap behavior;
- snapshot/restore of daily state;
- continued visible topology while de-energized;
- no forbidden recurring utility simulation.

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`.
