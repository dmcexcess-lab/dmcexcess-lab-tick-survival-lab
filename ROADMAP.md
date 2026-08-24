# Tick Survival Lab — Roadmap to Beta

Status: **canonical priority roadmap**.

This file answers **what major gameplay work comes next and in what order**. It does not replace system designs. Each phase is still implemented through bounded, approved subsystem designs under `README_SOPS.md`.

Current game identity remains:

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

The numbered order below reflects the 2026-08-24 roadmap update. Existing foundations and Systems 19–28 are the platform underneath it.

---

## Phase 1 — Items, spoilage, interaction readability, and world-object breadth

Goal: make the physical world and the things in it much more useful/readable before deeper character systems arrive.

Planned work:

- real item spoilage using authoritative world time;
- expand usable item/content breadth without fake interactions;
- inventory and menu icons;
- readable proximity highlighting for containers and world objects the player is actually close enough to use;
- preserve System 23 knowledge rules: highlighting may clarify an already-acquired usable object, but must never reveal an unseen object through fog/geometry;
- broaden environment/object content, including larger physical props and multi-cell footprints where appropriate;
- examples explicitly requested: larger stoplights and trees that can occupy a 2×2 / four-cell footprint;
- keep art semantic: object size/footprint belongs to physical world truth, not sprite pixels.

This phase may extend Systems 11/12/13D/19/20/24 and the existing render/UI seams, but should not turn the renderer into interaction authority.

---

## Phase 2 — Crafting

Goal: make collected materials physically useful.

Planned direction:

- recipes consume real persistent inputs and create real persistent outputs;
- crafting spends WHEN time;
- tools/workstations/required conditions are real world/item facts rather than menu-only gates;
- outputs enter ordinary inventory/world containment;
- later Phase-6 skills modify capability, quality, speed, recipe access, or outcome through narrow skill seams rather than being baked into the crafting owner;
- carpentry/base-building, traps, repairs and specialized utility/vehicle work may reuse the same general crafting/action substrate while remaining owned by their relevant systems.

---

## Phase 3 — Power and water utilities

Goal: add a causal, damageable three-tier utility network that can fail locally or regionally instead of using a global on/off switch.

### Power — three tiers

1. **Main generation facility / major source**
   - supplies roughly one-half to one-third of the playable map/region;
   - robust and slow to fail after collapse;
   - its loss creates broad regional consequences.

2. **Substations / local distribution facilities**
   - each supplies several technical/local areas;
   - fail semi-often compared with the main facility;
   - allow partial neighborhoods/districts to go dark while other areas remain powered.

3. **Distribution lines / structure service**
   - bring power to individual structures/local branches;
   - fail relatively often;
   - may be physically broken by falling trees, vehicle impacts, damage, or later player/NPC actions;
   - local failure does not require the whole upstream network to be dead.

### Water — same causal hierarchy

1. **Main treatment/water-works source** — broad regional supply and slow failure.
2. **Pump stations / local distribution facilities** — several areas, semi-frequent failure.
3. **Local mains, hydrants and structure service** — vulnerable local distribution/access points and repair/damage seams.

The exact water-source vocabulary (treatment plant, reservoir/intake, etc.) is finalized in the dedicated design; the important locked rule is the **same three-tier causal hierarchy** as power.

### Wastewater

**Standalone wastewater/sewer gameplay is removed from the active roadmap.** Existing System-00D wastewater planning may remain inert historical/generated data until a deliberate cleanup/migration pass; it must not force a wastewater gameplay system back into scope.

### Downstream seams

- powered lights, neon, TVs, pumps and appliances feed their real active state into System 27 rather than faking emissive art;
- utility failures are persistent world consequences;
- Phase-6 Mechanical/Electrical skills later attach to repair/maintenance actions;
- Phase-7 vehicles can damage local distribution without utilities importing vehicle logic;
- tree-fall/damage systems can use the same damage seam later.

---

## Phase 4 — Player physical survival and health

Goal: turn the existing actor-status scaffolds into the complete playable physical survival loop.

Final target set from the roadmap update:

- **hunger**;
- **thirst**;
- **sleep / exhaustion**;
- **health / injury**;
- **stamina**.

Important migration rule:

The current implementation already contains `fatigue`, hunger, thirst, sleep pressure and Health scaffolds. The Phase-4 design must **reconcile current fatigue with the new stamina/exhaustion model** rather than blindly adding a second redundant short-horizon exertion meter. Existing fields are implementation history, not a requirement to keep duplicate concepts.

Consequences should affect capability and action speed through normal action/movement providers. Extreme unmet needs can become lethal; **death from exhaustion is an intended possible terminal consequence** once the owning physical-survival rules are implemented.

Food/drink/sleep/treatment actions become real item/world interactions here or through the Phase-6 specialized skill layer as appropriate.

---

## Phase 5 — Moodlets and mental/comfort pressure

Goal: make the survivor's state readable and consequential without creating a giant psychology simulator.

Requested mood/status families:

- comfort;
- fear;
- boredom;
- hunger;
- thirst;
- sleep/exhaustion.

These escalate through meaningful severity states and can cause gameplay consequences such as action-speed/capability penalties and behavioral pressure.

Ownership rule:

- hunger/thirst/sleep truth remains owned by the physical-survival systems;
- Moodlets derive/read those truths rather than duplicating them;
- comfort/fear/boredom may own the minimum persistent state/history genuinely required by their mechanics;
- Moodlets may expose derived modifier providers, but do not become a second Health/Needs engine.

---

## Phase 6 — Final skills and broad item/world interactions

Goal: replace the current generic skill scaffold with the concrete skills that actually correspond to player actions.

### Target skill catalog

- **Awareness**;
- **Sneak**;
- **First Aid**;
- **Cooking**;
- **Carpentry**;
- **Mechanical**;
- **Electrical**;
- **Fishing**;
- **Farming**.

The existing generic Combat / Scavenging / Survival / Medical / Technical / Social catalog is a current implementation scaffold, **not the final skill identity**. Phase 6 deliberately migrates it rather than layering duplicate skills on top.

### Skill/action meaning

- Awareness plugs into observer/perception capability without bypassing Systems 23/26/27 truth;
- Sneak affects how visible/audible the actor is and later how AI detects them;
- First Aid owns skill influence on treatment and infection care, while Health/Infection retain physical truth;
- Cooking acts on real food/items;
- Carpentry covers physical base construction and related crafted structures;
- Mechanical covers vehicles, plumbing/mechanical repair and other appropriate machinery;
- Electrical covers electrical repair/installation/use;
- Fishing and Farming own their respective action proficiency.

**Hunting is not a separate skill.** Hunting emerges from how quietly the player moves, how well the relevant future combat/shooting mechanics perform, or where/how a crafted trap is placed. Phase 8 defines the final combat/shooting proficiency shape; this roadmap does not invent a redundant Hunting stat.

### Final general object interactions

This phase also closes the broad interaction vocabulary for ordinary world objects. Example explicitly requested:

- a TV can be switched on only if its real state/power allows it;
- an active TV can emit real System-27 glow/light;
- its audible/dialogue information can appear as localized yellow words through the sound/knowledge presentation path rather than through a decorative fake source.

The same pattern applies to switches, appliances, fixtures and interactable machinery: **real state first, presentation downstream.**

---

## Phase 7 — Vehicles

Goal: make transportation another persistent physical system using the same world/time/collision rules.

Vehicle classes requested:

- cars;
- trucks;
- motorcycles;
- bicycles;
- skateboards.

Long-term vehicle direction:

- persistent condition/damage/cargo;
- movement through the authoritative tick/action system;
- collision and world damage;
- utility-line/tree/object interaction through normal damage seams;
- Mechanical skill integration;
- cars and trucks can eventually be modified **Mad-Max-style** with physical upgrades rather than abstract vehicle levels.

Exact fuel/battery, momentum, occupancy and modification-slot designs remain dedicated vehicle-system decisions.

---

## Phase 8 — Actor/NPC AI, combat, and causal outbreak

Goal: make the completed physical/sensory world populate itself with dangerous and believable actors.

This phase intentionally groups the late, strongly coupled actor layer, but it will still be implemented as multiple bounded system designs.

Scope includes:

- infected/zombie AI;
- survivor AI;
- follower AI;
- raider/hostile-human AI;
- all player/NPC combat needed for the Beta game loop;
- melee and firearm/shooting behavior;
- NPC use of the same physical vision, light, hearing, weather, movement, utilities, items and vehicles available to the player;
- follower/player idle conversations influenced by mood/personality/context;
- survivor/raider behavior and social decisions;
- population/household/coarse distant behavior needed for the causal outbreak;
- outbreak spread/collapse behavior and the existing 00E player-story direction.

AI receives observer knowledge, not hidden world truth. It does not read framebuffer lighting, exact hidden sound sources, or omniscient object lists.

Idle conversation may use the project's yellow-word presentation style, but the conversation decision/content must come from real actor state/context rather than renderer randomness.

---

## Phase 9 — Final graphics and UI overhaul → Beta

Goal: perform the final presentation/usability pass only after the major gameplay systems reveal what the interface actually needs.

Scope explicitly includes:

- audit every player button/control and put it in the best place for actual play;
- phone/Safari and desktop layouts both remain first-class;
- final inventory/menu/icon consistency;
- final interaction/highlight readability;
- final world-art/content cleanup;
- add/finish convincing shadows on items/props where appropriate while keeping System 27/backend truth authoritative;
- polish lighting/weather/sound-word presentation without changing simulation ownership;
- remove obsolete DEV UI from ordinary player flow or clearly isolate it;
- final accessibility/readability/performance pass.

**Completion of Phase 9 is the planned Beta start gate.**

---

## Non-numbered engineering gates

These do not reorder the gameplay phases, but must be inserted when required by persistence/safety/scale:

- save/load orchestration before newly persistent gameplay state becomes unsafe to lose;
- schema migration/invalidation policy while pre-Beta remains free to invalidate old saves;
- performance profiling before population-scale AI, many simultaneous observers, moving lights, vehicles or large utility damage graphs;
- persistence-backed streaming eviction only after it can preserve the same current WHAT truth;
- mobile/browser hard-pause and input regressions remain required throughout.

---

## Roadmap discipline

The roadmap is an **order and scope guide**, not blanket authorization to code nine phases at once.

For each phase:

1. recover the current implementation truth;
2. DESCRIBE the bounded owning system/refactor;
3. obtain approval when required;
4. IMPLEMENT through stable seams;
5. VERIFY the exact executable head;
6. update this roadmap/context if the completed work changes what comes next.

Newest explicit user direction supersedes older roadmap ordering, but implemented historical systems remain current truth until deliberately migrated.