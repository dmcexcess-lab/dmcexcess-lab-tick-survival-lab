# Tick Survival Lab — System 33 Power / Water Utility Runtime

Status: **IMPLEMENTED + AUTOMATED VERIFIED — Candidate 001 + powered room-light refinement; HUMAN RETEST PENDING**

Current verified executable: `c7592c956a44c31b082db84ae597f43c643231c4`

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

- `95a23ac49328c852b507a39a661354cbd445ed6c` — runtime power/water/refrigeration implementation.
- `6ba3fb08520323a9ab816bbcc20b1f8a64434ab2` — verification composition alignment.

Human play then **rejected the visible lighting integration**: utility truth was real, but fixed lighting still came from demo coordinates and the player had an unconditional fake flashlight.

Truthful-lighting repair lineage:

- `2267a7ea1b0fcd76fab90ddf23219c7e1ae70d43` — replaced fake lighting sources with real WHAT fixture/equipment truth.
- `ec7be83146d62055a5d2d4b1233eb7cc50cea630` — aligned stale regression contracts and exact-head verified the repaired source boundary.

Human browser play then reported that repaired behavior looked good, while also exposing a content/system gap: generated houses had too few actual indoor light sources to make household power state visible.

Indoor-light refinement:

- `c7592c956a44c31b082db84ae597f43c643231c4` — materializes one persistent powered non-bloom room-light fixture per generated room and exact-head verifies real luminance-on/no-bloom behavior.

The current executable is automated-green. **Human browser retest remains the acceptance gate; Phase 3 is not HUMAN ACCEPTED yet.**

---

## 1. Goal

System 00D answers **where utility infrastructure is planned**. System 33 answers **whether that infrastructure currently provides service** and exposes that truth to real consumers.

The target is intentionally smaller than a full electrical or hydraulic simulator. The game needs causal outages, local consequences, persistent repair seams and future expansion points without load-flow mathematics, pressure solvers or recurring network simulation.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

---

## 2. Non-negotiable gameplay result

Utility failure is spatial and causal rather than one global switch.

A local branch failure may disable one structure while another remains supplied. A settlement feeder failure affects its downstream area. A major source failure affects all dependent service.

Water has an additional dependency: an electrically driven pump cannot provide water when its required power service is unavailable.

The player should be able to reason from real world truth:

- this branch is down, therefore these consumers lost power;
- this room is on a powered branch, therefore its real room-light fixture raises local illumination;
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
- procedural room/building grammar — System 19 owns room plans;
- rendering, sprites or bloom;
- physical illumination propagation/math — System 27;
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

System 33 may read stable 00D electrical/water planning identities, WHAT persistent consumer identities/placements, local building facts only to establish deterministic bindings, and authoritative WHEN/world-time only when an explicit timed utility action later requires it.

System 33 may publish service state to System 27 lighting, System 30 cold-storage exposure, System 29 inspection/interaction affordances and later repair/construction/AI/survival systems.

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

A water endpoint has service only if its upstream water path is operational and every electrical pump dependency has power.

### 5.3 Rural decentralized water

Where existing planning/local context calls for decentralized rural service, Candidate 001 materializes deterministic private/shared well service. A rural electrically pumped well has persistent source/well truth, persistent pump state, a power-service dependency and a derived property endpoint. Aquifer depletion is not simulated.

---

## 6. Typed persistent state

System 33 keeps explicit typed domain state keyed by stable IDs rather than arbitrary metadata on WHAT entities.

Power and water domains contain persistent component/link/service-binding records. Appliance state contains stable consumer identity, power-service binding, operational state and switch state where relevant.

Operational state set:

- `OPERATIONAL`
- `DISABLED`
- `DAMAGED`

No automatic decay/random failure generator belongs in Candidate 001.

---

## 7. Topology materialization and stable identity

System 33 consumes 00D4/00D5 planning rather than generating competing utility geography.

On virgin initialization it deterministically materializes runtime components/links, binds settlement/local service endpoints, creates rural decentralized-water components where required and initializes operational state once.

Afterward, System-33 state is current persistent truth. Reloading/streaming must not recreate or heal damaged utility state.

### 7.1 Generated room-light identity

System 19 already owns deterministic generated room cell sets. To make household electrical service visibly testable without inventing visible lamp art, building materialization creates exactly one persistent WHAT fixture per generated room:

- semantic type: `fixture.room_light`;
- stable ID derived from the building plan identity plus room index;
- placement: a deterministic real cell from that room;
- channel: non-rendered `EFFECT`;
- single-cell physical identity with no collision or visible prop art.

This fixture is virgin-world/materialization truth, not a presentation-only marker. System 33 binds it like any other fixed electrical consumer. Future real fixture/switch content may replace or specialize this ambient-room fixture through an explicit design change rather than creating a parallel lighting owner.

---

## 8. Service derivation

Service is **derived**, not stored as a second mutable truth.

Power query resolves an endpoint to its terminal component, follows the bounded required upstream chain, and requires all components/links operational plus a valid source.

Water query follows the bounded water chain, requires all components/links operational, verifies any electrical pump's real power service and requires a valid potable source.

Malformed/cyclic topology fails closed.

---

## 9. Revisions, cache and performance

Utilities are event-driven state, not a clocked simulation.

Required rules:

- no `_process()` utility simulation;
- no recurring whole-world service scan;
- no timer per component/link/fixture/appliance/room;
- no topology work merely because world time advanced;
- no camera-driven service recomputation;
- no dependency on streaming activation for truth.

Power and water own monotonic revisions. Mutations invalidate bounded/domain caches. Water derivation also keys off power revision where pumps depend on power.

The fixed-light provider discovers real fixtures through WHAT semantic-type indexing and then follows events/revisions. It does not rescan every frame/action.

---

## 10. Fixed, room and portable lighting integration

System 27 remains the owner of physical illumination/emitter truth. System 33 never directly brightens tiles.

### 10.1 Fixed powered fixtures

Canonical fixed-light source behavior:

1. identify a **real persistent WHAT fixture entity** by semantic type;
2. read its actual `WorldPlacement` origin/facing;
3. bind it to System-33 power service for its real cell;
4. combine appliance operational/switch state with upstream service;
5. emit a System-27 descriptor only while that real fixture is available;
6. let System 27 handle physical illumination, shadows, visibility and presentation consequences.

Supported families currently include street/traffic/crosswalk lights, lamps, neon and generated `fixture.room_light` sources.

A bright sprite cannot create service or emitter truth. A dark sprite cannot remove it.

### 10.2 Non-bloom room ambient light

`fixture.room_light` uses `LightEmitterProfile.room_ambient()` / profile ID `light.room_ambient.candidate001`.

The profile is deliberately split into two truths:

- **physical light:** normal positive base luminance, range, falloff and local spill feed System-27 useful illumination exactly like another light source;
- **presentation glow:** `presentation_glow_scale = 0.0` suppresses source bloom/glare/scatter contribution.

Therefore powered rooms become visibly lighter through the ordinary physical-light multiply/illumination map, but no fake glowing bulb/halo is drawn. Walls, doors, windows and existing optical transmission continue to shape the light normally.

This distinction is reusable: future ceiling fluorescents, ambient panels, emergency illumination or other sources may choose their own presentation-glow scale without changing who owns physical illumination.

Ordinary streetlights, visible lamps, neon and flashlights retain nonzero glow behavior.

### 10.3 Portable flashlight truth

The old DEV player flashlight source is retired.

The player has **no flashlight beam by default**. A flashlight emitter exists only while a real WHAT `item.tool.flashlight` is assigned to a real System-09 hand slot. Origin/facing derives from the controlled actor's real placement.

Candidate 001 does not invent battery depletion or hidden default equipment. Grid outages do not fake-disable a portable flashlight. `DemoLightingSourceAdapter` remains an inert compatibility/bootstrap shim with zero gameplay lights.

A facing-only turn with no equipped moving light must not wake the physical-light solver.

---

## 11. Refrigeration integration

System 30 owns freshness derivation.

A refrigerator is valid cold storage only when it is a real persistent appliance/container, operational, switched on and supplied by its bound power service.

System 33 exposes cold-storage availability; System 30 consumes it as storage-environment input. Power loss changes exposure truth at an authoritative boundary. No per-item timer, compressor cycle or detailed temperature simulation is introduced.

---

## 12. Water consumer integration

Phase 4 thirst/drinking is not implemented here.

Candidate 001 exposes truthful water availability/diagnostic state, including unavailable service and pump-power dependency. It does not invent abstract water inventory or fake drinking/filling mechanics.

---

## 13. Appliance / fixture local state

Utility consumers may have persistent local operational/damaged and switched-on/off state independent from upstream service.

This state is keyed to real persistent consumer/service identity and survives snapshot/restore. Virgin generated appliances/fixtures may deterministically start operational/on where appropriate; later state changes must use canonical mutation/action seams.

The current generated room ambient fixtures begin as powered consumers when their real local service is available. Per-room user-facing wall-switch interaction is not claimed by this slice; future interaction may mutate the same appliance switch state rather than inventing separate light truth.

---

## 14. Damage, outage and repair seams

Candidate 001 includes real failure state and canonical mutation APIs before final repair skills exist.

Current allowed causes include DEV controls and focused tests that call those same APIs. Deferred causes include trees/vehicles, combat/explosions, sabotage, NPC actions, weather damage, wear and final repair-skill actions.

DEV controls may only mutate real System-33 state; they may not own parallel demo utility models.

---

## 15. WHEN / pause semantics

Utility truth changes only because authoritative mutation occurs. Candidate 001 has no background time progression requirement.

Future timed toggle/damage/repair actions must use WHEN for duration/commit, mutate System 33 at the authoritative boundary and notify consumers once from settled state.

No utility simulation runs merely because render frames continue while paused.

---

## 16. Snapshot / restore

System-33 snapshot contains canonical typed state only: schema version, persistent power/water component/link/binding state, appliance/switch state and required revision values.

Derived service caches are not serialized. Restore validates temporary state before replacing live state, rebuilds caches and emits reset/revision notification.

---

## 17. Candidate 001 implementation slices — IMPLEMENTED

### 33A — Utility foundation

Implemented typed power/water state, deterministic plan-derived identities, local bindings, snapshot/restore, mutation/query APIs, revisions and service tests.

### 33B — Power

Implemented three-tier power derivation, real outage mutations, real fixed consumer bindings, System-27 source integration, canonical DEV controls, truthful hand-equipped flashlight behavior and powered non-bloom generated room fixtures.

### 33C — Potable water

Implemented municipal/rural service, pump-to-power dependency and water service query/inspection without thirst/liquid shortcuts.

### 33D — Refrigeration

Implemented persistent refrigerator appliance state, real power dependency and cold-storage availability for System 30 while preserving analytic freshness.

Candidate 001 is implementation-complete and automatically verified. Human acceptance remains pending.

---

## 18. Verification contract

### 18.1 Power

Prove full-chain service, Tier-1/2/3 causal failures, unrelated-branch isolation, persistent restore semantics, fail-closed malformed topology and cached repeated queries.

### 18.2 Water

Prove municipal/local failure propagation, rural well behavior, pump-power dependency, restoration behavior and no frame/time polling.

### 18.3 Truthful lighting

Prove:

- a real powered fixed fixture creates a System-27 emitter at its actual WHAT cell/facing;
- local power loss removes that emitter and restoration returns it;
- generated rooms have persistent `fixture.room_light` identity on real room cells;
- room fixtures bind to real local System-33 service;
- room ambient light materially raises real local physical luminance;
- room ambient light adds no presentation bloom/glare/scatter;
- ordinary visible light profiles retain bloom;
- no player flashlight emitter exists without real equipped flashlight truth;
- equip/unequip creates/removes the player beam at actor position/facing;
- grid outage does not invent portable battery behavior;
- legacy demo source emits zero gameplay lights;
- player turning without an equipped moving light does not trigger a physical-light rebuild;
- black-screen/full-window visibility regression coverage remains green.

Dedicated coverage:

- `System33LightingTruthSmoke.gd`
- `RoomLightingPowerSmoke.gd`
- `verify/system33-lighting-truth`

### 18.4 Freshness

Prove powered refrigerator cold-storage availability, outage exposure transition, analytic/no-timer freshness and history-preserving restoration.

### 18.5 Neighbor regressions

Preserve global world planning, streaming/materialization, Systems 19/20, WHAT persistence, WHEN/action-pause where relevant, System 27, System 29 if inspection changes, System 30, performance architecture, canonical startup/player responsiveness/visibility and Pages.

Current exact executable verified: `c7592c956a44c31b082db84ae597f43c643231c4`.

---

## 19. Performance acceptance

Candidate 001 fails the performance gate if it introduces recurring full-network/world scans, per-component/per-room simulation Nodes/timers, frame/camera-driven recomputation, whole-world reevaluation for local changes or utility truth coupled to renderer visibility/stream activation.

Room-light materialization is one persistent fixture per generated room, created with the building's virgin materialization transaction. Runtime availability remains event/revision driven.

---

## 20. Human acceptance — PENDING RETEST

Automated verification is green, but human acceptance is not yet closed.

Browser play must confirm:

1. normal start remains responsive and visually correct;
2. generated rooms become visibly lighter when their actual service is powered, without fake glowing room-light graphics;
3. `LOCAL PWR` removes/restores the expected affected indoor illumination;
4. walls/closed doors/windows continue to shape physical light normally;
5. ordinary visible streetlights/lamps/neon still present visible glow;
6. there is no phantom player flashlight when no flashlight is equipped;
7. water status responds correctly to local/municipal failure and pump power loss/restoration;
8. refrigerator truthfully transitions between powered cold storage and ordinary storage;
9. no black-screen regression, first-step hitch growth or input backlog returns;
10. phone/Safari remains first-class.

Human rejection of the original fake/demo lighting integration remains part of the historical record even though the current executable is automated-green.

---

## 21. Explicitly deferred from Candidate 001

- player thirst/drinking consequences;
- generic liquid inventories/container filling;
- generators/fuel consumption and portable battery depletion;
- user-facing per-room wall-switch interactions beyond existing appliance state;
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

---

## 22. Current lifecycle boundary

Candidate 001 was approved, implemented and automatically verified. The active lifecycle gate is now:

> **HUMAN VERIFY System 33 Candidate 001 + powered non-bloom room-light refinement on executable `c7592c956a44c31b082db84ae597f43c643231c4`.**

Do not mark Phase 3 HUMAN ACCEPTED or begin Phase 4 by default until the current browser build passes the checks in Section 20. New explicit user direction may override roadmap sequencing, but must not rewrite the historical rejection/verification record.
