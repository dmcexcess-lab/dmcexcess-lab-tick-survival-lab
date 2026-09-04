# Tick Survival Lab — System 33 Power / Water Utility Runtime

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED; HUMAN RETEST PENDING**

Current verified executable: `6aab0596cb46d70d4739cbc045d149a25597193d`

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

`UtilityLocalPowerTopologyPlanner` consumes the actual deterministic local-area/building manifests and groups generated buildings into service groups targeting **10 buildings per substation**. The count scales with generated content; there is no fixed island substation count and there is no requirement that every global small-town site already contain a legacy substation node.

System 20 may project regional power corridors/service facts through a small town even when no global substation node lies inside that site's bounds. The real neighborhood substations are derived afterward from the generated building manifest; local generation therefore never invents or requires a one-substation-per-town placeholder.

Each group receives stable local identities for:

- a substation service;
- a substation component;
- a feeder component;
- a structure-service terminal;
- the generated buildings served by that group.

The regional source/ingress to each local substation is a **logical non-physical link**. The game does not draw or materialize long-distance source-to-substation transmission lines.

### Shared roadside distribution topology

Each substation feeds its served buildings through **one shared road-following feeder tree**, not a transformer-to-house starburst.

`NeighborhoodPowerInfrastructureMaterializer` builds a graph from the centerlines of the actual generated `local_roads`, chooses the reachable road cell nearest the substation as the distribution root, and computes deterministic root-to-customer-tap paths. Those customer paths are unioned before physicalization, so any road section used by multiple buildings becomes one shared physical trunk rather than duplicated overlapping wires.

Physical roadside poles are placed off the road surface at the feeder root, customer taps, turns, junctions and deterministic spacing points. Pole placement also consumes the real generated parcel-access surfaces: driveway and parking/access cells are hard exclusions and cannot receive a support pole. This keeps supports off the narrow paved/gray access strips that connect parcels to the road rather than trying to infer those surfaces from rendered pixels.

Pole side is resolved root-outward along each straight feeder progression instead of independently at every support. A child support first inherits its parent span's physical side of the road. If that side has no legal support location and the line must cross, the new side is held for the next **two sequential pole placements** before an elective cross-back is allowed. Turns and real topology junctions may establish a new routing direction; the side-hold rule does not invent extra forks or change the logical feeder tree. Existing stable pole IDs remain tied to the deterministic route-cell ordering even though physical placement is resolved root-outward.

The materialized electrical path is therefore:

1. one short `substation_lead` from the transformer to the shared road-root pole;
2. deduplicated `shared_trunk` spans following the generated road network pole-to-pole;
3. forks only where the road/customer topology actually requires them;
4. one short final `service_drop` from a shared roadside tap to a customer pole near each real generated building.

There are **no direct substation-to-every-house rays**. Common route sections genuinely reuse the same poles and wire spans, and each final service drop retains the identity of the actual building it serves.

## 3. Physical substations

Each local substation is a small fenced utility compound, not a fake power-plant structure. Current persistent WHAT materialization contains:

- one transformer;
- two utility boxes;
- chain-link fencing with an opening.

Substation placement searches for a legal nearby facility footprint that does not overlap buildings, planned/local road surfaces, blocked outdoor props or existing world entities.

## 4. Physical power-line condition and daily snap rule

Visible shared-trunk and service-drop spans/supports have stable physical identities and persistent condition. Direct damage and repair use the same authoritative condition/service path.

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

### Player-facing physical support repair

The low-level condition seam is now connected to ordinary player interaction for failed persistent **distribution supports**.

A clicked power pole is the same persistent WHAT entity registered with the power network as a `distribution_support`; the interaction layer does not create another condition record. `UtilityPowerRepairInteractionOfferProvider` only offers REPAIR when that exact canonical asset is currently failed, and `UtilityPowerRepairActionService` commits through `UtilityPowerNetworkRuntime`.

The current wooden-pole player profile requires:

- a real carried hammer, retained;
- two real carried wood-plank entities, consumed;
- one real carried nails-box entity, consumed;
- the player-facing Mechanical requirement;
- real WHEN duration/completion.

The action snapshots the canonical utility runtime before commit and restores it on failure, so utility condition, service outage and carried-resource mutation cannot diverge as a partially committed repair. A successful repair restores the physical asset and only the outage state causally owned by that fault. A healthy pole immediately ceases to expose REPAIR.

Distribution **spans** remain real condition assets and retain their low-level repair seam, but they do not yet have an independent player-clickable WHAT identity. Therefore current ordinary player-facing utility repair is deliberately support-only rather than inventing a click target for a wire.

## 5. Municipal water

The current global water contract is one **island-wide municipal treatment facility** near the shore.

The municipal runtime has one source -> treatment -> distribution-header chain shared by every settlement service. Municipal service records are explicitly `island_wide_municipal`; there is no service radius and no simulated long-distance municipal pipe network.

`NeighborhoodUtilityRuntimeState.water_service_for_cell()` resolves municipal service from the island-wide settlement-service records rather than using the retired plant-radius model. A generated small-town or rural settlement cell can therefore resolve its real municipal service even when the plant and its internal nodes are elsewhere on the island.

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

Current low-level mechanical material requirements:

- municipal plant: 3 material units;
- private well: 1 material unit.

These remain low-level owner seams. They are not yet ordinary player-facing exact carried-resource actions and must not be presented as such until their physical target/tool/material routes are connected through the same truthful interaction pipeline.

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

The player-facing support repair reuses this same snapshot/restore contract transactionally; it does not add a UI-layer rollback or duplicate utility state.

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
- small-town generation when regional service exists but no legacy global substation node is inside the site;
- zero direct substation-to-customer starburst spans;
- exactly one final service drop per generated served building;
- roadside shared-trunk spans tied to real generated-road centerline cells;
- shared path deduplication and actual pole reuse across multiple wire edges;
- physical network damage/repair and daily snap behavior;
- island-wide municipal water cell/service lookup without radius inference;
- plant/well service truth;
- complete island planning;
- System-27 physical lighting;
- System-30 freshness;
- performance architecture;
- player input responsiveness;
- canonical startup.

The dedicated `verify/system33-roadside-pole-routing` contract additionally proves that generated driveway/parking access cells are carried into utility pole exclusions, real materialized local power poles do not occupy those cells, an obstructed support can remain on its current legal side, a genuinely forced crossing moves to the opposite side, and the next two straight-route supports cannot immediately cross back. It also scans the real shared-trunk materialization for the same side-hold behavior.

Player-facing repair is additionally protected by `game/scripts/ci/UtilityPowerRepairUiSmoke.gd` inside `verify/world-interaction-closure`: it damages a real physical support, proves the corresponding outage, drives the real pointer/chooser REPAIR route, proves exact carried-resource consumption and WHEN completion, proves canonical condition/service restoration, and proves that the repaired healthy support no longer offers REPAIR.

Verified executable: `6aab0596cb46d70d4739cbc045d149a25597193d`. On that exact head `verify/system33-power-water`, `verify/world-interaction-closure` (run `33915077349`), protected neighboring statuses and `verify/pages-deploy` (run `33915077391`) are green.

## 13. Human acceptance

Automated verification is green. Browser play should still verify the visible/game-feel result:

1. substations appear as small fenced electrical compounds and scale roughly one per ten generated buildings;
2. no fake long-distance line is drawn from the regional source/power plant to substations;
3. each substation's local distribution leaves as a shared roadside feeder tree rather than separate rays to every house;
4. common route sections visibly reuse one set of poles/wires and forks occur only where needed;
5. roadside support poles do not land on generated driveway/parking/access strips, and a feeder that crosses the road stays on the new side for two subsequent support placements before an elective cross-back;
6. final service drops terminate near the real buildings they serve;
7. line failure causes the expected local blackout and a failed wooden pole can be repaired through the ordinary chooser using the exact carried resources, restoring the causally affected service;
8. the municipal water plant exists physically and a plant failure removes island-wide municipal water;
9. ordinary grid loss does not disable the municipal plant;
10. a deterministic minority of rural homes have real private wells and powered-well failure behaves correctly;
11. no black-screen, first-step hitch growth or input-backlog regression returns, with phone/Safari remaining first-class.

Do not mark Phase 3 HUMAN ACCEPTED solely from CI.
