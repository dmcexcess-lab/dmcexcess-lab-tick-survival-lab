# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live Web build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## 2. Current architectural phase

**Systems 14–16 are now the live canonical demo/presentation path.** `game/main.tscn` launches the canonical playable demo with real HUD, stance control, Stats/Inventory inspectors and Menu/hard pause. `game/scripts/reboot/` remains frozen/deprecated recovery/reference code and must not be extended or used as a compatibility adapter.

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
- 15 Canonical HUD / Facing Inspection
- **16 Canonical Player Shell / Inspectors / Stance Integration**

Current designs:

- `SYSTEM_DESIGNS/14_CANONICAL_PLAYABLE_DEMO.md`
- `SYSTEM_DESIGNS/15_CANONICAL_HUD_FACING_INSPECTION.md`
- `SYSTEM_DESIGNS/16_CANONICAL_PLAYER_SHELL.md`

Dedicated workflows:

- `.github/workflows/canonical-demo.yml`
- `.github/workflows/canonical-hud.yml`
- `.github/workflows/canonical-player-shell.yml`

System 16 hardened code head `dce48115f35ef6487bcbe8811fe945d2e5012cff` passed dedicated run `31996425080` after one lifecycle-only hardening of touch-button initialization. All protected Locomotion/actor-status/Hands/Inventory/System14/System15 regressions were green.

## 3. Foundation / mechanic truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative persistent current world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic changes and deterministic snapshot/restore. Mechanic state attaches in typed stable-ID domains.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion

Collision owns hard occupancy. Movement owns forward/back/turn request -> time -> commit semantics. Actor Locomotion owns standing/crouched state and movement-capability composition.

System 03 owns real timed stance actions:

- crouch/stand base action = 4 ticks before existing modifiers;
- standing step baseline on demo terrain = 10 ticks;
- crouched step on that same terrain = 14 ticks;
- turn baseline = 3 ticks.

Running remains deferred until it has real downside.

### Physical item truth

- WHAT placement owns loose world location;
- 09 owns anatomical Right/Primary + Left/Secondary hands;
- 11 owns direct/nested containment;
- 12 owns timed transitions among world/hand/personal containment and derives disposition;
- 13D owns explicit item weight;
- 13E derives carried weight/capacity from real possession.

System 16 Inventory is read-only and does not become another possession truth.

## 4. Actor status truth

### 13A Health

100 HP baseline plus broad real injury records: type, body region, MINOR/SERIOUS/CRITICAL, stabilized/treated. HP zero does not itself implement corpse/death transition.

### 13B Needs

Independent integer 0..100 fatigue, hunger, thirst, sleep pressure. No implicit frame-time progression. Fatigue contributes to locomotion only through 03’s provider seam.

### 13C Skills

Combat, Scavenging, Survival, Medical, Technical, Social; catalog driven; levels 0..10 + XP; threshold `20 + level * 15` below max.

### 13D / 13E

Item weight is positive integer grams where explicitly classified. Missing weight is UNKNOWN, never zero. Carry persists capacity (default 18,000 g) but derives current weight from Hands + nested Containment + weights.

### 13F Moodlets

Derived only from real source state. No duplicate ordinary moodlet truth.

## 5. Canonical presentation

04 selects recovered environment/player/living-actor/held-item art. 05 Ground, 06 Structure, 07 Prop, 08 Living Actor and 10 Hand Equipment Presentation are independently implemented.

Current live renderer composition remains:

`Ground -> Structure -> Prop -> Living Actor`

The demo still has no real equipped items, so System 10 BACK/FRONT hand layers are not yet inserted into live composition. They are ready for the next item-interaction slice.

System 15 owns a separate CanvasLayer HUD. System 16 owns separate inspector/menu presentation. Neither becomes simulation truth.

## 6. Live canonical demo

Current live demo:

- authored 13x13 real WHAT map;
- grass + cross-road, small house shell, trees, bench, mailbox, streetlight;
- exactly one controlled `actor.survivor`; no NPCs/infected;
- player starts `(6,10)` facing NORTH;
- real Collision / Movement / Locomotion / WHEN;
- W/Up forward, S/Down backward, A/Left turn left, D/Right turn right;
- C = Crouch/Stand semantic toggle;
- native touch buttons for Forward, Back, Turn L, Turn R, Crouch/Stand;
- fixed one-screen view at 38 px/cell; no camera yet because the test area fits;
- System 15 HUD shows tick, facing, latest action, one-cell-ahead `Looking at:`, HP, fatigue, hunger, thirst, sleep pressure, carry and moodlets;
- System 16 top buttons: Stats, Inventory, Menu.

The old controls help line and second controls-owned tick/action label are gone. System 15 is the sole tick/action HUD surface.

## 7. System 16 player shell truth

### Stance

- semantic `STANCE_TOGGLE` only;
- controller reads canonical stance and calls existing `request_crouch` / `request_stand`;
- touch label derives from canonical stance: `CROUCH` while standing, `STAND` while crouched;
- no duplicate stance state.

### Stats

Read-only modal shows:

- stance;
- HP;
- fatigue/hunger/thirst/sleep pressure;
- carry current/capacity;
- moodlets;
- real injuries or `None`;
- all six real Skills with level and XP/next threshold.

The live demo survivor is explicitly enrolled in 13C, so boot Skills are honest level-0/XP-0 records. Traits/stress/temperature/etc. are not displayed because those systems do not exist.

### Inventory

Read-only modal shows:

- Right/Primary hand;
- Left/Secondary hand;
- actor-root contents;
- nested containment recursively;
- stable physical item IDs;
- known weight or explicit `Weight: Unknown`;
- real carry current/capacity.

The current itemless demo honestly says Empty and reports 0.0/18.0 kg. No starter gear was fabricated.

### Menu / hard pause

Stats, Inventory and Menu acquire WHEN hard application pause. The shell captures the pre-existing hard-pause state once per modal lifetime, keeps it while switching modals, and restores it exactly on final Close/Resume.

The full-screen overlay blocks pointer input and the shell explicitly disables keyboard/touch gameplay adapters while open.

Menu contains Resume + Leave Game. Web Leave Game tries browser history first and otherwise falls back to Google; native fallback quits normally.

## 8. Death / corpse direction

Approved direction remains: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Exact corpse representation/decay/disposal/rendering remain NOT DESIGNED. System 13/16 do not implement this transition.

## 9. Immediate path after System 16

Do **not** rebuild the existing renderers, player shell, actor-state domains or item-transfer rules.

Next useful bounded slice is the **real item interaction demo**:

1. put a few real stable WHAT `item.*` entities with explicit 13D weights into the authored map;
2. implement the missing loose-item renderer;
3. insert existing System 10 `BACK -> actor body -> FRONT` held-item layers into live composition;
4. expose real System 12 pickup/drop/equip/unequip through semantic touch/keyboard interaction UI;
5. refresh existing HUD/Inventory after committed transfers.

Door open/close interaction remains a separate later bounded system.

## 10. Other later systems

- Container Access / Search / Open / Lock — NOT DESIGNED
- Corpse / Decay / Contamination — NOT DESIGNED, direction approved
- Door interaction / physical transition — NOT DESIGNED
- Actor Appearance / character creator integration — NOT DESIGNED
- Loose-item renderer — NOT DESIGNED
- quantity/stack/durability/richer item properties — NOT DESIGNED
- first aid / health progression / sickness — NOT DESIGNED beyond 13A
- eating/drinking/rest/sleep progression — NOT DESIGNED beyond 13B
- global world generation / roads / parcels / buildings / rooms / dressing — NOT DESIGNED
- construction/destruction — DEFERRED
- vision/perception, lighting, weather, silent spatial sound — DEFERRED
- infected AI, combat, vehicles — DEFERRED
- old raid/extraction/session physical architecture — SUPERSEDED

## 11. Development invariants

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. No placeholder/fake completion.
4. Generator creates initial WHAT; it does not own reality.
5. Rendering presents truth; it does not become truth.
6. Input emits semantic intent; it does not implement mechanics.
7. Art is not physics.
8. Phone/Safari is first-class.
9. Do not wire canonical modules into deprecated Reboot through temporary adapters.
10. Persistent mechanic state uses typed stable-ID domains rather than a universal metadata bag.
11. Controlled-player role is not persistent actor identity.
12. Carry totals and moodlets are derived.
13. Needs/Carry affect locomotion only through 03’s provider contract.
14. HUD/inspectors are readers/composers; they do not mutate mechanic truth.
15. Hard application pause uses WHEN, not SceneTree pause.

## 12. Documentation source order

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

## 13. Recommended next action

Playtest the live System 16 shell on Safari/phone. Unless playtesting reveals a shell defect, design the bounded **real item interaction demo** next: loose item presentation + existing held-item layer composition + real System 12 pickup/drop/equip controls.
