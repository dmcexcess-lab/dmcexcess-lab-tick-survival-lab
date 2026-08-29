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
- **Phase 2 — COMPLETE.** System 32 Crafting / Material Transformation Candidate 001 is implemented and CI verified.
- **Compact-island/world-seam cleanup — COMPLETE.** Exact executable `918f1dbd7b033fa179522a112b1507d9a2c63890` is green with zero failed and zero in-progress exact-head Actions runs after settlement-site overlap repair.
- **Current next lifecycle gate: Phase 3 Power and Water — DESCRIBE.** No Phase-3 runtime implementation is pre-authorized by completion of prior phases.

---

## Phase 1 — Items, spoilage, interaction readability, and world-object breadth — COMPLETE

Goal: make the physical world and the things in it useful/readable before deeper character systems arrive.

### 1A — Interaction affordance + reach — COMPLETE

System 29 owns neutral reach + interaction-offer composition.

Core rule:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Implemented result includes shared `CONTACT_FORWARD` reach, real read-only interaction offers, System-23 visibility gating, bounded local OBJECT discovery, and presentation-only highlights.

### Performance architecture gate — COMPLETE + HUMAN ACCEPTED

The P0/P1/P2 performance architecture and Weather presentation optimization are complete and human-accepted on phone/Safari.

Protected direction remains event-driven/cache-oriented invalidation, bounded queries and shared derived plans rather than recurring world scans, per-cell/per-item Nodes/timers or frame-driven simulation.

### 1B — Item freshness / spoilage — COMPLETE

System 30 Candidate 001 is implemented and verified.

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Refrigeration remains inactive until Phase 3 supplies real powered-appliance truth. Phase 4 later owns eating/drinking/health consequences.

### 1C — Semantic inventory/menu icons — COMPLETE

System 31 is implemented and verified.

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

### 1D — Large/multi-cell object visual geometry — COMPLETE

System 07B is implemented and CI verified.

Core rule:

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

Large-tree/traffic-light presentation, actor-overhang layering and emitter-derived glow remain presentation-only and do not redefine collision, reach, LOS, WHEN, save or streaming truth.

### 1E — Content expansion + integration — COMPLETE

Canonical design: `SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.

Core rule:

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Implemented result includes broader deterministic building/location dressing, expanded mundane/location-aware loot, broader perishables, complete icon coverage for shipped item semantics and permanent integration/performance verification without fake future Crafting/Power/Health/Skills/Vehicles/AI behavior.

Verified Phase-1E executable: `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

---

## Phase 2 — Crafting — COMPLETE + CI VERIFIED

Canonical design:

`SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`

System owner: **System 32 Crafting / Material Transformation**.

Verified executable:

`8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`

Exact-head context: `verify/system32-crafting`.

Core rule:

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Implemented Candidate 001:

1. **2A — Recipe + plan foundation** — exact-semantic recipe/workstation catalogs, deterministic ingredient/tool selection from real personal possession, positive physical-weight/carry/freshness validation and no abstract stack/resource wallet.
2. **2B — Timed physical transformation** — positive-duration CANCELABLE `crafting.craft_recipe` WHEN action, final-commit revalidation, real input removal, deterministic new persistent outputs, actor-root containment, hard carry ceiling and bounded compensation journal rather than whole-world snapshots.
3. **2C — Workstation + player integration** — explicit heavy-workbench capability, System-29 `CONTACT_FORWARD` `CRAFT` offer and phone/Safari-first Crafting UI integrated into the canonical player shell.

System 32 deliberately does not own Construction/Repair/Durability, Cooking/Nutrition, Power/Water, Skills/quality/XP, Vehicles, combat/ammunition or AI. Later owners may reuse its physical-transformation substrate through explicit contracts.

---

## World-generation cleanup gate — COMPLETE + CI VERIFIED

The compact playable island is `temperate.island.region` v3 over the protected rural-v6 planning skeleton.

Completed cleanup includes:

- fresh new-game world seeds redraw authoritative island identity rather than aliasing the historical standalone critique fixture;
- central local-site seed derives from world seed + site identity;
- the playable island no longer carries the old 640-cell regional stress-fixture protected-cross half-span; island v3 uses a compact local protected cross;
- central-to-small-town spacing remains bounded instead of exposing a giant green belt;
- natural ecology remains coherent across logical source rectangles using world seed + absolute global cell;
- global settlement placement now rejects actual positive-area 256x256 site-rectangle overlap rather than relying on an insufficient center-distance heuristic.

Final verified cleanup executable:

`918f1dbd7b033fa179522a112b1507d9a2c63890`

On that exact head the formerly failing island legacy-seam smoke, System 00D, System 20, streaming, canonical shell, Crafting, performance architecture, canonical startup and Pages deployment are green. Exact-head Actions settled with zero failures and zero in-progress runs.

---

## Phase 3 — Power and Water — NEXT: DESCRIBE

Goal: add causal, damageable **three-tier utility networks** rather than global on/off switches.

### Power hierarchy

1. **Main generation / major source** — broad regional supply, robust and slow to fail.
2. **Substations / local distribution facilities** — several areas, semi-frequent failure.
3. **Distribution lines / structure service** — vulnerable local branches damaged by trees, vehicles, combat or later player/NPC actions.

### Water hierarchy

1. **Main treatment/waterworks source** — broad regional supply and slow failure.
2. **Pump stations / local distribution** — several areas, semi-frequent failure.
3. **Local mains/hydrants/structure service** — vulnerable local access and repair/damage seams.

### Required ownership rules

- Phase 3 must consume existing System-00D planning facts where appropriate without treating planning records as runtime utility state.
- Real utility state must be persistent world truth, not renderer/UI state and not a global boolean shortcut.
- Powered lights, neon, TVs, pumps and appliances feed real active state into existing physical systems.
- Utility damage/failure persists through the normal world-state architecture.
- Mechanical/Electrical skills later attach to real repair actions rather than being prebuilt here.
- Vehicles/trees may later damage local distribution through ordinary physical damage seams.
- System 30 may consume **real refrigeration availability** only after Phase 3 establishes real power + appliance state.
- Standalone wastewater/sewer gameplay is removed from the active roadmap. Existing generated wastewater planning may remain inert until deliberate migration/cleanup.

**Lifecycle rule:** Phase 3 must be DESCRIBED and approved before runtime implementation begins.

---

## Phase 4 — Player physical survival and health

Goal: turn existing actor-status scaffolds into the complete physical survival loop.

Final target set:

- hunger;
- thirst;
- sleep / exhaustion;
- health / injury;
- fatigue.

**Fatigue is the stamina/endurance concept. There is no separate stamina meter.**

Conceptual split:

- fatigue = short-horizon exertion/endurance pressure from running, carrying and strenuous actions;
- sleep pressure/exhaustion = long-horizon need for sleep and severe sleep-deprivation consequences.

Food/drink/sleep/treatment become real actions here or through later specialized skill ownership. System 30 freshness is read when appropriate but does not own nutrition, sickness or Health.

Extreme unmet needs may become lethal; death from exhaustion remains an intended possible terminal consequence.

---

## Phase 5 — Moodlets and mental/comfort pressure

Goal: make survivor state readable and consequential without creating a giant psychology simulator.

Target families include:

- comfort;
- fear;
- boredom;
- hunger;
- thirst;
- sleep/exhaustion.

Underlying hunger/thirst/sleep/fatigue truth remains with physical-survival owners. Moodlets derive/read those facts rather than duplicating them. Comfort/fear/boredom may own only the minimum persistent history genuinely required.

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

The current generic Combat / Scavenging / Survival / Medical / Technical / Social catalog is an implementation scaffold, not final identity; migrate rather than layer duplicates.

**Hunting is not a separate skill.** It emerges from Sneak, future shooting/combat proficiency and crafted trap placement.

General object-interaction rule:

> **Real state first, presentation downstream.**

Example: a TV switches on only if real state/power permits, then may feed real light and localized sound/information presentation.

---

## Phase 7 — Vehicles

Goal: make transport another persistent physical system using the same world/time/collision rules.

Requested classes:

- cars;
- trucks;
- motorcycles;
- bicycles;
- skateboards.

Long-term direction includes persistent condition/damage/cargo, authoritative action-time movement, collision/world damage, utility/tree/object interaction, Mechanical skill integration, and eventually physical Mad-Max-style car/truck modifications rather than abstract levels.

---

## Phase 8 — Actor/NPC AI, combat, and causal outbreak

Scope includes:

- infected/zombie AI;
- survivor AI;
- follower AI;
- raider/hostile-human AI;
- player/NPC combat needed for the Beta loop;
- melee and firearm/shooting behavior;
- NPC use of the same physical vision/light/hearing/weather/movement/utilities/items/vehicles available to the player;
- follower/player idle conversations influenced by mood/personality/context;
- population/household/coarse distant behavior needed for the causal outbreak;
- outbreak spread/collapse and the existing 00E player-story direction.

AI receives observer knowledge, not hidden world truth. It never reads framebuffer lighting, exact hidden sound sources or omniscient object lists.

This phase is intentionally grouped late but will still be split into bounded system designs internally.

---

## Phase 9 — Final graphics and UI overhaul -> Beta

Scope includes:

- audit/control placement for actual play;
- phone/Safari and desktop as first-class layouts;
- final inventory/menu/icon consistency;
- final interaction/highlight readability;
- final world-art/content cleanup;
- convincing item/prop shadows while System 27 remains authoritative;
- polish lighting/weather/sound-word presentation without changing simulation ownership;
- isolate/remove obsolete DEV UI from normal player flow;
- final accessibility/readability/performance pass.

**Completion of Phase 9 is the planned Beta start gate.**

---

## Non-numbered engineering gates

Insert when required without changing gameplay phase order:

- save/load orchestration before new persistent state becomes unsafe to lose;
- schema migration/invalidation policy while pre-Beta may still invalidate old saves;
- performance profiling before population-scale AI, many simultaneous observers, moving lights, vehicles or large utility damage graphs;
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
6. update roadmap/context when completed work changes what comes next.

Newest explicit user direction supersedes older roadmap ordering, but implemented historical systems remain current truth until deliberately migrated.

**Current next step: DESCRIBE Roadmap Phase 3 — Power and Water. No Phase-3 runtime implementation is authorized yet.**
