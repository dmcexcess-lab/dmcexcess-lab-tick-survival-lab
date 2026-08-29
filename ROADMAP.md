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
- **Compact-island/world-seam cleanup — REOPENED.** The attempted planner repair `918f1dbd7b033fa179522a112b1507d9a2c63890` passed automated CI but caused a severe user-visible gameplay regression and was rolled back.
- **Current restored runtime:** `f6a06add3dfd212c0c29b343d24a8f7d28a89bca`, restoring the pre-regression planner. Its Pages deploy passed.
- **Known remaining cleanup defect:** System 00D again fails the strict `Legacy Crossroads Is Not Embedded In Island` alternate-seed seam check. Do not weaken that validator.
- **Next engineering gate:** repair and human-accept the reopened island seam using a focused planner fixture before closing cleanup.
- **Next gameplay phase after cleanup acceptance:** Phase 3 Power and Water — DESCRIBE. No Phase-3 runtime implementation is pre-authorized.

---

## Phase 1 — Items, spoilage, interaction readability, and world-object breadth — COMPLETE

Goal: make the physical world and the things in it useful/readable before deeper character systems arrive.

### 1A — Interaction affordance + reach — COMPLETE

System 29 owns neutral reach + interaction-offer composition.

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Implemented result includes shared `CONTACT_FORWARD` reach, real read-only interaction offers, System-23 visibility gating, bounded local OBJECT discovery, and presentation-only highlights.

### Performance architecture gate — COMPLETE + HUMAN ACCEPTED

The P0/P1/P2 performance architecture and Weather presentation optimization are complete and human-accepted on phone/Safari.

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

## World-generation cleanup gate — REOPENED

The playable island remains `temperate.island.region` v3 over the protected rural-v6 planning skeleton.

Already-valid cleanup work remains in place:

- fresh new-game seeds redraw island identity rather than aliasing the historical standalone critique fixture;
- central local-site seed derives from world seed + site identity;
- the playable island does not carry the old 640-cell regional stress-fixture protected-cross half-span;
- compact island spacing removes the former giant green belt;
- natural ecology stays coherent across logical source rectangles using world seed + absolute global cell;
- spawn remains on inherited pavement rather than the diner entrance.

### Remaining defect

The strict alternate-seed System-00D seam identifies `island_base_site_overlap:area.smalltown.center.001` under at least one legal seed.

The first attempted repair changed global settlement candidate rejection from the historical 160-cell center-distance heuristic to exact 256x256 rectangle-overlap rejection. Automated CI passed on `918f1dbd7b033fa179522a112b1507d9a2c63890`, but human play found the deployed game severely broken. That repair was therefore rejected and rolled back in `f6a06add3dfd212c0c29b343d24a8f7d28a89bca`.

### Required repair discipline

Before another live planner change:

1. reproduce the bad alternate-seed placement in a focused planner fixture;
2. characterize the intended settlement-layout invariants beyond simple non-overlap;
3. make the smallest deterministic planner change that satisfies those invariants;
4. run System 00D, System 20, streaming, performance, canonical startup and Pages checks;
5. **human-play the generated island** before marking cleanup complete.

A green validator suite alone is not sufficient evidence for this cleanup after the `918f1db...` regression.

---

## Phase 3 — Power and Water — NEXT GAMEPLAY PHASE AFTER CLEANUP

Goal: add causal, damageable **three-tier utility networks** rather than global on/off switches.

### Power hierarchy

1. **Main generation / major source** — broad regional supply, robust and slow to fail.
2. **Substations / local distribution facilities** — several areas, semi-frequent failure.
3. **Distribution lines / structure service** — vulnerable local branches damaged by trees, vehicles, combat or later player/NPC actions.

### Water hierarchy

1. **Main treatment/waterworks source** — broad regional supply and slow failure.
2. **Pump stations / local distribution** — several areas, semi-frequent failure.
3. **Local mains/hydrants/structure service** — vulnerable local access and repair/damage seams.

Required ownership rules:

- Phase 3 may consume System-00D planning facts but planning records are not runtime utility state.
- Real utility state must be persistent world truth, not renderer/UI state or a global boolean shortcut.
- Powered lights, neon, TVs, pumps and appliances feed real active state into existing physical systems.
- Utility damage/failure persists through normal world-state architecture.
- Mechanical/Electrical skills later attach to real repair actions.
- System 30 may consume real refrigeration availability only after Phase 3 establishes real power + appliance state.
- Standalone wastewater/sewer gameplay is removed from the active roadmap; existing wastewater planning may remain inert until deliberate cleanup.

**Lifecycle rule:** Phase 3 must be DESCRIBED and approved before runtime implementation begins.

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

**Current next step: resolve and human-accept the reopened compact-island/world-seam cleanup. After that, DESCRIBE Roadmap Phase 3 — Power and Water.**
