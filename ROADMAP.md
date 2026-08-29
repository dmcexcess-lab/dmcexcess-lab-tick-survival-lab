# Tick Survival Lab — Roadmap to Beta

Status: **canonical priority roadmap**.

This file answers what major gameplay work comes next and in what order. It does not replace system designs. Each independently owned phase/system follows `README_SOPS.md` and the normal **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY** lifecycle.

Current game identity:

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

---

## Current milestone state

- **Phase 1 — COMPLETE.** Items, spoilage, interaction readability, semantic UI, large-object presentation, content breadth and integration are implemented.
- **Phase 2 — COMPLETE.** System 32 Crafting / Material Transformation Candidate 001 is implemented and CI verified on `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.
- **Compact-island/world-seam cleanup — COMPLETE + HUMAN ACCEPTED.** The broad planner repair `918f1dbd7b033fa179522a112b1507d9a2c63890` remains rejected, but the later focused local-window repair `282864f242ba2a5c3df0519591e31990372c4aed` preserved the world layout while resolving the overlap seam.
- **Responsiveness / black-screen recovery — HUMAN ACCEPTED.** Executable `1f65bff312853a44858201b57d9df2e26ee64f80` restored the human-good visibility path while preserving the accepted decision-pause/input responsiveness work. Human play subsequently confirmed the black screen fixed and performance improved.
- **Current gameplay lifecycle gate:** Phase 3 / System 33 Power + Water is **DESCRIBED and awaiting explicit approval**. No Phase-3 runtime implementation is pre-authorized.

---

## Phase 1 — Items, spoilage, interaction readability, and world-object breadth — COMPLETE

Goal: make the physical world and the things in it useful/readable before deeper character systems arrive.

### 1A — Interaction affordance + reach — COMPLETE

System 29 owns neutral reach + interaction-offer composition.

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Implemented result includes shared `CONTACT_FORWARD` reach, real read-only interaction offers, System-23 visibility gating, bounded local OBJECT discovery, and presentation-only highlights.

### Performance architecture gate — COMPLETE + HUMAN ACCEPTED

The P0/P1/P2 performance architecture and Weather presentation optimization are complete and human-accepted on phone/Safari.

The later action-responsiveness repair is also human accepted on the current playable lineage: one accepted action resolves through bounded per-frame work, gameplay input remains locked until the next real decision pause, stale buffered input is not replayed, and the black-screen visibility regression has been recovered.

Protected direction remains event-driven/cache-oriented invalidation, bounded queries and shared derived plans rather than recurring world scans, per-cell/per-item Nodes/timers or frame-driven simulation.

### 1B — Item freshness / spoilage — COMPLETE

System 30 Candidate 001 is implemented and verified.

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Refrigeration remains inactive until Phase 3 supplies real powered-appliance truth. Phase 4 later owns eating/drinking/health consequences.

### 1C — Semantic inventory/menu icons — COMPLETE

System 31 is implemented and verified.

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

### 1D — Large/multi-cell object visual geometry — COMPLETE

System 07B is implemented and CI verified.

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

### 1E — Content expansion + integration — COMPLETE

Canonical design: `SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Verified Phase-1E executable: `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

---

## Phase 2 — Crafting — COMPLETE + CI VERIFIED

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

Exact-head context: `verify/system32-crafting`.

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Implemented Candidate 001:

1. **2A — Recipe + plan foundation** — exact-semantic recipes/workstations, deterministic ingredient/tool selection from real personal possession, physical-weight/carry/freshness validation and no abstract resource wallet.
2. **2B — Timed physical transformation** — positive-duration CANCELABLE `crafting.craft_recipe` WHEN action, final-commit revalidation, real input removal, deterministic persistent outputs, actor-root containment, hard carry ceiling and bounded compensation.
3. **2C — Workstation + player integration** — explicit heavy-workbench capability, System-29 `CONTACT_FORWARD` `CRAFT` offer and phone/Safari-first Crafting UI in the canonical player shell.

System 32 does not own Construction/Repair/Durability, Cooking/Nutrition, Power/Water, Skills/quality/XP, Vehicles, combat/ammunition or AI.

---

## World-generation cleanup gate — COMPLETE + HUMAN ACCEPTED

The playable island remains `temperate.island.region` v3 over the protected rural-v6 planning skeleton.

Accepted cleanup result includes:

- fresh new-game seeds redraw island identity rather than aliasing the historical standalone critique fixture;
- central local-site seed derives from world seed + site identity;
- the playable island does not carry the old 640-cell regional stress-fixture protected-cross half-span;
- compact island spacing removes the former giant green belt;
- natural ecology stays coherent across logical source rectangles using world seed + absolute global cell;
- spawn remains on inherited pavement rather than the diner entrance;
- the legal-seed base-site overlap is repaired by `282864f242ba2a5c3df0519591e31990372c4aed` through a bounded local-window adaptation that preserves settlement centers/world layout instead of changing the global settlement planner.

### Rejected attempt remains historical evidence

`918f1dbd7b033fa179522a112b1507d9a2c63890` changed global settlement candidate rejection from the historical center-distance heuristic to exact rectangle-overlap rejection. Automated CI passed, but human play found the world severely broken. It was rolled back in `f6a06add3dfd212c0c29b343d24a8f7d28a89bca` and remains **not accepted**.

The later focused repair `282864f...` is the accepted direction because it repairs the island-local adaptation rather than silently redesigning global settlement placement.

Human play of the current recovered executable lineage confirmed the playable world is acceptable to move forward. Generated-world changes remain subject to the same human acceptance discipline in the future.

---

## Phase 3 — Power and Water — DESCRIBED; AWAITING APPROVAL

Canonical design: `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`.

Goal: add causal, persistent **three-tier utility networks** rather than global on/off switches.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

### Power hierarchy

1. **Main generation / major source** — broad regional supply.
2. **Substations / settlement feeders** — local distribution facilities and service branches.
3. **Local branch / structure service** — vulnerable final service to structures/consumer groups.

### Water hierarchy

1. **Main potable source + treatment/storage** — broad municipal supply where planned.
2. **Pump/distribution / settlement service** — local distribution with real power dependency where pumping is electrical.
3. **Property / structure service** — local endpoint; rural properties may instead use planned private/shared wells.

### Candidate 001 if approved

1. **33A — Utility state foundation + plan materialization** — typed persistent state consuming 00D4/00D5 planning truth, stable identities, service bindings, snapshot/restore, revisions and cached service queries.
2. **33B — Power vertical slice** — causal three-tier power state, real local outages and fixed powered lights feeding System 27 through canonical emitter truth.
3. **33C — Potable-water vertical slice** — municipal service, rural well service and electrically driven pump dependency on real power.
4. **33D — Refrigeration consumer slice** — real powered refrigerator cold-storage availability feeding System 30 without adding item timers or moving freshness ownership.

Required ownership/performance rules:

- System 00D planning facts define topology/geography but are not runtime service state.
- No global `power_on` or `water_on` gameplay shortcut.
- No frame-driven network simulation, per-component timers or recurring whole-world scans.
- Runtime damage/disabled state is persistent typed truth.
- Service is derived/cached from required upstream state and revisions.
- System 27 remains physical-light owner; System 30 remains freshness owner.
- Water-service inspection may be implemented now, but thirst/drinking/liquid consequences remain Phase 4 or a later dedicated liquid system.
- Portable battery/fuel equipment is not silently faked merely to delete the current temporary flashlight adapter.
- Standalone wastewater/sewer gameplay remains outside the active roadmap.

**Lifecycle rule:** System 33 Candidate 001 requires explicit approval before runtime implementation begins.

---

## Phase 4 — Player physical survival and health

Goal: complete the physical survival loop.

Target set:

- hunger;
- thirst;
- sleep / exhaustion;
- health / injury;
- fatigue.

**Fatigue is the stamina/endurance concept. There is no separate stamina meter.**

---

## Phase 5 — Moodlets and mental/comfort pressure

Target families include comfort, fear, boredom, hunger, thirst and sleep/exhaustion. Underlying physical needs remain owned by physical-survival systems; Moodlets derive/read them rather than duplicating truth.

---

## Phase 6 — Final skills and broad item/world interactions

Target skill catalog:

- Awareness;
- Sneak;
- First Aid;
- Cooking;
- Carpentry;
- Mechanical;
- Electrical;
- Fishing;
- Farming.

**Hunting is not a separate skill.** It emerges from Sneak, future shooting/combat proficiency and crafted trap placement.

> **Real state first, presentation downstream.**

---

## Phase 7 — Vehicles

Requested classes: cars, trucks, motorcycles, bicycles and skateboards.

Long-term direction includes persistent condition/damage/cargo, authoritative action-time movement, collision/world damage, utility/tree/object interaction and Mechanical skill integration.

---

## Phase 8 — Actor/NPC AI, combat, and causal outbreak

Scope includes infected/zombie AI, survivor/follower/raider AI, melee/firearms, NPC use of the same physical perception and world systems as the player, conversations, population/coarse distant behavior and the causal outbreak/collapse.

AI receives observer knowledge, not hidden world truth.

---

## Phase 9 — Final graphics and UI overhaul -> Beta

Scope includes final control/layout audit, phone/Safari + desktop layouts, inventory/menu/icon consistency, interaction readability, world-art cleanup, shadows/lighting/weather/sound presentation, removal of obsolete DEV UI, accessibility and final performance work.

**Completion of Phase 9 is the planned Beta start gate.**

---

## Non-numbered engineering gates

Insert when required without changing gameplay phase order:

- save/load orchestration before new persistent state becomes unsafe to lose;
- schema migration/invalidation policy while pre-Beta may still invalidate old saves;
- performance profiling before population-scale AI, many simultaneous observers, moving lights, vehicles or large utility graphs;
- persistence-backed streaming eviction only when current WHAT truth remains preserved;
- mobile/browser hard-pause and input regressions throughout.

---

## Roadmap discipline

For each bounded phase/system:

1. recover current implementation truth;
2. DESCRIBE the bounded owner/refactor;
3. obtain approval when required;
4. IMPLEMENT through stable seams;
5. VERIFY the exact executable head;
6. perform human play/visual acceptance when behavior or generated-world layout materially changes;
7. update roadmap/context when completed work changes what comes next.

Newest explicit user direction supersedes older roadmap ordering, but implemented historical systems remain current truth until deliberately migrated.

**Current next step: approve or revise `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`. Runtime implementation begins only after explicit approval.**
