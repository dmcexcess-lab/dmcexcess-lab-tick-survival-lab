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

All **16 required exact-head contexts** are green on the executable, including `verify/system30-item-freshness` and `verify/pages-deploy`.

### 1C — Semantic inventory/menu icons — COMPLETE

Canonical design:

`SYSTEM_DESIGNS/31_SEMANTIC_UI_ICONS.md`

System 31 Candidate 001 is implemented and verified.

Current verified executable: `dc83ad10b7469a629fb2ac5d86c77d386b69434d`.

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

Implemented result:

- System 31 is a presentation-only semantic UI icon system;
- one dedicated low-resolution atlas with 16×16 logical icon cells normally drawn at 32×32;
- one shared Node-free/cached `SemanticUiIconCatalog`;
- all current 71 loot semantic types receive explicit icon mappings, with intentional sharing allowed but no automatic family fallback;
- unknown future semantics receive an honest unknown glyph + diagnostic while text remains usable;
- Stats / Inventory / Menu become icon + text rather than icon-only;
- hands, carried inventory, scavenging contents, and `YOUR PACK` use the same semantic item vocabulary;
- TAKE / STORE, movement, and DEV controls stay text-only in Candidate 001;
- labels, stable IDs, weight, utility/family, freshness and later mechanic truth stay beside the icon;
- no persistent state, simulation tick work, per-item runtime objects, or world scan;
- selected held-item silhouettes may be visually repacked into the UI atlas, but System 31 has no runtime dependency on System 10;
- `verify/system31-semantic-ui-icons` proves all current mappings, cache/failure behavior, protected System-16/24/30 regressions and canonical startup;
- all **17 required exact-head contexts** are green, including `verify/pages-deploy`.

No separate human visual-acceptance claim is recorded for the post-width-fix appearance; executable/CI verification is complete.

### 1D — Large/multi-cell object visual geometry — DESCRIBED: AWAITING APPROVAL

Canonical draft:

`SYSTEM_DESIGNS/07B_LARGE_MULTI_CELL_VISUAL_GEOMETRY.md`

Goal: let physical multi-cell objects actually look large instead of drawing one recovered one-cell sprite at their anchor, while keeping visual geometry independent from authoritative collision/world footprint.

Candidate 001 direction:

- System 07B is a presentation-only child of the existing System 07 renderer, not a new gameplay/world system;
- a Node-free visual descriptor supplies authored whole-cell draw span, anchor-attached pivot and optional foreground/overhang art;
- physical footprint remains WHERE/WHAT truth and may differ from decorative visual overhang;
- System 07A remains facing/orientation owner;
- one stable entity produces one shared logical visual plan rather than repeated/stretched icons per occupied cell;
- the ordinary base/body pass stays at z=20 while an optional foreground/overhang pass sits at z=35 above actors and below physical lighting;
- a small catalog-derived discovery halo allows an offscreen physical anchor to contribute visible canopy/arm overhang without any whole-world scan;
- explicit large art remains resolved through System 04;
- first examples are a 2×2-or-larger large tree and larger traffic/stop lights;
- future vehicles and final prop shadows may reuse this presentation seam but are not part of Candidate 001;
- implementation requires dedicated `verify/system07b-large-visual-geometry` coverage plus all protected exact-head regressions.

**Runtime implementation is not authorized until the draft is approved.**

### 1E — Phase-1 content expansion + integration

Goal: use 1A–1D foundations to make ordinary locations richer before Crafting.

Planned direction:

- broaden mundane survival item/loot content and perishables;
- broaden props/fixtures/vegetation in existing building/area profiles;
- add large trees/traffic furniture using 1D rather than fake one-cell art;
- add interaction capability only where a real owning action exists;
- tune highlight density, icon readability and freshness labels together on phone/Safari;
- retain System 24's rule: **loot exists before you search for it.**

### Phase-1 completion gate

Phase 1 is complete when:

- nearby usable containers/objects are identifiable from real reach + perception truth;
- perishables age deterministically with no per-item tick loop;
- inventory/menu surfaces have a coherent low-resolution icon vocabulary;
- multi-cell objects may have intentionally large authored visuals independent from collision footprints;
- representative buildings/areas use the broader item/object vocabulary;
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

**Current next step: APPROVE or revise the bounded System-07B Candidate-001 design for Phase 1D. Runtime implementation is not authorized yet.**
