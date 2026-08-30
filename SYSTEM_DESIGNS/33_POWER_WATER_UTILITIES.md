# Tick Survival Lab — System 33 Power / Water Utility Runtime

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED; HUMAN RETEST PENDING**

Current verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`

Roadmap phase: **Phase 3 — Power and Water**

Upstream planning:

- `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`
- `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`

Physical-network extension: `33B_POWER_PHYSICAL_NETWORK_CONDITION.md`

## 1. Authority

System 33 owns current utility service truth and persistent utility condition. Planning and materialization may provide identities/geometry, but consumers never infer power or water from sprites, brightness, distance from a plant, or UI state.

> **Real infrastructure creates real service paths; System 33 owns whether those paths currently work.**

Wastewater/sewer/septic is not an active System-33 domain.

## 2. Current power model

The playable island uses generated local distribution rather than one fake island substation.

`UtilityLocalPowerTopologyPlanner` consumes the actual deterministic local-area/building manifests and groups generated buildings into service groups targeting **10 buildings per substation**. The count scales with generated content; there is no fixed island substation count.

Each group receives stable local identities for:

- a substation service;
- a substation component;
- a feeder component;
- a structure-service terminal;
- the generated buildings served by that group.

The regional source/ingress to each local substation is a **logical non-physical link**. The game does not draw or materialize long-distance source-to-substation transmission lines.

From each substation, real local distribution is physicalized to customer poles placed near the served building envelopes. Visible wire spans run from the substation transformer to those near-building poles. A service drop therefore terminates close to each real generated building rather than at an abstract settlement center.

## 3. Physical substations

Each local substation is a small fenced utility compound, not a fake power-plant structure. Current persistent WHAT materialization contains:

- one transformer;
- two utility boxes;
- chain-link fencing with an opening.

Substation placement searches for a legal nearby facility footprint that does not overlap buildings, planned/local road surfaces, blocked outdoor props or existing world entities.

## 4. Physical power-line condition and daily snap rule

Visible distribution spans/supports have stable physical identities and persistent condition. Direct damage and repair use the same authoritative condition/service path.

Automatic line failure is intentionally simple and day-boundary driven:

- one deterministic pass per authoritative game day;
- base chance per eligible span: **100 / 1,000,000 = 0.01%**;
- each no-snap day adds **100 / 1,000,000 = 0.01%**;
- chance caps at **10,000 / 1,000,000 = 1.00%**;
- the first successful span snap ends that day's pass;
- a snap resets quiet-day accumulation;
- the roll is deterministic from day index + stable span ID;
- failed spans are skipped;
- the snapped real span becomes failed condition and its mapped System-33 service link becomes damaged;
- repair restores only outage state owned by the failed physical asset.

The runtime emits `line_snapped(asset_id, cell)` for the real failed span. Live composition routes the event through the spatial-sound system as `*SNAP*` rather than creating audio playback.

There is no continuous analytic wear scheduler, per-span Node, per-span Timer, render-frame utility simulation or recurring whole-world scan.

## 5. Municipal water

The current global water contract is one **island-wide municipal treatment facility** near the shore.

The municipal runtime has one source -> treatment -> distribution-header chain shared by every settlement service. Municipal service records are explicitly `island_wide_municipal`; there is no service radius and no simulated long-distance municipal pipe network.

The plant's stable critical asset is real persistent world truth. Current physical materialization is a small fenced utility facility containing a shed/plant body, tank-like storage, industrial machinery and a utility box.

If the critical municipal plant asset fails, every municipal settlement service loses water. Repair restores the same shared service chain.

### Municipal plant power rule

The municipal plant **does not require external grid power**. Its water components/bindings have no required power-service ID. A grid outage by itself must not disable island-wide municipal water.

## 6. Rural private wells

System 33 selects wells from the **actual generated rural residential building manifest**, not from settlement-radius intent.

Current deterministic target:

- nominal target: **15%** of rural homes;
- accepted range: **10–20%** when enough rural homes exist;
- selection seed: world seed + stable building identity.

Every selected well has:

- a stable physical asset/entity ID;
- a stable water component and private service ID;
- a real placement adjacent to its owning generated building;
- persistent condition and repair state;
- a dependency on that building group's real electrical service.

The current visible ground-cap semantic reuses existing final prop art while stable System-33 identity carries actual well truth. Wells are not UI-only markers.

`water_service_for_building()` prefers a working private well for that building; otherwise the building can use its settlement's island-wide municipal service.

## 7. Water asset condition and repair

Municipal plant and private wells carry persistent physical condition. Current failure threshold is 250 from an initial condition of 1000; successful repair restores condition to 900.

Current mechanical material requirements:

- municipal plant: 3 material units;
- private well: 1 material unit.

These are low-level repair seams, not final Phase-6 player action/tool/skill balance.

## 8. Lighting and refrigeration consumers

System 33 remains the service owner used by:

- real fixed System-27 light emitters;
- persistent non-bloom `fixture.room_light` entities generated for rooms;
- real hand-equipped flashlight truth;
- System-30 refrigerator cold-storage availability.

A power outage changes these consumers through service queries/events. Rendering, light presentation and freshness never own a parallel utility switch.

## 9. Persistent state and caching

Utility state uses typed power/water components, links, bindings, appliance records and revisions. Service is derived from bounded upstream chains and cached by revision.

Snapshot/restore preserves durable utility state and physical asset condition; derived caches are rebuilt. Streaming does not heal failed infrastructure.

## 10. Performance contract

Forbidden patterns include:

- utility `_process()` loops;
- per-component/per-span/per-room timers;
- whole-world utility scans on ordinary player actions;
- render/camera-driven service recomputation;
- technical streaming state defining utility existence.

The local topology is planned once from deterministic generated content. Daily line snaps are processed only when authoritative time crosses a day boundary. Local mutations invalidate only relevant cached/service state.

## 11. Wastewater boundary

There is **no wastewater/sewer/septic gameplay or live planning dependency**. `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is a retired historical record. Do not couple municipal water, private wells, local-area generation or utility CI back to wastewater.

## 12. Verification contract

`verify/system33-power-water` proves the current utility and physical-network behavior and protects:

- project import/parse;
- System-33 power/water smoke;
- generated local substation/customer topology;
- physical network damage/repair and daily snap behavior;
- plant/well service truth;
- complete island planning;
- System-27 physical lighting;
- System-30 freshness;
- performance architecture;
- player input responsiveness;
- canonical startup.

The broader global-world-planning contract independently proves profile v7, island-wide municipal water projection, complete-island planning, island seam integrity and System-20 projection/local generation.

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`.

## 13. Human acceptance

Automated verification is green. Browser play should still verify the visible/game-feel result:

1. substations appear as small fenced electrical compounds and scale roughly one per ten generated buildings;
2. no fake long-distance line is drawn from the regional source/power plant to substations;
3. local wires originate at substations and terminate near the buildings they serve;
4. line failure causes the expected local blackout and repair restores it;
5. the municipal water plant exists physically and a plant failure removes island-wide municipal water;
6. ordinary grid loss does not disable the municipal plant;
7. a deterministic minority of rural homes have real private wells and powered-well failure behaves correctly;
8. lighting/refrigeration consequences remain truthful;
9. no black-screen, first-step hitch growth or input-backlog regression returns;
10. phone/Safari remains first-class.

Do not mark Phase 3 HUMAN ACCEPTED solely from CI.
