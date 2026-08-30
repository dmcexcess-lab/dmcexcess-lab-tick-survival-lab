# Tick Survival Lab — Roadmap to Beta

Status: **canonical priority roadmap**.

This file answers what major gameplay work comes next and in what order. It does not replace system designs. Each independently owned phase/system follows `README_SOPS.md` and the normal **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY** lifecycle.

Current game identity:

> **Sprite-based zombie survival game.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

---

## Current milestone state

- **Phase 1 — COMPLETE.** Items, spoilage, interaction readability, semantic UI, large-object presentation, content breadth and integration are implemented.
- **Phase 2 — COMPLETE.** System 32 Crafting Candidate 001 is implemented and CI verified on `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.
- **Compact-island/world-seam cleanup — COMPLETE + HUMAN ACCEPTED.** Broad planner repair `918f1db...` remains rejected; focused local-window repair `282864f...` is accepted.
- **Responsiveness / black-screen recovery — HUMAN ACCEPTED.** Recovery executable `1f65bff312853a44858201b57d9df2e26ee64f80` restored the human-good full-window lighting/visibility path while preserving decision-pause responsiveness.
- **Phase 3 / System 33 Power + Water — IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Current executable including Stage B analytic physical power distribution: `7ddee8df0e638cbe14897d83632b62513d5fc574`.
- **Current gameplay lifecycle gate:** human browser verification of Stage B plus current System-33 lighting/water/refrigeration behavior.

---

## Phase 1 — Items, spoilage, interaction readability, and world-object breadth — COMPLETE

Goal: make the physical world and the things in it useful/readable before deeper character systems arrive.

### 1A — Interaction affordance + reach — COMPLETE

System 29 owns neutral reach + interaction-offer composition.

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

### Performance architecture gate — COMPLETE + HUMAN ACCEPTED

The current playable lineage uses bounded per-frame action resolution, WHEN decision-pause input locking, stale-input rejection and event/cache-driven expensive consumers.

Protected direction remains event-driven/cache-oriented invalidation, bounded queries and shared derived plans rather than recurring world scans, per-cell/per-item Nodes/timers or frame-driven simulation.

### 1B — Item freshness / spoilage — COMPLETE

System 30 Candidate 001 is implemented and verified.

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

System 33 supplies real powered refrigerator cold-storage availability; System 30 still owns freshness math. Phase 4 later owns eating/drinking/health consequences.

### 1C — Semantic inventory/menu icons — COMPLETE

System 31 is implemented and verified.

### 1D — Large/multi-cell object visual geometry — COMPLETE

System 07B is implemented and CI verified.

### 1E — Content expansion + integration — COMPLETE

Canonical design: `SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.

---

## Phase 2 — Crafting — COMPLETE + CI VERIFIED

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

---

## World-generation cleanup gate — COMPLETE + HUMAN ACCEPTED

The playable island remains `temperate.island.region` v3 over the protected rural-v6 planning skeleton.

Accepted cleanup includes fresh island identity, coherent world-space ecology, inherited pavement spawn, compact spacing and focused island-local overlap repair `282864f242ba2a5c3df0519591e31990372c4aed` without redesigning global settlement placement.

Rejected attempt `918f1db...` remains historical evidence that green CI does not replace human generated-world acceptance.

---

## Phase 3 — Power and Water — IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING

Canonical designs:

- `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`
- `SYSTEM_DESIGNS/33B_POWER_PHYSICAL_NETWORK_CONDITION.md`

Current verified executable: `7ddee8df0e638cbe14897d83632b62513d5fc574`.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

### Implemented Candidate 001

1. **33A — Utility foundation** — persistent typed power/water state consuming 00D4/00D5 planning truth, stable service bindings, snapshot/restore, revisions and cached service queries.
2. **33B — Power** — causal three-tier service, typed outage/damage mutation, real fixed powered light integration into System 27 and canonical DEV controls.
3. **33C — Potable water** — municipal/rural service and electrically driven pump dependency on real power.
4. **33D — Refrigeration** — powered operational refrigerator cold-storage availability feeding System 30 without item timers.

### Truthful fixed/equipped lighting

The initial visible 33B integration was human-rejected because the runtime utility state was real while source ownership remained fake: an unconditional flashlight was passed through and static lights came from demo coordinates.

The repaired runtime now requires real WHAT fixture placement for fixed emitters, real System-33 service for powered fixtures, and a real `item.tool.flashlight` in a real hand slot for the player beam. The legacy demo source is inert. The user later reported this repaired source behavior looked good.

### Powered non-bloom interior lighting

Generated interiors previously had too few real visible light objects to make household power state easy to test. The refinement on `c7592c9...` adds one invisible persistent `fixture.room_light` WHAT entity per generated System-19 room.

- the fixture occupies a real room cell on the non-rendered EFFECT channel;
- its System-33 appliance binds to the power service for that actual cell;
- while powered it feeds a real `light.room_ambient.candidate001` emitter into System 27;
- the profile raises physical/local luminance but has `presentation_glow_scale = 0.0`;
- therefore a house can become visibly light/dark with power without inventing a glowing lamp graphic;
- ordinary streetlights, lamps, neon and flashlights retain visible bloom;
- local outage/restoration removes/restores affected room emitters through canonical System-33 state;
- no frame polling, per-room timer, camera-driven utility truth or recurring whole-world scan was added.

Dedicated verification: `verify/system33-lighting-truth`, including `RoomLightingPowerSmoke.gd`.

### Stage B — analytic physical power distribution

Stage B on `7ddee8d...` connects the physical overhead distribution world to the existing service runtime without adding a clocked grid simulation.

- 00D4 feeder edges now record deterministic `service_settlement_ids`, so the planner resolves downstream causality once.
- Physical wire spans receive stable condition identities and real pole/support IDs remain persistent WHAT identities.
- `UtilityNetworkConditionStore` derives utility-asset wear from authoritative time and event anchors; no asset has a timer, Node, scheduled event or daily update.
- `UtilityPowerNetworkRuntime` maps physical assets to actual System-33 services and translates failed assets into existing System-33 link state.
- Ordinary time advancement checks one sorted earliest predicted failure threshold and processes only assets actually due; it does not scan every line or iterate simulated days.
- Direct damage/repair is event-driven and reevaluates only mapped services.
- The regression proves a settlement-specific physical span can fail one downstream service while a sibling service remains energized, then repair restores the affected service.
- Existing cables remain visible while de-energized or damaged; render topology is not power-service truth.
- Fake regional-ingress/substation transformer clusters were removed. Final source/substation tactical facilities remain future facility-generation work rather than fake materializer props.
- The wire renderer now ignores unrelated world changes through a cached endpoint-ID lookup.

This Stage B architecture is also the intended reusable pattern for future physical water-network condition where appropriate: shared analytic condition substrate, domain-specific network owner, bounded event-driven consequences.

### Required ownership/performance rules

- System 00D planning facts define topology/geography but are not runtime service state.
- No global `power_on` or `water_on` gameplay shortcut.
- No frame-driven network simulation, per-component timers or recurring whole-world scans.
- No per-day catch-up loops and no per-tick all-line condition scan.
- Runtime damage/disabled state is persistent typed truth.
- Service is derived/cached from required upstream state and revisions.
- Physical asset condition is analytic from authoritative time/event anchors.
- System 27 remains physical-light owner; System 30 remains freshness owner.
- Presentation bloom is not illumination authority; a valid physical source may deliberately have zero additive glow.
- Failed/de-energized cable visibility is presentation of physical existence, not service state.
- Water inspection exists without inventing Phase-4 thirst/liquid consequences.
- Portable battery/fuel simulation remains outside Candidate 001.

### Human acceptance gate

Before Phase 3 / Stage B is marked human accepted, browser play must confirm:

1. generated house rooms visibly brighten when powered without a fake glowing room-light sprite;
2. `LOCAL PWR` removes/restores affected indoor illumination;
3. walls/doors still shape physical light and visible streetlights/other sources retain normal glow;
4. no phantom flashlight exists when none is equipped;
5. overhead power lines/poles remain visually stable and support placement remains correct;
6. water/pump and refrigerator service remain truthful;
7. movement/turning stays responsive and the black-screen regression does not return;
8. ordinary world-time advancement does not introduce a recurring utility hitch;
9. phone/Safari remains first-class.

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

Phase 4 may consume truthful System-33 water availability but must not move utility ownership into needs/health.

---

## Phase 5 — Moodlets and mental/comfort pressure

Target families include comfort, fear, boredom, hunger, thirst and sleep/exhaustion. Underlying physical needs remain owned by physical-survival systems.

---

## Phase 6 — Final skills and broad item/world interactions

Target skill catalog: Awareness, Sneak, First Aid, Cooking, Carpentry, Mechanical, Electrical, Fishing and Farming.

**Hunting is not a separate skill.** It emerges from Sneak, future combat proficiency and crafted trap placement.

---

## Phase 7 — Vehicles

Requested classes: cars, trucks, motorcycles, bicycles and skateboards.

---

## Phase 8 — Actor/NPC AI, combat, and causal outbreak

Scope includes infected/zombie AI, survivors/followers/raiders, melee/firearms, conversations, population/coarse distant behavior and the causal outbreak/collapse. AI receives observer knowledge, not hidden world truth.

---

## Phase 9 — Final graphics and UI overhaul -> Beta

Scope includes final control/layout audit, phone/Safari + desktop layouts, inventory/menu/icon consistency, interaction readability, world-art cleanup, shadows/lighting/weather/sound presentation, obsolete DEV UI removal, accessibility and final performance work.

**Completion of Phase 9 is the planned Beta start gate.**

---

## Non-numbered engineering gates

Insert when required without changing gameplay phase order: save/load orchestration, pre-Beta schema invalidation/migration policy, performance profiling before population-scale systems, evidence-driven persistence-backed streaming eviction and continued mobile/browser hard-pause/input regression coverage.

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

**Current next step: human-play verify Stage B physical power-network behavior plus current System-33 lighting/water/refrigeration behavior on `7ddee8df0e638cbe14897d83632b62513d5fc574`. Phase 4 begins by default only after that gate is accepted unless the user explicitly directs otherwise.**
