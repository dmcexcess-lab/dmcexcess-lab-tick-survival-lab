# Tick Survival Lab — System 33B Physical Power Network Condition

Status: **IMPLEMENTED + EXACT-HEAD CI VERIFIED; HUMAN PLAYTEST PENDING**

Verified executable: `7ddee8df0e638cbe14897d83632b62513d5fc574`

Parent design: `33_POWER_WATER_UTILITIES.md`

Upstream planning: `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`

Roadmap phase: **Phase 3 — Power and Water**

---

## 1. Purpose

This approved Stage B extension connects the physical electrical distribution world to the existing System-33 service runtime without turning the utility grid into a continuously simulated network.

The gameplay result is causal and physical:

- visible distribution spans and supports have stable condition identity;
- damaging a physical distribution asset can remove power from the settlements actually downstream of that asset;
- unrelated branches remain powered when topology allows;
- repairing the failed asset restores only service that System 33 itself blocked for that physical failure;
- failed/de-energized cables remain visible because presentation is not service truth;
- unattended wear can eventually cause a real outage without per-asset timers, per-day loops or whole-network polling.

> **Physical utility assets may fail over authoritative time, but condition is analytic and service consequences are event-driven. The game never advances every pole or wire just because time passed.**

---

## 2. Ownership

### System 00D / 00D4 owns

- global electrical corridor geography;
- regional ingress, substation and settlement-service planning nodes;
- road-following feeder segment geometry;
- deterministic downstream settlement mapping for each planned feeder edge.

### System 33B owns

- persistent condition records for physical utility assets;
- stable mapping from physical distribution assets to affected System-33 power services;
- direct damage and repair mutation seams;
- analytic wear/failure prediction;
- the minimal threshold schedule needed to observe future failures;
- translation of physical failures into canonical System-33 link state.

### Existing System 33 remains service authority

System 33 still decides whether a consumer has power. Stage B does not create a second `powered` flag on poles, wires or render records. It changes canonical System-33 link state when a real physical distribution failure requires it.

### Rendering owns presentation only

`PowerLinePresentationRenderer` draws cached physical topology. Energized/damaged state does not decide whether a cable exists visually.

---

## 3. Global planning contract extension

`GlobalPowerInfrastructurePlanner` now routes physical power in the same causal hierarchy used by runtime service truth:

`regional ingress -> substation -> settlement distribution`

Each generated `power_segment` retains the existing stable geometry/provenance fields and additionally records:

- `service_settlement_ids: Array[String]`

This array is the deterministic set of settlements downstream of that physical feeder edge.

The regional trunk from ingress to substation carries all settlement IDs. A settlement-specific branch carries only the settlement IDs actually dependent on it.

This mapping is created once during deterministic global planning. Runtime damage therefore does not need to rediscover graph topology, flood-fill the grid or scan the world.

---

## 4. Physical asset identity

`UtilityPowerInfrastructureMaterializer` remains a one-time physical projection of canonical 00D4 distribution topology.

Each visible wire span now receives a stable asset ID:

`power.asset.span.<segment-token>.<span-ordinal>`

Each persistent physical support keeps its existing stable WHAT entity ID:

`power.physical.<segment-token>.support.<ordinal>`

The cached wire record carries:

- `asset_id`;
- `start_id`;
- `end_id`;
- `network_id`;
- `power_class`;
- `segment_id`;
- `service_settlement_ids`.

Supports are real persistent WHAT entities. Wire spans are stable physical-network records projected between those real support placements.

---

## 5. Facility truth correction

The older distribution materializer created small generic equipment clusters around `regional_ingress` and `substation` planning nodes. Stage B removes those clusters.

Reason: a future power plant / regional supply facility and a real substation require their own proper streamed facility generation. Repeated transformers and utility boxes around abstract planning coordinates would be fake facility truth.

Current rule:

- regional ingress/substation remain real **planning + runtime topology identities**;
- Stage B does not pretend their final tactical facility geometry exists;
- settlement-service distribution hardware remains physicalized because it is legitimate local distribution equipment;
- future facility generation must consume the existing stable planning identities rather than inventing a second source/substation owner.

---

## 6. Shared physical utility condition substrate

`UtilityNetworkConditionStore` is a data-only reusable condition owner intended for physical utility networks.

Current power asset kinds:

- `distribution_support`;
- `distribution_span`.

Each record stores only durable event anchors and deterministic parameters needed to derive current condition, including:

- stable asset identity;
- kind;
- section identity;
- optional persistent entity identity;
- condition at the last event;
- wear anchor/start tick;
- deterministic wear rate;
- failure threshold;
- last damage source.

Condition is derived analytically from authoritative world time.

No asset receives:

- a Node;
- a Timer;
- `_process()`;
- a scheduled event per asset;
- a daily update record;
- recurring mutation merely because time advances.

Power is the first consumer. Future water infrastructure should reuse this substrate where the same condition model is appropriate rather than creating a parallel wear architecture.

---

## 7. Deterministic initial condition and wear

Virgin physical distribution assets receive deterministic initial condition and wear rates from stable asset identity.

The implementation currently uses a one-day grace before analytic wear begins. Current condition is then derived from elapsed authoritative ticks and the asset's wear rate.

A failed asset is one whose derived condition reaches its failure threshold.

This is intentionally a reduced internal model: it creates persistent maintenance history and eventual infrastructure degradation without pretending to be detailed conductor corrosion, pole rot, transformer loading or weather physics.

Future explicit damage sources may still apply immediate condition loss through the same canonical mutation seam.

---

## 8. Efficient unattended failure observation

Analytic condition alone is not enough: a failure that occurs while no one is inspecting the line still has to become a real outage.

`UtilityPowerNetworkRuntime` therefore maintains one sorted threshold schedule containing each asset's next predicted failure tick.

Ordinary authoritative time advancement performs only the cheapest possible check:

- inspect the earliest scheduled threshold;
- if it is later than the new world tick, stop;
- if one or more thresholds were crossed, process only those due assets;
- refresh only the services mapped to those assets.

There is no loop over simulated days and no loop over every grid asset on each ordinary tick advance.

The schedule is rebuilt/rescheduled only when initialization, restore, damage or repair changes predicted thresholds.

---

## 9. Service consequence mapping

During initialization, each physical span/support records the real System-33 power service IDs corresponding to its `service_settlement_ids`.

For each power service, the runtime therefore has the bounded set of physical assets that can interrupt that service.

When one asset fails:

1. inspect only the service IDs mapped to that asset;
2. for each mapped service, determine whether any of its mapped distribution assets are currently failed;
3. if failed, set the existing System-33 settlement distribution link to `DAMAGED`;
4. if no mapped asset remains failed and Stage B itself owns the block, restore that link to `OPERATIONAL`.

The canonical runtime link currently used for physical settlement-distribution failure is:

`power.link.substation_to.<settlement_id>`

The existing upstream/downstream System-33 derivation then naturally propagates consequences to lighting, refrigeration and electrically dependent water pumps.

Stage B does not directly toggle those consumers.

---

## 10. Damage API

The live composition exposes a narrow event-driven seam:

`damage_power_infrastructure(asset_id, damage, source_kind)`

A damage event:

- derives condition at the authoritative current tick;
- subtracts the explicit damage amount;
- re-anchors future wear from that event;
- reschedules only that asset's predicted failure;
- reevaluates only its mapped services.

The current canonical code supports explicit source labels such as `vehicle`, but Stage B does **not** claim that vehicle collision/combat/weather interaction generators are implemented. Those later systems may call the same seam when they own a real damage event.

---

## 11. Repair seam

The live composition exposes:

- `power_infrastructure_repair_requirements(asset_id)`;
- `repair_power_infrastructure(asset_id, electrical_skill, available_material_units)`.

Current low-tier requirements are deliberately small foundation values:

- distribution span: Electrical 2 + 1 material unit;
- distribution support: Electrical 2 + 2 material units.

Successful repair restores a high condition anchor, reschedules that asset and reevaluates only its mapped services.

This is the **mechanical repair seam**, not the final user-facing Phase-6 repair action. It does not yet claim inventory consumption, WHEN action duration, UI flow, tool requirements, interruption behavior or final skill balance. Those systems must call this existing truth rather than create a second repair model.

---

## 12. Snapshot / persistence

The physical condition store has its own schema-backed snapshot containing durable asset condition records and revision state.

`UtilityPowerNetworkRuntime` snapshots/restores the condition store, rebuilds its derived failure schedule, and resynchronizes affected System-33 service truth after restore.

Derived schedules and service lookup indices are rebuildable caches and are not independent persistent truth.

Streaming does not heal failed assets.

---

## 13. Presentation independence

A failed cable remains a cable.

`UtilityGameMain` passes the same physical wire projection to presentation regardless of energized state. `PowerLinePresentationRenderer` never asks whether the service is powered before drawing an existing span.

Stage B also hardens renderer invalidation:

- endpoint IDs are indexed once in `_wire_endpoint_ids`;
- unrelated `WorldChange` events are ignored in O(1) lookup;
- visible-wire geometry is rebuilt only when a real wire endpoint changes/reset/view window changes.

No renderer work becomes simulation authority.

---

## 14. Performance contract

Stage B fails its architecture gate if later changes introduce any of the following:

- per-frame utility condition simulation;
- per-tick loops over all distribution assets;
- per-day catch-up loops;
- one timer/scheduled event/Node per persistent utility asset;
- whole-world scans to rediscover downstream topology after damage;
- camera/streaming visibility as a condition or service authority;
- renderer-driven outage state;
- consumer-specific blackout mutations that bypass System 33.

Preferred future extension remains:

- analytic condition;
- one minimal next-threshold structure per network owner;
- explicit event-driven damage/repair;
- bounded section/service invalidation;
- cached deterministic topology mappings.

---

## 15. Automated verification

Dedicated physical-network coverage: `System33PowerPhysicalNetworkSmoke.gd`.

It proves:

1. generated physical distribution receives stable causal service mapping;
2. one settlement-specific span can be selected deterministically;
3. direct physical damage fails that span;
4. the mapped downstream System-33 service loses power;
5. an unrelated sibling service remains energized;
6. the failed cable remains in the presentation topology;
7. low-tier span repair requirements are exposed;
8. repair restores the affected service;
9. the next unattended wear failure is predicted analytically;
10. jumping directly to that threshold creates a real failed asset and canonical outage without iterating days;
11. physical supports use the same shared condition substrate;
12. support repair material cost is distinct from span repair.

`System33PowerInfrastructureSmoke.gd` additionally proves stable span asset IDs, service mapping, real endpoint placement, constructed-vehicle-surface rejection and removal of fake regional/substation equipment clusters.

Exact executable `7ddee8df0e638cbe14897d83632b62513d5fc574` is green across all published contexts, including:

- `verify/system33-power-water`;
- `verify/system33-lighting-truth`;
- `verify/system27-physical-lighting`;
- `verify/system25-world-time-light`;
- `verify/system00d-global-world`;
- `verify/system00f-streaming-materialization`;
- `verify/system19-local-building`;
- `verify/system20-local-area`;
- `verify/system23-perception`;
- `verify/system28-weather`;
- `verify/system30-item-freshness`;
- `verify/system32-crafting`;
- `verify/performance-architecture`;
- `verify/pages-deploy`;
- all other published exact-head checks.

---

## 16. Human playtest gate

Stage B is automated-green but is not marked HUMAN ACCEPTED until browser play confirms the resulting build remains good.

Human checks should focus on:

1. ordinary movement/turning remains responsive and the earlier black-screen regression does not return;
2. poles/streetlights remain correctly placed off constructed vehicle surfaces;
3. overhead cables remain visible and visually stable;
4. ordinary powered lights still work normally;
5. a future exposed/manual physical-line damage test blacks out only the expected downstream branch rather than the whole world;
6. restoring the physical asset restores the affected branch;
7. no unexplained recurring hitch appears as world time advances.

The existing accepted full-window lighting/LOS/input lineage remains protected.

---

## 17. Explicitly deferred

Stage B does not yet implement:

- final tactical power plant geometry;
- final tactical substation facility geometry;
- player targeting/interaction UI for cutting a wire or damaging a pole;
- vehicle collision damage generation;
- tree-fall/weather/combat/explosion damage generation;
- electrocution/fire/arc hazards;
- breaker/load/voltage simulation;
- generator/solar/battery islanding;
- final repair action duration, inventory/tool consumption or Phase-6 skill balance;
- AI repair/sabotage behavior;
- detailed water-pipe physicalization.

These later systems must consume the current physical asset/service seams rather than replace them with parallel truth.
