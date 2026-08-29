# Tick Survival Lab — System 33 Power / Water Utility Runtime

Status: **IMPLEMENTED + AUTOMATED VERIFIED — Candidate 001; HUMAN RETEST PENDING**

Verified repaired executable: `ec7be83146d62055a5d2d4b1233eb7cc50cea630`

Roadmap phase: **Phase 3 — Power and Water**

Upstream planning contracts:

- `00D4_GLOBAL_ELECTRICAL_INFRASTRUCTURE.md`
- `00D5_GLOBAL_POTABLE_WATER_INFRASTRUCTURE.md`

Primary downstream contracts:

- `27_PHYSICAL_LIGHTING_ILLUMINATION_SHADOWS.md`
- `30_ITEM_FRESHNESS_SPOILAGE.md`
- existing WHAT / WHEN / interaction foundations

---

## 0. Lifecycle / implementation record

Candidate 001 completed DESCRIBE and received explicit user approval before implementation.

Initial implementation lineage:

- `95a23ac49328c852b507a39a661354cbd445ed6c` — System-33 runtime power/water/refrigeration implementation.
- `6ba3fb08520323a9ab816bbcc20b1f8a64434ab2` — verification composition alignment.

Human play then **rejected the visible lighting integration**: runtime utility truth existed, but fixed lighting still came from legacy demo coordinates and the player received an unconditional fake flashlight beam.

Focused truthful-lighting repair lineage:

- `2267a7ea1b0fcd76fab90ddf23219c7e1ae70d43` — replaced fake lighting sources with real WHAT fixture/equipment truth.
- `ec7be83146d62055a5d2d4b1233eb7cc50cea630` — aligned stale regression contracts with the truthful source boundary and exact-head verified the repaired executable.

The repaired executable is automated-green. **Human browser retest remains the acceptance gate; Phase 3 is not HUMAN ACCEPTED yet.**

---

## 1. Goal

Create the first persistent runtime utility model for the playable world.

System 00D answers **where utility infrastructure is planned**. System 33 answers **whether that infrastructure currently provides service** and exposes that truth to real world consumers.

The target is intentionally smaller than a full electrical or hydraulic simulator. The game needs causal outages, local consequences, persistent repair seams and future expansion points without load-flow mathematics, pressure solvers or recurring whole-network simulation.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

---

## 2. Non-negotiable gameplay result

Utility failure is spatial and causal rather than one global switch.

A local branch failure may disable one structure while another remains supplied. A settlement feeder failure affects its downstream area. A major source failure affects all dependent service.

Water follows the same principle, with an additional dependency: an electrically driven pump cannot provide water when its required power service is unavailable.

The player should be able to reason from world truth:

- this branch is down, therefore these consumers lost power;
- this pump has no power, therefore this water service is unavailable;
- this refrigerator lost power, therefore it is no longer cold storage;
- this real fixed fixture has no power, therefore System 27 receives no active emitter from it.

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
- persistent appliance/fixture operational and switch state where needed;
- read-only service queries for downstream systems;
- snapshot/restore of typed durable utility state;
- change notifications sufficient for downstream invalidation.

System 33 does **not** own:

- global utility geography/corridors — System 00D owns planning;
- procedural building grammar — Systems 19/20;
- rendering, sprites or glow;
- physical illumination math — System 27;
- freshness math — System 30;
- hunger, thirst, drinking consequences or nutrition — Phase 4;
- generic liquid item/container simulation;
- final repair skill checks — Phase 6;
- vehicle/combat damage generation;
- automatic random outages;
- detailed electrical loads/voltage/breakers/circuits;
- hydraulic pressure/flow/pipe-size/contamination simulation;
- wastewater/sewer gameplay;
- portable battery/fuel depletion unless separately designed.

---

## 4. Dependency direction

System 33 may read:

- stable 00D electrical/water planning identities and topology facts;
- WHAT stable entity/structure identities for real consumers;
- local materialization/building facts only to establish deterministic service bindings;
- authoritative WHEN/world-time only when an explicit timed utility action needs it.

System 33 may publish read-only state to:

- System 27 fixed-light source integration;
- System 30 cold-storage exposure integration;
- System 29 inspection/interaction affordances;
- future repair, construction, AI and survival systems.

System 33 may not depend on render frames, camera position, art selection, UI state, visual brightness or streamed-node existence as proof of utility existence.

Technical streaming never defines utility existence.

---

## 5. Runtime topology: three causal tiers

### 5.1 Power

1. **Tier 1 — regional source / major supply**
2. **Tier 2 — substation / settlement feeder**
3. **Tier 3 — local branch / structure service**

An endpoint is powered only if every required upstream component/link on its resolved service path is operational and an operational source is reached.

### 5.2 Potable water

1. **Tier 1 — source + treatment/storage**
2. **Tier 2 — pump/distribution / settlement service**
3. **Tier 3 — property / structure service**

A water endpoint has service only if the required upstream water path is operational and every electrical pump dependency has power.

### 5.3 Rural decentralized water

Where existing planning/local context calls for decentralized rural service, Candidate 001 materializes deterministic private/shared well service.

A rural electrically pumped well consists of persistent source/well truth, persistent pump state, a power-service dependency and a derived property water endpoint. Aquifer depletion is not simulated.

---

## 6. Typed persistent state

Do not add arbitrary metadata to WHAT entities. System 33 keeps explicit typed domain state keyed by stable IDs.

Power domain includes persistent component/link/service-binding records. Water domain includes persistent source/treatment/pump/well/local-service component/link/binding records. Appliance state includes stable consumer identity, service binding, operational state and switch state where relevant.

Operational state set:

- `OPERATIONAL`
- `DISABLED`
- `DAMAGED`

`DISABLED` is intact but intentionally unavailable. `DAMAGED` is persistent physical failure awaiting a future repair action.

No automatic decay/random failure generator belongs in Candidate 001.

---

## 7. Topology materialization and stable identity

System 33 consumes 00D4/00D5 planning rather than generating competing utility geography.

On virgin initialization it deterministically materializes runtime components/links with stable IDs, binds settlement/local service endpoints, creates rural decentralized-water components where required and initializes operational state once.

Afterward, System-33 state is current persistent truth. Reloading or streaming a region must not recreate/heal damaged utility state. Planning remains reference topology, not an overwrite authority.

---

## 8. Service derivation

Service is **derived**, not stored as a second mutable truth.

Power query:

1. resolve endpoint to its terminal component;
2. follow its bounded required upstream chain;
3. require all components/links operational and a valid source.

Water query:

1. resolve endpoint to its terminal water component;
2. follow bounded upstream water chain;
3. require all water components/links operational;
4. query required power service for electrical pumps;
5. require a valid potable source.

Candidate 001 uses deterministic bounded parent/upstream chains rather than a generalized pathfinder. Malformed/cyclic topology fails closed.

---

## 9. Revisions, cache and performance

Utilities are event-driven state, not a clocked simulation.

Required rules:

- no `_process()` utility simulation;
- no recurring whole-world service scan;
- no timer per component/link/fixture/appliance;
- no topology work merely because world time advanced;
- no camera-driven service recomputation;
- no dependency on streaming activation for truth.

Power and water own monotonic revisions. Relevant mutations invalidate bounded/domain caches. Water derivation also keys off power revision where pumps depend on power.

Consumers wake from explicit revision/change notifications instead of polling every frame.

---

## 10. Fixed and portable lighting integration

System 27 remains the owner of physical illumination/emitter truth. System 33 does not brighten tiles directly.

### 10.1 Fixed powered fixtures

Canonical fixed-light source behavior:

1. a **real persistent WHAT fixture entity** is identified by semantic type;
2. emitter origin/facing comes from that entity's actual `WorldPlacement`;
3. the fixture binds to the System-33 power service for its real cell;
4. its appliance operational/switch state and power service determine availability;
5. the thin System-33/System-27 provider emits a System-27 descriptor only while that real fixture is available;
6. System 27 handles illumination, shadow, visibility and presentation consequences.

A bright sprite cannot create service or emitter truth. A dark sprite cannot remove service truth.

Supported fixed semantic fixture families in the repaired provider currently include street/traffic/crosswalk lights, lamps and neon fixtures.

### 10.2 Portable flashlight truth

The old DEV player flashlight source is retired.

The player has **no flashlight beam by default**. A flashlight emitter exists only while a real WHAT entity with semantic type `item.tool.flashlight` is assigned to a real System-09 hand slot. Its origin/facing derives from the controlled actor's real placement.

Candidate 001 does not invent battery depletion or a hidden default flashlight. Grid outages do not fake-disable a portable flashlight. Battery/toggle behavior is a future portable-equipment concern unless separately approved.

`DemoLightingSourceAdapter` remains only as an inert compatibility/bootstrap shim and must emit zero gameplay lights.

A facing-only turn with no equipped moving light must not wake the physical-light solver.

---

## 11. Refrigeration integration

System 30 owns freshness derivation.

A refrigerator is valid cold storage only when it is a real persistent appliance/container, operational, switched on and supplied by its bound power service.

System 33 exposes cold-storage availability; System 30 consumes it as storage-environment input. Power loss changes exposure truth at an authoritative boundary. No per-item timer, compressor cycle or detailed temperature simulation is introduced.

---

## 12. Water consumer integration

Phase 4 thirst/drinking is not implemented here.

Candidate 001 exposes truthful water availability/diagnostic state for service inspection, including unavailable service and pump-power dependency. It does not invent an abstract water inventory or fake drinking/filling mechanics when no canonical liquid system exists.

---

## 13. Appliance / fixture local state

Utility consumers may have persistent local operational/damaged and switched-on/off state independent from upstream service.

This state is keyed to real persistent consumer/service identity and survives snapshot/restore. Virgin generated appliances may deterministically start operational/on where appropriate; later changes must occur through canonical mutation/action seams rather than UI presentation state.

---

## 14. Damage, outage and repair seams

Candidate 001 includes real failure state and canonical mutation APIs before final repair skills exist.

Current allowed causes include DEV test controls and focused tests that call those same canonical mutation APIs.

Deferred causes include trees/vehicles, combat/explosions, sabotage, NPC actions, weather damage, wear and final repair skill actions.

DEV controls are acceptable only as controls over real System-33 state; they may not own a parallel demo utility model.

---

## 15. WHEN / pause semantics

Utility truth changes because an authoritative mutation occurs. Candidate 001 has no background time progression requirement.

Future timed toggle/damage/repair actions must use WHEN for duration/commit, mutate System 33 at the authoritative commit boundary and notify downstream consumers once from settled state.

No utility simulation runs simply because render frames continue while paused.

---

## 16. Snapshot / restore

System-33 snapshot contains canonical typed state only: schema version, persistent power/water component/link/binding state, appliance/switch state and required revision values.

Derived service caches are not serialized.

Restore validates IDs/references/topology into temporary state before replacing live state, rebuilds caches and emits reset/revision notification. Pre-Beta incompatibility may invalidate old saves rather than carry vestigial migration code unless compatibility is explicitly requested.

---

## 17. Candidate 001 implementation slices — IMPLEMENTED

### 33A — Utility state foundation + plan materialization

Implemented typed power/water state, deterministic plan-derived identities, local service bindings, snapshot/restore, mutation/query APIs, revisions and service tests.

### 33B — Power vertical slice

Implemented three-tier power derivation, fixed consumer bindings, real outage mutations, System-27 integration and DEV controls over canonical state.

The first lighting source adapter was human-rejected because it still relied on fake/demo source ownership. The repaired 33B integration now uses actual WHAT fixture entities and actual hand equipment as specified in Section 10.

### 33C — Potable-water vertical slice

Implemented municipal/rural service, pump-to-power dependency and water service query/inspection without a thirst/liquid shortcut.

### 33D — Refrigeration consumer slice

Implemented persistent refrigerator appliance state, real power dependency and cold-storage availability for System 30 while preserving analytic freshness.

Candidate 001 is implementation-complete and automatically verified. Human acceptance remains pending.

---

## 18. Verification contract

### 18.1 Power

Prove full-chain service, Tier-1/2/3 causal failures, unrelated-branch isolation, persistent restore semantics, fail-closed malformed topology and cached repeated queries.

### 18.2 Water

Prove municipal/local failure propagation, rural well behavior, pump-power dependency, restoration behavior and no frame/time polling.

### 18.3 Truthful lighting integration

Prove:

- a real powered fixed fixture creates a System-27 emitter at its actual WHAT cell/facing;
- local power loss removes that emitter and restoration returns it;
- no player flashlight emitter exists when no real flashlight item is equipped;
- assigning a real `item.tool.flashlight` to a hand creates the player beam at actor position/facing;
- unequipping removes the beam;
- grid outage does not invent portable battery behavior;
- legacy demo source emits zero gameplay lights;
- player turning without an equipped moving light does not trigger a physical-light rebuild;
- black-screen/full-window visibility regression coverage stays green.

Dedicated smoke/context:

- `System33LightingTruthSmoke.gd`
- `verify/system33-lighting-truth`

### 18.4 Freshness

Prove powered refrigerator cold-storage availability, outage exposure transition, analytic/no-timer freshness and history-preserving restoration.

### 18.5 Neighbor regressions

At minimum preserve global world planning, streaming/materialization, Systems 19/20, WHAT persistence, WHEN/action-pause where relevant, System 27, System 29 if inspection changes, System 30, performance architecture, canonical startup/player responsiveness/visibility and Pages.

Exact repaired executable verified: `ec7be83146d62055a5d2d4b1233eb7cc50cea630`.

---

## 19. Performance acceptance

Candidate 001 fails the performance gate if it introduces recurring full-network scans, per-component simulation Nodes/timers, frame/camera-driven recomputation, whole-world reevaluation for local changes or utility truth coupled to renderer visibility/stream activation.

The repaired fixed-light provider discovers existing real fixtures through WHAT's semantic-type index and then updates from events/revisions. It does not scan the whole world every frame/action.

Useful telemetry includes service derivations/cache hits, mutations and downstream invalidations. Telemetry is evidence, not gameplay truth.

---

## 20. Human acceptance — PENDING RETEST

Automated verification is green, but human acceptance is not yet closed.

Browser play must confirm:

1. normal start remains responsive and visually correct;
2. there is **no phantom player flashlight** when no flashlight is actually equipped;
3. real visible fixed fixtures produce light at their actual world positions;
4. local power outage removes/restores the expected real fixed lights without blacking unrelated areas;
5. water status responds correctly to local/municipal failure and pump power loss/restoration;
6. refrigerator truthfully transitions between powered cold storage and ordinary storage;
7. no black-screen regression, first-step hitch growth or input backlog returns;
8. phone/Safari remains first-class.

Human rejection of the original fake/demo lighting integration remains part of the historical acceptance record even though the repaired executable is now automated-green.

---

## 21. Explicitly deferred from Candidate 001

- player thirst/drinking consequences;
- generic liquid inventories/container filling;
- generators/fuel consumption and portable battery depletion;
- solar/wind production simulation;
- player wiring/plumbing construction;
- detailed breakers/circuits/load balancing;
- voltage/pressure/flow simulation;
- contamination/water quality;
- wastewater/sewers;
- automatic random utility failures;
- utility damage from weather/trees/vehicles/combat;
- final repair actions/skill checks;
- AI utility behavior;
- procedural outage events.

These remain future consumers/causes over the same persistent state rather than reasons to generalize Candidate 001 now.

---

## 22. Current lifecycle boundary

The original approval boundary has been crossed: Candidate 001 was approved, implemented and automatically verified.

The active lifecycle gate is now:

> **HUMAN VERIFY System 33 Candidate 001 on repaired executable `ec7be83146d62055a5d2d4b1233eb7cc50cea630`.**

Do not mark Phase 3 HUMAN ACCEPTED or begin Phase 4 by default until the repaired browser build passes the human checks in Section 20. New explicit user direction may override roadmap sequencing, but must not rewrite the historical rejection/verification record.
