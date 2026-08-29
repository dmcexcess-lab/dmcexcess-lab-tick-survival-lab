# Tick Survival Lab — System 33 Power / Water Utility Runtime

Status: **DRAFT — DESCRIBE complete; explicit approval required before runtime implementation**

Roadmap phase: **Phase 3 — Power and Water**

Upstream planning contracts:

- `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`
- `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`

Primary downstream contracts:

- `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md`
- `30_ITEM_FRESHNESS_SPOILAGE.md`
- existing WHAT / WHEN / interaction foundations

---

## 1. Goal

Create the first persistent runtime utility model for the playable world.

System 00D already answers **where utility infrastructure is planned**. System 33 answers **whether that infrastructure is currently able to provide service** and exposes that truth to real world consumers.

The target is intentionally smaller than a full electrical or hydraulic simulator. The game needs causal outages, local consequences, persistent repair seams and future expansion points without paying for load-flow mathematics, pressure solvers or recurring whole-network simulation.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

---

## 2. Non-negotiable gameplay result

Phase 3 must make utility failure spatial and causal rather than one global switch.

A failure near one structure may darken or disable that structure while another remains supplied. A settlement feeder failure may affect a broader area. A major source failure may affect everything downstream.

Water follows the same principle, with one additional dependency: an electrically driven pump cannot provide water when its required power service is unavailable.

The player should be able to reason from the world:

- this branch is down, therefore these buildings lost service;
- this pump has no power, therefore this water service is unavailable;
- this refrigerator lost power, therefore it is no longer cold storage;
- this fixed light has no power, therefore System 27 receives no active emitter from it.

---

## 3. Ownership

System 33 owns:

- persistent runtime operational state for power infrastructure;
- persistent runtime operational state for potable-water infrastructure;
- stable bindings from planned/local service points to runtime utility identities;
- deterministic service derivation through required upstream components/links;
- cached service results and utility revisions;
- explicit mutation APIs for utility component/link state;
- power dependency of electrically driven water pumps;
- persistent on/off state for fixed utility-powered appliance/fixture consumers where that state is necessary to determine service use;
- read-only service query APIs for downstream systems;
- snapshot/restore of its typed durable state;
- change notifications sufficient for downstream invalidation.

System 33 does **not** own:

- global geography or placement of utility corridors — System 00D owns planning;
- procedural building grammar — Systems 19/20 own local generated form;
- rendering, light sprites or glow — presentation systems own those;
- physical illumination math — System 27 owns it;
- item freshness math — System 30 owns it;
- hunger, thirst, drinking consequences or nutrition — Phase 4 owns those;
- liquid item/container simulation unless separately designed later;
- repair skill checks — final Mechanical/Electrical skills arrive in Phase 6;
- vehicle collisions or combat damage generation — later systems may call System 33 mutation APIs;
- automatic random outages;
- electrical load balancing, amperage, voltage drop, breaker-panel simulation or individual wire circuits;
- hydraulic pressure, flow-rate, pipe diameter or contamination simulation;
- wastewater/sewer gameplay;
- portable battery/fuel equipment truth unless separately approved.

---

## 4. Dependency direction

System 33 may read:

- stable System-00D electrical/water planning identities and topology facts;
- WHAT stable entity/structure identities where local consumers are real entities;
- local materialization/building facts only to establish deterministic service bindings;
- authoritative WHEN/world-time state only when an explicit timed utility action later needs it.

System 33 may publish read-only state to:

- System 27 fixed-light source integration;
- System 30 cold-storage exposure integration;
- System 29 inspection/interaction offers;
- future repair, construction, AI and survival systems.

System 33 may not depend on:

- render frames;
- camera position;
- art atlas selection;
- player UI state;
- a consumer's visual brightness;
- streamed-node existence as proof that infrastructure exists.

Technical streaming never defines utility existence.

---

## 5. Runtime topology: three causal tiers

The roadmap's three-tier model remains canonical. The implementation should preserve these semantic tiers without requiring a generic arbitrary graph engine.

### 5.1 Power

**Tier 1 — regional source / major supply**

Represents broad incoming generation/supply planned by 00D4.

**Tier 2 — substation / settlement feeder**

Represents the planned substation and settlement-level service path.

**Tier 3 — local branch / structure service**

Represents the final service path from settlement distribution to a structure or local consumer group.

A structure is powered only if every required upstream power component/link on its resolved service path is operational.

### 5.2 Potable water

**Tier 1 — source + treatment/storage**

Represents the planned municipal groundwater/source and treatment/storage chain where applicable.

**Tier 2 — pump/distribution / settlement service**

Represents settlement-level distribution and any required pumping.

**Tier 3 — property / structure service**

Represents the final local potable-water service endpoint.

A water endpoint has service only if every required upstream water component/link is operational **and** every electrically driven pump on that service path currently has required power.

### 5.3 Rural decentralized water

00D5 already describes rural decentralized source intent rather than pretending every rural site is municipally piped.

Candidate 001 may materialize a deterministic private/shared well service for rural properties where the existing planning/local-generation facts call for one.

A rural electrically pumped well is intentionally compact:

- the source/well exists as a persistent utility component;
- the pump has an operational state;
- the pump has a power-service dependency;
- the property water endpoint derives availability from those facts.

No groundwater depletion or aquifer simulation is required in Candidate 001.

---

## 6. Typed persistent state

Do not add arbitrary metadata to WHAT entities. Following 00B, System 33 keeps explicit typed domain state keyed by stable IDs.

Candidate implementation modules should remain domain-specific unless a shared abstraction proves real value.

### 6.1 Power state

`PowerComponentState`

- stable `component_id`;
- semantic role: source, substation, feeder, local branch, structure service;
- operational state;
- source planning identity/reference where applicable.

`PowerLinkState`

- stable `link_id`;
- upstream component ID;
- downstream component ID;
- operational state;
- source planning identity/reference where applicable.

`PowerServiceBinding`

- stable consumer/service ID;
- resolved terminal power component ID;
- optional WHAT structure/entity ID owning the endpoint.

### 6.2 Water state

`WaterComponentState`

- stable `component_id`;
- semantic role: source, treatment/storage, pump/distribution, well, local main, structure/property service;
- operational state;
- optional required power service ID for electrically driven pumps;
- source planning identity/reference where applicable.

`WaterLinkState`

- stable `link_id`;
- upstream component ID;
- downstream component ID;
- operational state.

`WaterServiceBinding`

- stable consumer/service ID;
- resolved terminal water component ID;
- optional WHAT structure/entity/property identity.

### 6.3 Operational state

Candidate 001 needs only a small explicit state set:

- `OPERATIONAL`
- `DISABLED`
- `DAMAGED`

`DISABLED` is an intact but intentionally unavailable state useful for switches/test controls/future shutoffs.

`DAMAGED` is persistent physical failure awaiting a future real repair action.

No automatic decay/random failure generator belongs in Candidate 001.

---

## 7. Topology materialization and stable identity

System 33 must consume the existing 00D4/00D5 plan rather than generate competing utility geography.

On virgin-world initialization:

1. read stable global utility planning records;
2. deterministically materialize runtime utility components/links with stable IDs derived from planning identity + role;
3. bind planned settlement service nodes to local/structure service endpoints through deterministic local-generation identities;
4. create rural decentralized-water components only where planning/local context requires them;
5. initialize operational state once;
6. thereafter treat System-33 state as current persistent truth.

Reloading/materializing a region must not recreate or heal damaged utility state.

If the world already has System-33 state, generation/planning is reference topology, not authority to overwrite current runtime state.

---

## 8. Service derivation

Service is **derived**, not stored as a second mutable truth.

Power service for endpoint `E`:

1. resolve `E` to its terminal power component;
2. follow the bounded required upstream chain;
3. service is available only when all required components/links are operational and a valid operational source is reached.

Water service for endpoint `W`:

1. resolve `W` to its terminal water component;
2. follow the bounded required upstream water chain;
3. verify all required components/links are operational;
4. for any electrically driven pump, query its required power service;
5. service is available only if an operational potable source is reached and all pump dependencies are satisfied.

Candidate 001 should prefer deterministic parent/upstream chains appropriate to the generated three-tier topology over a generalized pathfinder. If later construction creates branching/re-routing networks, that may justify a richer graph design then.

Cycles or malformed topology fail closed in validation/service queries rather than producing service accidentally.

---

## 9. Revisions, cache and performance

Utilities are event-driven state, not a clocked simulation.

Required performance rules:

- no `_process()`/frame-driven utility simulation;
- no recurring whole-world service scan;
- no timer per component, link, fixture or appliance;
- no full topology traversal merely because world time advanced;
- no work because the camera moved;
- no dependency on streaming activation for truth.

Each utility domain owns a monotonically increasing revision.

A successful mutation of relevant power truth increments the power revision and invalidates only affected cached service results or, for Candidate 001 if simpler and still bounded, the small domain service cache.

Water service cache invalidates on water revision and on power revision for endpoints whose pumps require power.

Consumers wake from explicit utility revision/change notifications. They do not poll every frame.

The cost target is proportional to the changed service chain/known consumers, not the world area or number of terrain cells.

---

## 10. Fixed lighting integration

System 27 remains the only owner of physical illumination/emitter truth.

System 33 does not brighten tiles directly.

For fixed powered fixtures:

1. a real persistent fixture/entity is bound to a power service;
2. its own persistent switch/operational state is read;
3. System 33 reports whether electrical service is available;
4. a thin canonical source provider translates **powered + switched on + operational fixture** into System-27 emitter input;
5. System 27 handles illumination, visibility and presentation consequences normally.

A dark sprite cannot make a fixture unpowered. A bright sprite cannot make it powered.

The temporary DEV lighting adapter should be retired only for the portion replaced by real canonical truth. The portable flashlight may remain on an honestly temporary equipment-source seam until portable battery/equipment state is deliberately designed; Phase 3 must not fake battery simulation simply to delete a filename.

---

## 11. Refrigeration integration

System 30 continues to own freshness derivation and spoilage math.

A refrigerator becomes valid cold-storage exposure only when:

- the refrigerator is a real persistent appliance/container;
- its appliance state is operational;
- its switch state is on;
- its bound power service is available.

System 33 (or a thin provider owned at the System-33/System-30 seam) exposes authoritative cold-storage availability. System 30 consumes that as storage-environment input without gaining ownership of power.

When power is lost, no item timer is created. The storage exposure changes at an authoritative tick/time boundary, and System 30 analytically derives future freshness from that exposure history according to its existing contract.

Candidate 001 should not add freezer thermodynamics, compressor cycling or per-fridge temperature simulation.

---

## 12. Water consumer integration

Phase 4 thirst/drinking is not implemented here.

Candidate 001 may expose truthful water availability to existing fixture inspection/interaction UI:

- sink/faucet/water fixture has service;
- service unavailable;
- pump unpowered;
- component damaged/disabled where discoverable by inspection.

Do not invent an abstract water inventory or fake drinking action merely to demonstrate the network.

If a real liquid-container/fill system does not already exist, actual drawing/filling of water remains deferred to the later system that owns liquid item state.

---

## 13. Appliance / fixture local state

A utility consumer may need a tiny persistent local state independent from service availability:

- operational/damaged;
- switched on/off.

This state must be keyed to the real persistent consumer entity/service identity and survive streaming/snapshot restore.

Initial generated fixed fixtures/appliances may deterministically start operational and switched on where appropriate. That is virgin initialization, not fake runtime truth.

Changing a switch later must happen through an explicit action/interaction mutation, not by UI directly rewriting presentation state.

---

## 14. Damage, outage and repair seams

Candidate 001 needs real failure state and real mutation APIs even before final repair skills exist.

Allowed initial causes:

- deterministic DEV test controls that call the same canonical mutation API future gameplay will use;
- explicit fixture/utility state mutations from focused tests.

Deferred causes:

- trees/vehicles striking lines;
- combat/explosions;
- player sabotage;
- NPC actions;
- weather damage if deliberately designed;
- wear/failure over time.

Future repair actions use the same damaged state. Phase 6 Electrical/Mechanical skills can gate or modify those actions without changing System-33 ownership.

DEV outage controls are acceptable only as **controls over real canonical state**. They may not own a parallel demo utility model.

---

## 15. WHEN / pause semantics

Utility truth changes only because an authoritative mutation occurs.

Candidate 001 has no background time progression requirement.

If a future action toggles, damages or repairs utility equipment:

- input emits intent;
- WHEN owns action duration/commit;
- System 33 mutation occurs at the authoritative commit boundary;
- revisions change once;
- downstream lighting/freshness/inspection updates derive from the settled state.

No utility work runs while the player is paused merely because render frames continue.

---

## 16. Snapshot / restore

System 33 snapshot must contain canonical typed state only:

- schema version;
- power component states;
- power link states;
- power service bindings that are runtime-created rather than safely reconstructible;
- water component states;
- water link states;
- water service bindings that are runtime-created rather than safely reconstructible;
- persistent local switch/operational states owned by this system;
- revision values where needed for deterministic restore semantics.

Do not serialize derived service caches.

Restore validates all IDs/references/topology into temporary stores before replacing live state, then rebuilds caches and emits a domain reset/revision notification.

Pre-Beta save incompatibility may still invalidate old saves rather than carrying vestigial migration code when the user has not requested compatibility.

---

## 17. Candidate 001 implementation slices

After explicit approval, implement in this order.

### 33A — Utility state foundation + plan materialization

- typed power/water state stores;
- deterministic stable IDs from 00D4/00D5 planning truth;
- local/structure service bindings;
- snapshot/restore;
- mutation/query services;
- domain revisions;
- focused topology/service tests.

No visible gameplay consequence is required until this foundation is real.

### 33B — Power vertical slice

- three-tier power service derivation;
- fixed structure/fixture power bindings;
- real outage mutations;
- fixed powered lights feed System 27 through a canonical provider;
- DEV outage controls mutate only real System-33 state;
- retain portable flashlight temporary seam unless real portable equipment power is implemented separately.

### 33C — Potable-water vertical slice

- municipal three-tier water service;
- rural private/shared well service where planned;
- pump-to-power dependency;
- water service query/inspection;
- no thirst/liquid inventory shortcut.

### 33D — Refrigeration consumer slice

- persistent refrigerator appliance/switch state;
- real power-service dependency;
- cold-storage availability provider to System 30;
- outage immediately changes exposure truth at the authoritative time boundary;
- freshness remains analytic/no timers.

Candidate 001 is complete only when all four slices are integrated and verified on the canonical playable build.

---

## 18. Verification contract

System 33 requires focused tests plus existing neighbor regressions.

### 18.1 Power tests

Prove:

- operational full chain provides service;
- Tier-1 failure removes all dependent service;
- Tier-2 failure removes only that downstream settlement branch;
- Tier-3/local failure removes only the affected endpoint/group;
- unrelated branch remains powered;
- restore preserves damage/disabled state;
- malformed/cyclic references fail closed;
- repeated query without revision change uses cached result/no repeated full work.

### 18.2 Water tests

Prove:

- operational municipal chain provides water;
- local water failure stays local;
- source/treatment failure propagates downstream;
- powered rural well provides service;
- unpowered rural well does not;
- restoring pump power restores derived water service without rewriting water truth;
- no per-frame/time-tick polling is required.

### 18.3 Lighting integration tests

Prove:

- powered switched-on fixture creates canonical System-27 emitter input;
- power loss removes that emitter input;
- restoring service restores it;
- flashlight behavior remains correct and independent unless separately migrated;
- black-screen/visibility regression smoke remains green.

### 18.4 Freshness integration tests

Prove:

- powered operational switched-on refrigerator reports cold-storage availability;
- outage removes cold-storage availability at the authoritative boundary;
- System 30 freshness remains analytic with no per-item timers;
- restoring power creates a new cold-storage exposure period rather than rewriting elapsed history.

### 18.5 Required neighbor regression set

At minimum include:

- System 00D global world planning;
- System 00F streaming/materialization;
- System 19/20 generation;
- WHAT foundation/persistence;
- WHEN/action-pause regressions where action integration changes;
- System 27 physical lighting;
- System 29 interaction affordance if utility inspection/toggles are exposed;
- System 30 freshness;
- performance architecture;
- canonical startup / player responsiveness / visibility smoke;
- Pages build/deploy.

Exact final executable SHA must be verified.

---

## 19. Performance acceptance

Candidate 001 fails the performance architecture gate if it introduces any of the following:

- recurring full-network scans;
- per-component/per-fixture Nodes for simulation truth;
- per-component/per-appliance timers;
- frame-driven service recomputation;
- camera-driven service recomputation;
- whole-world utility reevaluation after a local endpoint change when a bounded invalidation is available;
- utility truth coupled to renderer visibility/stream activation.

Useful telemetry should count, at minimum:

- power service derivations/cache hits;
- water service derivations/cache hits;
- utility state mutations;
- downstream invalidations by domain.

Telemetry is evidence, not gameplay truth.

---

## 20. Human acceptance

After automated verification, browser play must confirm:

1. normal start remains responsive and visually correct;
2. a local power outage produces understandable local darkness without blacking unrelated areas;
3. restoring the service restores the expected fixed lights;
4. water status responds correctly to a municipal/local outage and to loss/restoration of pump power;
5. a refrigerator truthfully transitions between powered cold storage and ordinary storage;
6. no obvious new input lag, first-step hitch growth or visual regression appears on the current browser target;
7. phone/Safari remains a first-class acceptance target.

---

## 21. Explicitly deferred from Candidate 001

- player thirst/drinking consequences;
- liquid inventories/container filling if no canonical liquid system exists;
- generators, fuel consumption and portable battery depletion;
- solar/wind production simulation;
- player wiring/plumbing construction;
- detailed breakers/circuits/load balancing;
- voltage/pressure/flow simulation;
- contamination/water quality;
- wastewater/sewers;
- automatic random utility failures;
- line damage from weather/trees/vehicles/combat;
- repair actions/skill checks;
- AI utility behavior;
- procedural outage events.

Those are future consumers/causes over the same persistent state, not reasons to make Candidate 001 generic now.

---

## 22. Approval boundary

This document completes the **DESCRIBE** step only.

No Phase-3 runtime implementation is authorized by this document itself.

Recommended approval target:

> **Approve System 33 Candidate 001: persistent three-tier power and potable-water runtime state; real fixed-light power integration; real pump-power dependency; real refrigerator cold-storage integration; truthful water-service inspection; no Phase-4 needs, no random outages, no detailed electrical/hydraulic simulation.**

On approval, implementation should start with **33A Utility state foundation + plan materialization**, preserve the current human-accepted responsiveness/visibility behavior, and proceed through 33B/33C/33D without inventing parallel demo truth.
