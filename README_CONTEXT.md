# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`
Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

**Systems 14–15 are now the live canonical entry/presentation path.** `game/main.tscn` launches the canonical playable demo with the real status HUD; `game/scripts/reboot/` remains frozen/deprecated recovery/reference code and must not be extended or used as a compatibility adapter.

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
- 13A Health / Injury
- 13B Needs / Rest
- 13C Skills
- 13D Item Physical Properties
- 13E Carry / Encumbrance
- 13F Moodlets / Status Derivation
- 14 Canonical Playable Demo Integration
- **15 Canonical HUD / Facing Inspection**

System 13 umbrella: `SYSTEM_DESIGNS/13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.
System 14 design: `SYSTEM_DESIGNS/14_CANONICAL_PLAYABLE_DEMO.md`.
System 15 design: `SYSTEM_DESIGNS/15_CANONICAL_HUD_FACING_INSPECTION.md`.
Dedicated demo workflow: `.github/workflows/canonical-demo.yml`.
Dedicated HUD workflow: `.github/workflows/canonical-hud.yml`.
System 15 hardened code head `fb19c7b86569c388dcb251b2b61210e745f3909a` passed Canonical HUD Facing Inspection run `31994628336`; the only earlier failure was a CI boundary regex matching an explanatory comment, not production code.

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

04 selects recovered environment/player/living-actor/held-item art. 05 Ground, 06 Structure, 07 Prop, 08 Living Actor, and 10 Hand Equipment Presentation are independently implemented.

System 14 currently composes the visible walking-demo stack as:

`Ground -> Structure -> Prop -> Living Actor`

The demo actor has no held items, so System 10 BACK/FRONT layers are intentionally not instantiated yet. They remain ready to insert around the actor body when demo item equipment is added.

System 15 adds a separate CanvasLayer HUD and read-only query owners. It does not change renderer ownership or simulation truth.

## 7. Live canonical demo

Current live demo:
- real authored 13x13 WHAT map, fully terrain-populated;
- grass + cross-road, small house shell, trees, bench, mailbox, streetlight;
- exactly one controlled `actor.survivor`; no NPCs/infected;
- player starts `(6,10)` facing NORTH;
- real Collision coverage for every placed actor/structure/object;
- real Movement + Locomotion + WHEN actions;
- recovered 10-tick walking baseline and existing 3-tick turn baseline;
- W/Up forward, S/Down backward, A/Left turn left, D/Right turn right;
- native Godot touch buttons emit the same semantic intents for Safari/iPhone;
- fixed one-screen view at 38 px/cell; no camera because the whole test area fits;
- real HUD shows tick, facing, action result, one-cell-ahead `Looking at:`, HP, fatigue, hunger, thirst, sleep pressure, carry, and derived moodlets.

The live demo survivor is now honestly enrolled in canonical Health, Needs, Hands, actor-root Inventory, Carry, and Moodlet state. At boot this means **100/100 HP, all need pressures 0, carry 0.0/18.0 kg, Well Rested**. These are domain defaults/derived facts, not UI placeholders.

`Looking at:` is currently a direct physical WHAT inspection of the cell in front. It is deliberately **not perception-aware**. Future LOS/vision/darkness logic may filter that information before presentation.

## 8. Immediate path after HUD

Do **not** rebuild the already-proven renderers, actor-state domains, or HUD queries.

When requested, extend the live canonical demo directly with bounded additions such as:
1. crouch/stand control plus `STATS`, `INVENTORY`, and `MENU`/hard-pause UI;
2. demo items/loose-item presentation, System 10 BACK/body/FRONT composition, and real 09/11/12 pickup/drop/equip;
3. door open/close interaction;
4. camera/zoom only once a larger world actually exceeds the one-screen authored view;
5. larger authored/generated content behind the same canonical contracts.

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
14. Reboot remains recoverable reference code, but live composition belongs to canonical owners.
15. HUD/inspection presentation reads typed truth and does not become perception or simulation ownership.

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
Playtest the live **System 15 HUD build** on phone/Safari. The next useful integration slice is likely crouch/stand plus the real `STATS`, `INVENTORY`, and `MENU` shell, unless playtesting exposes a more immediate HUD/control defect.