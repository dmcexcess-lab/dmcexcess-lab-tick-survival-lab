# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`
Web preview/reference: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project is in staged modular replacement of the deprecated playable runtime. `game/scripts/reboot/` is **frozen/deprecated reference code**. Do not extend it or add temporary adapters merely to make canonical modules visible.

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Implemented + CI:
- 00A WHERE / Spatial Model
- 00B WHAT / Persistent World State
- 00C WHEN / Tick Action Pause
- 01 Collision / Spatial Query
- 02 Movement Actions
- 03 Actor Locomotion / Movement Capability
- 04 Recovered Multi-Atlas Art Catalog
- 05 Ground Renderer
- 06A Door State
- 06 Structure Renderer
- 07 Prop / Fixture / Vegetation Renderer
- 08 Player / Living Actor Renderer
- 09 Actor Hand Equipment State
- 10 Actor Hand Equipment Presentation
- 11 Inventory / Containment
- 12 Item Transfer / Pickup / Drop / Equip Actions
- **13A Health / Injury**
- **13B Needs / Rest**
- **13C Skills**
- **13D Item Physical Properties**
- **13E Carry / Encumbrance**
- **13F Moodlets / Status Derivation**

System 13 umbrella: `SYSTEM_DESIGNS/13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.
Dedicated workflow: `.github/workflows/actor-stats.yml`.
Initial complete code candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed Actor Stats Domains run `31992365565` with all child smokes plus WHAT/Locomotion/Hands/Inventory regressions and no production repair.

## 3. Foundation / mechanic truth

### WHERE
Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT
One authoritative persistent current world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic changes, deterministic snapshot/restore. Mechanic state attaches in typed stable-ID domains.

### WHEN
One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion
Collision owns hard occupancy. Movement owns forward/back/turn request -> time -> commit semantics. Actor Locomotion owns standing/crouched state and movement-capability composition. Running remains deferred until it has real downside.

### Door State
06A owns persistent OPEN/CLOSED truth. Missing is UNKNOWN. Door State does not infer from Collision or rendering.

### 09 / 11 / 12 physical item truth
- WHAT placement owns loose physical world location.
- 09 owns anatomical primary/right + secondary/left hand assignment.
- 11 owns direct containment and nested acyclic container structure.
- 12 owns timed transitions among world/hand/personal containment and derives disposition; it is not a fourth serialized location truth.

## 4. System 13 actor status truth

### 13A Health / Injury
- stable survivor-ID enrollment;
- default/max v1 HP 100;
- broad injury type + body region + MINOR/SERIOUS/CRITICAL + stabilized/treated;
- multiple injuries supported;
- HP zero does not itself implement death/corpse transition;
- explicit mutation only; no hidden healing clock.

### 13B Needs / Rest
- independent integer 0..100 fatigue, hunger, thirst, sleep-pressure scales;
- fatigue = short-horizon exertion, sleep pressure = longer-horizon debt;
- no `_process()` progression or guessed calendar rate;
- read-only 03 provider recovers +0..65% locomotion duration from fatigue.

### 13C Skills
- Combat, Scavenging, Survival, Medical, Technical, Social;
- catalog-driven rather than fixed actor fields;
- levels 0..10 + persistent XP;
- threshold `20 + level * 15`;
- level 10 stores 0 XP;
- base progression only, temporary modifiers outside.

### 13D Item Physical Properties
- explicit semantic `item.*` profiles;
- positive integer weight in grams;
- no guessed built-in weights;
- missing weight => UNKNOWN, never zero.

### 13E Carry / Encumbrance
- persistent base capacity only, recovered default 18,000 g;
- current weight derived from 09 Hands + 11 actor/nested/held-container contents + 13D weights;
- stable IDs deduplicate physical items;
- missing one weight makes the total UNKNOWN;
- over-capacity is representable and does not silently rewrite 12 transfer rules;
- read-only 03 provider recovers +75% duration at exactly capacity and scales beyond.

### 13F Moodlets
Derived only from real source state. V1 includes Well Rested, Tired/Exhausted, Hungry/Starving, Thirsty/Dehydrated, Sleepy/Sleep Deprived, Injured/Badly Injured/No Vitality, Heavy Load/Overburdened. Only the strongest moodlet in each category appears. Missing source truth fails explicitly.

## 5. Death / corpse direction

Approved cross-system direction remains: death leaves persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Future corpse state preserves relation to deceased identity and supports age/decay/contamination pressure. Exact representation, decay formula, disposal actions, and rendering are **NOT DESIGNED**. 13A HP zero and 13F No Vitality do not implement that transition.

## 6. Canonical presentation

04 selects recovered environment/player/living-actor/held-item art. 05 Ground, 06 Structure, 07 Prop, 08 Living Actor, and 10 Hand Equipment Presentation are independently implemented. Future composition is `Ground -> Structure/Props as designed -> 10 BACK -> 08 body -> 10 FRONT` with exact z-order decided by Tactical Renderer design.

## 7. Requested canonical demo target

The user wants to reach the real playable canonical demo quickly. It must not be keyboard-only. Safari/iPhone is first-class.

Target:
- touch Forward, Back, Turn Left, Turn Right and implemented stance/navigation actions;
- desktop keyboard equivalents;
- recovered-style `Looking at: ...` HUD;
- concise **real** actor status from System 13;
- `STATS` inspector displaying real HP/needs/skills/carry/moodlets;
- `INVENTORY` using real 09/11/12 item truth;
- `MENU` invoking hard application pause;
- Stats/Inventory inspection pauses safely;
- Resume + Leave Game;
- no fabricated names/items/stats.

## 8. Immediate dependency path to demo

Actor/data prerequisites are now complete through System 13. Recommended next bounded path:
1. **Authored Visual Test Area — NOT DESIGNED.** Construct real canonical WHAT + 09/11/13 fixture; no fake generator.
2. **Tactical Renderer / Orchestration — NOT DESIGNED.** Compose existing render layers.
3. **Tactical Camera + Zoom — NOT DESIGNED.**
4. **Touch / Keyboard / Safari Input — NOT DESIGNED.**
5. **Tactical Controls UI — NOT DESIGNED.**
6. **HUD / Facing Inspection / Stats & Inventory Inspector / Pause Menu — NOT DESIGNED.**

Favor the smallest real composition path. Do not reopen completed mechanics merely to make the demo visible.

## 9. Other later systems
- Container Access / Search / Open / Lock — NOT DESIGNED
- Corpse / Decay / Contamination — NOT DESIGNED, direction approved
- Door interaction / physical transition — NOT DESIGNED
- Actor Appearance / character creator integration — NOT DESIGNED
- Loose-item renderer — NOT DESIGNED
- richer item quantity/condition/bulk — NOT DESIGNED
- first aid / health progression / sickness — NOT DESIGNED beyond 13A state
- eating/drinking/rest/sleep progression — NOT DESIGNED beyond 13B state
- global world generation / roads / parcels / buildings / rooms / dressing — NOT DESIGNED
- construction/destruction — DEFERRED
- vision/perception, lighting, weather, silent spatial sound — DEFERRED
- infected AI, combat, vehicles — DEFERRED
- old raid/extraction/session physical architecture — SUPERSEDED

## 10. Development invariants
1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. No placeholder/fake completion.
4. Generator creates initial WHAT; it does not own reality.
5. Rendering presents truth; it does not become truth.
6. Input emits semantic intent; it does not implement mechanics.
7. Art is not physics.
8. Phone/Safari is first-class.
9. Do not wire canonical modules into deprecated reboot through temporary adapters.
10. Persistent mechanic state uses typed stable-ID domains rather than a universal metadata bag.
11. Controlled-player role is not persistent actor identity.
12. Carry totals and moodlets are derived; do not persist duplicate truth.
13. Needs/Carry affect locomotion only through 03's provider contract.

## 11. Documentation source order
1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED system designs;
9. DRAFT designs;
10. compatible master-design material;
11. golden/same-owner history.

## 12. Recommended next action
Design the **Authored Visual Test Area** as the first real composition/demo fixture now that canonical actor/item/stat truth exists. Then move directly through renderer composition, camera, input, controls, and inspector/menu rather than inventing more simulation prerequisites.
