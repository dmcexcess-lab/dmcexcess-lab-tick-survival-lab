# Tick Survival Lab — Roadmap to Beta

Status: **canonical priority roadmap**.

This file answers what major gameplay work comes next and in what order. It does not replace system designs. Each independently owned phase/system still follows `README_SOPS.md` and the normal **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY** lifecycle.

Current game identity:

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

---

## Phase 1 — Items, spoilage, interaction readability, and world-object breadth

Goal: make the physical world and the things in it more useful/readable before deeper character systems arrive.

### 1A — Interaction affordance + reach — COMPLETE

System 29 Candidate 001 is implemented.

Core rule:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Implemented result includes shared `CONTACT_FORWARD` reach, real read-only interaction offers, System-23 visibility gating, bounded local OBJECT discovery, and presentation-only highlights.

### Performance architecture gate — COMPLETE + HUMAN ACCEPTED

The P0/P1/P2 performance architecture and subsequent Weather presentation optimization are complete and human-accepted on phone/Safari.

First P0/P1/P2 fully green executable: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Human-accepted Weather P3D executable: `6016fe5098804e3e6aba6c9f5f9658282036a697`.

Predictive/amortized streaming remains a measured follow-up only if evidence later justifies it.

### 1B — Item freshness / spoilage — COMPLETE

System 30 Candidate 001 is implemented and verified.

First fully green executable: `39716f27b7f91b7007645ceae02dedc47601bf87`.

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Implemented result:

- explicit perishable semantic profiles;
- sparse typed per-instance freshness records;
- FRESH / AGING / STALE / SPOILED derived analytically;
- no per-item tick loop, timer, Node or scheduled spoilage event;
- ambient cumulative exposure provider plus neutral future storage-context seam;
- deterministic bounded virgin starting age;
- virgin world perishables use logical scenario origin tick 0 even when streamed later;
- System 24 enrolls perishables inside the same rollback-safe source-initialization transaction;
- production loot probabilities/search/transfer timing are unchanged;
- inventory/container inspection exposes coarse freshness labels;
- refrigeration remains inactive until Phase 3 supplies real power/appliance truth;
- Phase 4 later owns eating/drinking/health consequences.

### 1C — Semantic inventory/menu icons — COMPLETE

Canonical design:

`SYSTEM_DESIGNS/31_SEMANTIC_UI_ICONS.md`

System 31 Candidate 001 is implemented and verified.

First verified executable: `dc83ad10b7469a629fb2ac5d86c77d386b69434d`.

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

Implemented result:

- presentation-only semantic UI icon system;
- dedicated low-resolution atlas with 16x16 logical icon cells normally drawn at 32x32;
- one shared Node-free/cached `SemanticUiIconCatalog`;
- all current loot semantic types receive explicit icon mappings, with intentional sharing allowed but no automatic family fallback;
- unknown future semantics receive an honest unknown glyph + diagnostic while text remains usable;
- Stats / Inventory / Menu use icon + text;
- hands, carried inventory, scavenging contents, and `YOUR PACK` use the same semantic item vocabulary;
- labels, stable IDs, weight, utility/family and freshness remain real data beside icons;
- no persistent state, simulation tick work, per-item runtime objects or world scan.

### 1D — Large/multi-cell object visual geometry — COMPLETE + CI VERIFIED

Canonical design:

`SYSTEM_DESIGNS/07B_LARGE_MULTI_CELL_VISUAL_GEOMETRY.md`

Verified executable/workflow head:

`d5e33b43fb732835b4a996ae4bec3a562cfa75f3`

Core rule:

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

Implemented result:

- System 07B remains a presentation-only child of System 07;
- Node-free descriptors provide authored whole-cell visual span, anchor-attached pivot and optional foreground/overhang art;
- physical footprint remains WHERE/WHAT truth and may differ from decorative visual overhang;
- System 07A remains facing/orientation owner;
- one stable entity produces one cached shared logical visual plan rather than repeated icons per occupied cell;
- base/body remains z=20; optional foreground/overhang is z=35 above actors and below physical lighting;
- a catalog-bounded two-cell discovery halo allows just-offscreen anchors to contribute visible canopy/arm overhang without any whole-world scan;
- unmapped props retain exact historical 1x1 visual geometry;
- dedicated large-tree and traffic-light base/foreground art prove the seam;
- the existing System-27 presentation glow was broadened into a soft two-ring bloom, but only real System-27 emitter truth creates the glow;
- no collision/reach/LOS/WHEN/streaming/save-state truth was changed;
- all **18 required exact-head contexts** are green on `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`, including `verify/system07b-large-visual-geometry` and `verify/pages-deploy`.

Automated implementation/CI verification is complete. Separate human visual acceptance of the new large-object proportions/glow has not yet been recorded.

### 1E — Phase-1 content expansion + integration — DESCRIBED: AWAITING APPROVAL

Canonical draft:

`SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`

Phase type: cross-system content/integration work, **not a new System 32**.

Core rule:

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Candidate 001 is split into:

1. **1E-1 World clutter + location identity** — enrich the existing 24 System-19 building profiles and System-20 outdoor/roadside/environment content; deploy approved 07B large trees/traffic furniture through ordinary generation while preserving circulation/access/road/water rules.
2. **1E-2 Mundane loot + perishable breadth** — expand System-24 item/container vocabularies; every new item has System-13D weight and an explicit System-31 icon; every new perishable receives an explicit System-30 freshness profile; no generic stack system and no search-time reward rolls.
3. **1E-3 Integration/readability/performance acceptance** — tune location differentiation, clutter density, real System-29 highlight density, icon/freshness readability, large-object layering/glow and phone/Safari performance on the complete island.

Protected non-goals remain explicit: no fake Crafting, Power/Refrigeration, nutrition/Health, Skills, Vehicles, combat or AI behavior merely to make content look functional.

Implementation requires approval of the Phase-1E draft. The proposed dedicated verification owner is `verify/phase1e-content-integration`; an implementation head would need the current 18 contexts plus that new context.

### Phase-1 completion gate

Phase 1 is complete when:

- nearby usable containers/objects are identifiable from real reach + perception truth;
- perishables age deterministically with no per-item tick loop;
- inventory/menu surfaces have a coherent low-resolution icon vocabulary;
- multi-cell objects may have intentionally large authored visuals independent from collision footprints;
- representative buildings/areas use the broader item/object vocabulary and read as materially different kinds of places;
- content density remains navigable/readable/performance-safe on phone/Safari;
- no future Crafting/Power/Skills behavior is faked to make Phase 1 look complete.

---

## Phase 2 — Crafting

Goal: make collected materials physically useful.

Direction:

- recipes consume real persistent inputs and create real persistent outputs;
- crafting spends WHEN time;
- tools/workstations/conditions are real world/item facts rather than menu-only gates;
- outputs enter ordinary inventory/world containment;
- later Phase-6 skills modify capability/quality/speed/access through narrow seams rather than being baked into crafting ownership;
- carpentry/base building, traps, repairs and specialized utility/vehicle work may reuse the same action substrate while retaining clear ownership.

---

## Phase 3 — Power and Water

Goal: add causal, damageable three-tier utility networks rather than global on/off switches.

### Power hierarchy

1. **Main generation / major source** — broad regional supply, robust and slow to fail.
2. **Substations / local distribution facilities** — several areas, semi-frequent failure.
3. **Distribution lines / structure service** — vulnerable local branches damaged by trees, vehicles, combat or later player/NPC actions.

### Water hierarchy

1. **Main treatment/water-works source** — broad regional supply and slow failure.
2. **Pump stations / local distribution** — several areas, semi-frequent failure.
3. **Local mains/hydrants/structure service** — vulnerable local access and repair/damage seams.

Standalone wastewater/sewer gameplay is removed from the active roadmap. Existing generated wastewater planning may remain inert until deliberate cleanup/migration.

Downstream rules:

- powered lights/neon/TVs/pumps/appliances feed real active state into existing physical systems;
- utility failures are persistent world consequences;
- Mechanical/Electrical skills later attach to real repair actions;
- vehicles/trees may damage local distribution through ordinary damage seams;
- System 30's storage-environment seam may consume **real** refrigeration availability here; no fake refrigeration before that truth exists.

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

Food/drink/sleep/treatment become real actions here or through later specialized skill ownership. System 30 freshness is read when appropriate but does not own nutrition/sickness/Health.

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

**Current next step: APPROVE or revise `PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`. No Phase-1E runtime/content implementation is authorized yet.**
