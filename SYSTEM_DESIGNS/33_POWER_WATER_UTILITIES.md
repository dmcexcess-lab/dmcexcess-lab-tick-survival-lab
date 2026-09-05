# Tick Survival Lab — System 33 Power / Water Utility Runtime

Status: **IMPLEMENTED; TARGETED EXACT-HEAD AUTOMATED VERIFIED; HUMAN RETEST PENDING**

Current verified water/well executable: `4ced86b353d273d54b89e0fb52499f564172364b`

Roadmap phase: **Phase 3 — Power and Water**

Upstream planning:

- `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`
- `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`

Physical-network extension: `33B_POWER_PHYSICAL_NETWORK_CONDITION.md`

## 1. Authority

System 33 owns current utility service truth and persistent utility condition. Planning and materialization may provide identities/geometry, but consumers never infer power or water from sprites, brightness, distance from a facility, or UI state.

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

The low-level condition seam is connected to ordinary player interaction for failed persistent **distribution supports**.

A clicked power pole is the same persistent WHAT entity registered with the power network as a `distribution_support`; the interaction layer does not create another condition record. `UtilityPowerRepairInteractionOfferProvider` only offers REPAIR when that exact canonical asset is currently failed, and `UtilityPowerRepairActionService` commits through `UtilityPowerNetworkRuntime`.

The current wooden-pole player profile requires:

- a real carried hammer, retained;
- two real carried wood-plank entities, consumed;
- one real carried nails-box entity, consumed;
- the player-facing Mechanical requirement;
- real WHEN duration/completion.

The action snapshots the canonical utility runtime before commit and restores it on failure, so utility condition, service outage and carried-resource mutation cannot diverge as a partially committed repair. A successful repair restores the physical asset and only the outage state causally owned by that fault. A healthy pole immediately ceases to expose REPAIR.

Distribution **spans** remain real condition assets and retain their low-level repair seam, but they do not yet have an independent player-clickable WHAT identity. Therefore current ordinary player-facing utility repair is deliberately support-only rather than inventing a click target for a wire.

## 5. Municipal water — one real building

The current municipal contract is deliberately simple:

> **One already-generated real building is the island's municipal water facility. If it works, municipal water works island-wide. If it fails, municipal water is off island-wide.**

System 00D5 provides lightweight per-settlement service references, but every reference resolves to the same facility identity and the same System-33 source component. There is no water-node graph, no water-link graph, no pipe routing, no simulated distribution header and no service radius.

`NeighborhoodUtilityRuntimeState` resolves the selected host from the global structural building manifest and uses that existing generated building as the one `municipal_plant` asset. `NeighborhoodPowerInfrastructureMaterializer` must **not** create a duplicate water-treatment shed, tank complex or second facility entity.

`water_service_for_settlement()` and ordinary non-well `water_service_for_building()` resolve one of the settlement aliases to this same island facility. A generated building therefore has municipal service because the shared facility is operational, not because a pipe reaches its cell.

If the facility building is damaged below the water failure threshold, every municipal alias becomes unavailable. Repair of the same real facility building restores municipal service island-wide.

### Municipal facility power rule

The municipal facility **does not require external grid power**. Its water component/bindings have no required power-service ID. A grid outage by itself must not disable island-wide municipal water.

## 6. Rural private wells

System 33 selects private wells from the **actual generated rural-building manifest**. Candidate status is based on the building's rural area site; it is not restricted to a residential archetype and it never applies to town/non-rural buildings.

Current deterministic rule:

- selected count is within **10–20% of generated rural buildings** when enough rural buildings exist for the range to be meaningful;
- both count and selection are deterministic from world seed + stable building identity;
- one selected building receives at most one well;
- every selected well has a stable asset ID, component ID and private service ID;
- the well is placed as a real persistent visible ground-cap entity adjacent to its owning generated building;
- the well has persistent condition and repair state;
- the well has **no required external power service**.

### Authoritative-source rule

For a selected well building, the private well **replaces municipal water** as that building's authoritative source.

`well_service_for_building(building_id)` returns that stable private service. `water_service_for_building(building_id)` returns the same private service whether the well is currently working or broken.

Consequences:

- a healthy well building has private water;
- a municipal-facility outage does not remove water from a healthy private-well building;
- damaging the well makes that private service unavailable;
- the building then has **no water** until the well is repaired;
- a broken well does **not** fall back to municipal service;
- repair restores the same private service identity;
- rural buildings without wells and all town buildings remain municipal-water buildings.

This is source ownership, not a preference order. Availability and source identity are separate truths.

## 7. Water asset condition and repair

The municipal facility building and private wells carry persistent physical condition. Current failure threshold is 250 from an initial condition of 1000; successful repair restores condition to 900.

Current low-level mechanical material requirements:

- municipal facility: 3 material units;
- private well: 1 material unit.

Snapshot/restore preserves municipal and private-well condition plus the stable binding identities. Restoring a snapshot rebuilds the derived private-well building index rather than rerolling selection.

These repair methods remain low-level owner seams. They are not yet ordinary player-facing exact carried-resource actions and must not be presented as such until their physical target/tool/material routes are connected through the truthful interaction pipeline.

## 8. Lighting and refrigeration consumers

System 33 remains the service owner used by:

- real fixed System-27 light emitters;
- persistent non-bloom `fixture.room_light` entities generated for rooms;
- real hand-equipped flashlight truth;
- System-30 refrigerator cold-storage availability.

A power outage changes these consumers through service queries/events. Rendering, light presentation and freshness never own a parallel utility switch.

## 9. Persistent state and caching

Utility state uses typed power/water components, links/bindings where appropriate, appliance records and revisions. Municipal water specifically uses one source component and settlement bindings with **zero physical water links**; private wells each use one local source component/binding.

Service is derived from bounded authoritative state and cached by revision. Snapshot/restore preserves durable utility state and physical asset condition; derived caches are rebuilt. Streaming does not heal failed infrastructure.

The player-facing power-support repair reuses this same snapshot/restore contract transactionally; it does not add a UI-layer rollback or duplicate utility state.

## 10. Performance contract

Forbidden patterns include:

- utility `_process()` loops;
- per-component/per-span/per-room timers;
- whole-world utility scans on ordinary player actions;
- render/camera-driven service recomputation;
- technical streaming state defining utility existence.

The local topology is planned once from deterministic generated content. Rural-well selection happens in that one-shot planning pass. Daily line snaps are processed only when authoritative time crosses a day boundary. Local mutations invalidate only relevant cached/service state.

## 11. Wastewater boundary

There is **no wastewater/sewer/septic gameplay or live planning dependency**. `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is a retired historical record. Do not couple municipal water, private wells, local-area generation or utility CI back to wastewater.

## 12. Verification contract

`verify/system33-power-water` is the owning water/well contract. On executable `4ced86b353d273d54b89e0fb52499f564172364b`, run `33988514222` succeeded. It proves, among the current utility checks:

- project import/parse;
- generated local power topology remains consumable by System 33;
- municipal water has no node/segment graph;
- wastewater arrays remain absent;
- exactly one existing generated building is the authoritative municipal facility asset;
- municipal facility failure removes municipal service island-wide and repair restores it;
- municipal water is independent of outside-grid power;
- deterministic private-well selection lands within 10–20% of rural buildings;
- only rural buildings receive private wells;
- same seed replays the same selected wells;
- every selected well maps directly to its owning building;
- wells have no grid-power dependency;
- a private well survives municipal failure;
- a damaged well leaves its building dry rather than falling back to municipal water;
- well repair restores that same private source;
- utility snapshots preserve the current water truth.

The physical-infrastructure smoke additionally proves the municipal facility is an already generated building, no duplicate municipal shed is materialized, and every selected private well receives its persistent visible well-cap entity.

`verify/pages-deploy` run `33988514204` also succeeded for that exact executable.

### Known unrelated/pre-existing red checks

Do **not** describe the entire `4ced86...` repository suite as green. Several other checks were already failing around this development line. In particular, `verify/system33-roadside-pole-routing` fails its shared-trunk two-pole side-hold assertion on `4ced86...`, and the same check was already failing on pre-well parent `12bcdcd40a7f6ab45ecd2bfa3424e10dfff61935`. That is a separate power-routing defect, not evidence of a private-well failure and not part of this water-contract completion.

## 13. Human acceptance

Automated water/well verification is green. Browser play should still verify the visible/game-feel result:

1. substations appear as small fenced electrical compounds and local distribution remains readable;
2. no fake long-distance source-to-substation line is drawn;
3. the one municipal-water facility is an existing generated building, with no duplicate treatment shed/tank facility beside it;
4. damaging that facility removes municipal water island-wide while grid loss alone does not;
5. roughly 10–20% of rural buildings receive visible private well caps for a given generated island;
6. town buildings never receive private wells;
7. a well building retains water during municipal failure;
8. a broken well building is dry and does not silently switch to municipal water;
9. repairing the well restores that building's private water;
10. no wastewater, pipe-network or radius behavior appears;
11. no black-screen, first-step hitch growth or input-backlog regression returns, with phone/Safari remaining first-class.

Do not mark Phase 3 HUMAN ACCEPTED solely from CI.
