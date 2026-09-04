# Tick Survival Lab — System 33B Physical Power Network Condition

Status: **IMPLEMENTED + PLAYER SUPPORT REPAIR VERIFIED; HUMAN PLAYTEST PENDING**

Verified executable: `6aab0596cb46d70d4739cbc045d149a25597193d`

Parent: `33_POWER_WATER_UTILITIES.md`

## 1. Purpose

System 33B gives visible distribution infrastructure persistent physical condition and causal outage consequences without continuously simulating the grid.

Visible spans/supports are real failure targets. Failed assets stay visible, but mapped System-33 service links become unavailable until the physical fault is repaired.

## 2. Current topology boundary

The current playable topology is generated from actual local-area building manifests:

- buildings are grouped with a target of 10 buildings per local substation;
- each local substation is a fenced transformer/utility-box compound;
- the regional source/ingress -> local-substation relationship is logical/non-physical for gameplay presentation;
- no long-distance transmission wire is materialized between the source and local substations;
- each substation leaves through one short lead into a **shared roadside feeder tree** built from the actual generated local-road centerlines;
- customer root-to-tap paths are unioned so common road sections become one deduplicated physical trunk;
- roadside poles are placed at the root, taps, turns, junctions and deterministic spacing points;
- the shared trunk forks only where road/customer topology requires it;
- each generated served building receives one short final service drop from its shared roadside tap to a nearby customer pole;
- there are no direct transformer-to-every-house starburst spans;
- visible shared-trunk and service-drop spans carry the service/building provenance needed for causal local outages.

Global 00D4 power facts remain upstream planning/provenance. The playable local topology does not invent a second service authority; `NeighborhoodUtilityRuntimeState` translates the generated local topology into canonical System-33 power components/links/bindings.

## 3. Stable physical identity

Physical spans use stable `power.asset.span.*` IDs. Persistent supports/substation equipment use stable WHAT entity IDs.

Each wire record carries enough immutable provenance to map failure to the correct local service, including its start/end IDs, segment/service identity, route cells where applicable, and the served building on final drops.

Presentation topology is cached separately from energized state, so a dead wire does not disappear simply because its service failed.

Persistent distribution-support WHAT entities are registered with their exact System-33B asset identity. This same identity is now used by the player-facing repair route; no interaction-only utility asset is created.

## 4. Condition owner

`UtilityNetworkConditionStore` is the data-only physical condition substrate. It stores durable condition/damage/repair truth without per-asset Nodes, Timers or `_process()` work.

Direct damage and repair are event-driven. System 33B does not create a duplicate `powered` property on presentation objects.

System 29 may expose a REPAIR offer for a failed physical support, but it never owns or copies condition. The offer/action service resolves the clicked WHAT entity back to this owner and commits through `UtilityPowerNetworkRuntime`.

## 5. Daily deterministic line-snap rule

The old continuous analytic wear/future-threshold scheduler is superseded.

`UtilityPowerNetworkRuntime` performs one deterministic eligible-span pass each time authoritative world time crosses into a new game day.

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

This applies to the real physical shared-trunk and service-drop span set. It creates rare infrastructure failure without frame polling, per-span scheduled events or a continuously evolving wear equation.

## 6. Authoritative-time processing

`advance_to_tick(world_tick)` processes only missing day boundaries since the last processed authoritative day. No work occurs because a render frame passed.

`next_failure_tick()` is retained as a compatibility/query seam and means the **next daily test boundary**, not a predicted wear threshold.

Snapshot state includes the condition store, last processed day and quiet-day count so save/restore cannot reroll already-resolved history.

## 7. Failure consequence

When a shared-trunk or service-drop span snaps, or an asset is explicitly damaged past failure threshold:

1. the real physical asset condition becomes failed;
2. System 33B looks up only the mapped power services for that asset;
3. it damages the existing canonical distribution link for those services;
4. System-33 power derivation propagates the outage to real consumers;
5. unrelated services remain available when their mapped assets are healthy.

The shared physical topology does not change service authority: a common trunk can causally affect the downstream service mappings carried by that physical asset, while a final drop is bounded to its mapped customer/service path.

Lighting, refrigeration and other consumers are never toggled directly by the span runtime.

## 8. Sound consequence

A daily span failure emits:

`line_snapped(asset_id, cell)`

The live composition forwards that real event through System 26 spatial sound with the textual sound presentation `*SNAP*`. There is no audio-file playback requirement.

## 9. Repair seam and player route

The canonical low-level repair seam remains:

- distribution span: Electrical 2 + 1 abstract owner material unit;
- distribution support: Electrical 2 + 2 abstract owner material units.

Those abstract units are the internal System-33B condition-repair contract. The ordinary player route does **not** expose or inventory those counters directly.

### Player-facing failed support repair

`UtilityPowerRepairInteractionOfferProvider` and `UtilityPowerRepairActionService` translate the existing distribution-support repair requirement into real carried entities while retaining System-33B as condition/service owner.

Current failed wooden support profile:

- exact target must be the persistent WHAT support registered as a `distribution_support`;
- target must currently be failed in `UtilityPowerNetworkRuntime`;
- real carried hammer required and retained;
- two real carried wood-plank entities consumed;
- one real carried nails-box entity consumed;
- current player-facing Mechanical requirement checked;
- real WHEN action duration/completion required;
- commit calls this existing repair seam and restores only outage state caused by this fault.

The action captures the existing `UtilityPowerNetworkRuntime` snapshot before commit and restores it if commit/resource finalization fails. This preserves one transactional authority instead of adding a second condition cache to UI/System 29.

After successful repair the same support is healthy and no longer produces a REPAIR offer.

### Span boundary

Physical spans remain real damageable/repairable System-33B assets, but they currently have no independent player-clickable WHAT entity. Therefore the normal player route intentionally does not invent a wire target or infer one from rendering. Direct player span repair remains deferred until physical selection identity is real.

## 10. Performance contract

System 33B must not introduce:

- per-asset Nodes or Timers;
- `_process()` utility simulation;
- full-network scans on render frames or ordinary player actions;
- one scheduled WHEN event per span;
- repeated graph discovery after each failure.

Topology/mappings are built once. Daily work happens only at day boundaries; direct mutation work is bounded to affected services/assets.

The player repair action is event-driven from an exact clicked target and does not add recurring utility work.

## 11. Verification

`System33PowerPhysicalNetworkSmoke.gd` and `System33PowerInfrastructureSmoke.gd`, run by `verify/system33-power-water`, prove:

- stable physical identities;
- one shared road-following feeder topology rather than direct substation-to-customer rays;
- exact one-per-building final service-drop ownership;
- shared-trunk route cells on generated roads;
- deduplication of overlapping customer routes and reuse of roadside poles by multiple wire edges;
- real local-service causality and sibling isolation;
- direct damage/repair;
- daily deterministic snap behavior;
- snapshot/restore of daily state;
- continued visible topology while de-energized;
- no forbidden recurring utility simulation.

`UtilityPowerRepairUiSmoke.gd`, run by `verify/world-interaction-closure`, additionally proves the real player path:

1. damage a real physical distribution support;
2. observe the actual mapped service outage;
3. click the persistent support through the normal world-pointer route;
4. select its real REPAIR button;
5. spend WHEN and consume exactly the required real carried materials while retaining the hammer;
6. restore canonical condition and service;
7. reopen the now-healthy target and prove REPAIR is absent.

The first closure run exposed stale hidden chooser controls after the successful repair; canonical condition and provider filtering were already correct. `WorldInteractionPanel` now clears old controls on close, so no obsolete REPAIR control survives the action lifecycle.

Verified executable: `6aab0596cb46d70d4739cbc045d149a25597193d`.

Exact-head verification:

- `verify/system33-power-water`: success;
- `verify/world-interaction-closure`: success, run `33915077349`;
- `verify/system29-interaction-affordance`: success;
- `verify/pages-deploy`: success, run `33915077391`;
- protected neighboring exact-head statuses: green.
