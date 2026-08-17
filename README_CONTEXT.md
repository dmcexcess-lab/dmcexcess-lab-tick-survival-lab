# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project is in staged modular replacement of the deprecated playable runtime.

`game/scripts/reboot/` is **frozen/deprecated reference code**. Do not extend it or add temporary adapters merely to make canonical modules visible in that old build.

Golden recovery commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Canonical progress:

- **00A WHERE / Spatial Model — IMPLEMENTED + CI**
- **00B WHAT / Persistent World State — IMPLEMENTED + CI**
- **00C WHEN / Tick Action Pause — IMPLEMENTED + CI**
- **01 Collision / Spatial Query — IMPLEMENTED + CI**
- **02 Movement Actions — IMPLEMENTED + CI**
- **03 Actor Locomotion State & Movement Capability — IMPLEMENTED + CI**
- **04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED + CI**
- **05 Ground Layer Renderer — IMPLEMENTED + CI**
- **06A Door State — IMPLEMENTED + CI**
- **06 Structure Layer Renderer — IMPLEMENTED + CI**
- **07 Prop / Fixture / Vegetation Renderer — IMPLEMENTED + CI**
- **08 Player / Living Actor Renderer — IMPLEMENTED + CI**
- **09 Actor Hand Equipment State — IMPLEMENTED + CI**
- **10 Actor Hand Equipment Presentation — IMPLEMENTED + CI**
- **11 Inventory / Containment — IMPLEMENTED + CI**
- **12 Item Transfer / Pickup / Drop / Equip Actions — IMPLEMENTED + CI**
- **13 Actor Stats / Status Architecture — APPROVED umbrella**
- **13C Actor Skills — DRAFT; awaiting detailed approval**

12 initial implementation head `7ea53e0d300fb0d7aad2802b11d4da930b802a49` preserved all neighboring regressions but its new smoke exposed a real reentrant destination-change edge case. Hardened head `c3139466c26cbb8367b4509f107a48916a323916` revalidated destination truth immediately before the second cross-domain mutation and passed dedicated run `31990020356`.

## 3. Foundation / mechanic truth

### WHERE
Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT
One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic changes, and deterministic snapshot/restore. Persistent mechanic state attaches in typed domains keyed by the same stable IDs.

### WHEN
One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion
Collision owns hard occupancy. Movement owns forward/back/turn request -> time -> commit semantics. Actor Locomotion owns standing/crouched state and movement-capability composition. Running remains deferred until it has real costs.

### Door State
06A owns persistent OPEN/CLOSED truth keyed by stable WHAT door ID. Missing state is UNKNOWN. Door State does not infer from or mutate Collision/WHEN.

### 09 Actor Hand Equipment

Canonical design: `SYSTEM_DESIGNS/09_ACTOR_HAND_EQUIPMENT_STATE.md`.

- explicit `actor.survivor` enrollment;
- primary = anatomical right hand; secondary = anatomical left;
- stable WHAT `item.*` assignments;
- one physical item cannot occupy multiple 09 hand assignments;
- missing record differs from enrolled empty hands;
- versioned/copy-safe/deterministic snapshot state;
- no Inventory/Render/Combat/Lighting/WHEN/UI ownership.

### 11 Inventory / Containment

Canonical design: `SYSTEM_DESIGNS/11_INVENTORY_CONTAINMENT.md`.

- explicit container enrollment; no art/name/channel inference;
- stable direct relation `item_id -> direct_container_id`;
- normal containment accepts only valid unplaced WHAT `item.*` children;
- one direct parent maximum;
- nested item-containers supported;
- self/ancestry cycles rejected;
- direct-container versions + global revision;
- non-empty containers cannot be unenrolled;
- no capacity/weight/bulk/stack/quantity values;
- no import of 09, WHEN, render, UI, combat, locomotion, collision, generation, or reboot.

### 12 Item Transfer Actions

Canonical design: `SYSTEM_DESIGNS/12_ITEM_TRANSFER_ACTIONS.md`.

The low-level item truths remain separate:

- WHAT placement owns loose physical world location;
- 09 owns anatomical hand assignment;
- 11 owns direct containment;
- **12 owns timed transitions between those truths.**

12 adds a read-only `ItemDispositionQuery` that derives `LOOSE_WORLD`, `HAND`, `CONTAINED`, `UNCLAIMED`, `INVALID_PLACEMENT`, `CONFLICT`, or `UNKNOWN`. It is never serialized as a fourth item-location truth.

V1 supports:

- floor -> personal container;
- floor -> hand;
- personal container -> floor;
- hand -> floor;
- personal container -> hand;
- hand -> personal container;
- personal container -> personal container.

Rules:

- pickup reach = actor footprint + one-cell-forward fringe;
- normal drop = one single-cell `LOOSE_ITEM` at actor anchor;
- actor-root, nested personal containers, held item-containers, and containers nested under held item-containers are accessible;
- arbitrary cabinets/trunks/corpses/vehicles are inaccessible until real access/search/open/lock rules exist;
- occupied target hand does not auto-swap;
- timing is explicit policy data; no pickup/drop/equip defaults were invented;
- actions are `CANCELABLE` until final `item_transfer.commit`;
- no item/hand/container reservation exists;
- pending expectations live only in WHEN payload;
- commit revalidates actor placement/facing, exact source, hand/container versions, personal access, destination state, and policy;
- cross-domain writes are synchronous, but low-level WHAT/09/11 signals remain independent;
- destination truth is rechecked **again after source removal** before the second mutation to defend against reentrant callbacks;
- unexpected second-write failure compensates through public APIs; compensation failure is an explicit critical consistency diagnostic.

WHAT, WHEN, 09, and 11 production/public APIs remained unchanged during 12 implementation.

### 13 Actor Stats / Status Architecture

Canonical umbrella: `SYSTEM_DESIGNS/13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

The user explicitly wants the character display to contain:

- moodlets;
- HP;
- fatigue;
- hunger;
- thirst;
- sleep;
- carry weight;
- skills and their levels.

The user explicitly approved keeping these modular so more domains can be added later.

Locked umbrella ownership:

- **13A Health / Injury** owns HP + future injury-capable health truth;
- **13B Needs / Rest** owns fatigue, hunger, thirst, sleep pressure;
- **13C Skills** owns persistent skill levels/XP;
- **13D Item Physical Properties** owns real item weight and later genuinely shared physical item facts;
- **13E Carry / Encumbrance** derives carried weight/capacity/consequence from physical possession + item weights and later modifiers;
- **13F Moodlets** derives readable status from real source domains rather than duplicating their state.

There is no universal `ActorStats` dictionary. The future Stats/HUD layer is a reader/composer and must be extensible by provider/adapters rather than owning mechanics.

Important semantic distinction approved at umbrella level:

- **fatigue** = short-horizon exertion/physical tiredness;
- **sleep** = longer-horizon sleep pressure/debt.

Carry weight is not a persisted duplicate total. It is derived from actual physical possession through existing item truth plus 13D weight.

### 13C Actor Skills — active DRAFT

Canonical draft: `SYSTEM_DESIGNS/13C_ACTOR_SKILLS.md`.

Same-owner First Fire recovery proves a strong candidate vocabulary/progression:

- Combat;
- Scavenging;
- Survival;
- Medical;
- Technical;
- Social;
- persistent XP;
- levels/ranks up to 10;
- next-level XP threshold `20 + current_level * 15`.

Those details are **not implemented and not yet approved as the child contract**. The user approved the modular umbrella only. Explicit approval of 13C is required before code.

## 4. Death / corpse direction

Approved cross-system direction: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Future corpse state preserves relation to deceased identity and supports age/decay; accumulated bodies may create local contamination/filth pressure that Health later interprets as sickness risk. Exact corpse representation, decay formula, disposal actions, and rendering are **NOT DESIGNED**.

## 5. Canonical presentation

### 04 Art Catalog
Recovered environmental multi-atlas selection plus protected player textures, separate recovered living-actor atlas, and separate recovered held-item atlas. Art Catalog selects presentation descriptors/metadata only.

Recovered extra assets:

- `game/assets/actor_atlas.svg` — 8 survivor variants × four facings + 8 infected variants × four facings;
- `game/assets/held_item_atlas.svg` — knife/club/hammer/spear/crowbar/hatchet/pistol/shotgun + flashlight/headlamp/lantern/glow-stick/road-flare art.

Original ten Tick baseline assets remain byte-identical.

### 05 Ground
Visible WHAT terrain -> Art Catalog; event-driven visible-window rendering.

### 06 Structure
Visible WHAT STRUCTURE occupancy -> Art Catalog + Door State; walls/doors/windows only.

### 07 Prop / Fixture / Vegetation
Visible WHAT OBJECT occupancy for `prop.*`, `fixture.*`, `vegetation.*`; one visual per stable entity.

### 08 Player / Living Actor
Visible WHAT ACTOR entities for `actor.survivor` and `actor.infected`. Controlled status is stable-ID presentation/session state. Corpses remain outside 08.

### 10 Actor Hand Equipment Presentation

Canonical design: `SYSTEM_DESIGNS/10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md`.

Future composition is `10 BACK -> 08 actor body -> 10 FRONT`.

- primary = anatomical right;
- secondary = anatomical left;
- held art rotates N/E/S/W;
- NORTH/SOUTH: both FRONT;
- EAST: secondary/left BACK, primary/right FRONT;
- WEST: primary/right BACK, secondary/left FRONT.

## 6. Canonical demo/UI target requested by the user

The eventual canonical demo must not be keyboard-only. Safari/iPhone is first-class.

Target:

- touch Forward, Back, Turn Left, Turn Right and implemented stance/navigation actions;
- desktop keyboard equivalents;
- recovered-style `Looking at: ...` HUD;
- concise **real** actor stats;
- `STATS` button for detailed inspection;
- `INVENTORY` button using real 09/11/12 item truth;
- `MENU` button invoking hard application pause;
- Stats/Inventory inspection also pauses safely;
- Menu includes Resume and Leave Game;
- no fabricated HP, stamina, carry weight, names, or inventory contents.

Stats target is explicitly moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, and skills/levels. UI must compose those from real modular domains rather than a giant actor record.

Web note: a webpage cannot reliably open the user's configured browser homepage. Future Leave Game should prefer useful browser-history return, with a safe fallback such as Google.

## 7. Dependency order toward the requested honest demo

Completed:

1. **09 Actor Hand Equipment State — IMPLEMENTED.**
2. **10 Actor Hand Equipment Presentation — IMPLEMENTED.**
3. **11 Inventory / Containment — IMPLEMENTED.**
4. **12 Item Transfer Actions — IMPLEMENTED.**
5. **13 Actor Stats / Status Architecture — APPROVED umbrella.**

Active detailed design gate:

6. **13C Actor Skills — DRAFT.** Recommended first child because same-owner recovery is strongest and it is independent of Health/Needs/Carry. Review/approve the six-skill 0–10 XP contract before code.

Then recommended stat children:

7. **13B Needs / Rest — NOT DESIGNED.** Fatigue/hunger/thirst/sleep.
8. **13A Health / Injury — NOT DESIGNED.** HP + injury-capable state.
9. **13D Item Physical Properties — NOT DESIGNED.** Real item weight.
10. **13E Carry / Encumbrance — NOT DESIGNED.** Derived weight/capacity/consequence.
11. **13F Moodlets — NOT DESIGNED.** Derived readable conditions.

Then:

12. **Authored Visual Test Area — NOT DESIGNED.** Real canonical WHAT fixture.
13. **Tactical Renderer / Orchestration — NOT DESIGNED.** Compose Ground/Structure/Prop/10-BACK/08/10-FRONT.
14. **Tactical Camera + Zoom — NOT DESIGNED.**
15. **Touch / Keyboard / Safari Input — NOT DESIGNED.**
16. **Tactical Controls UI — NOT DESIGNED.**
17. **HUD / Facing Inspection / Stats & Inventory Inspector / Pause Menu — NOT DESIGNED.**

Later slices may combine only when their explicit contracts prove they are genuinely one coherent owner.

## 8. Other later modular systems

- **Container Access / Search / Open / Lock — NOT DESIGNED.** Extends 12 to world storage.
- **Corpse / Decay / Contamination — NOT DESIGNED.** Approved direction only.
- **Door interaction / physical transition — NOT DESIGNED.** WHEN + Door State + Collision coordination.
- **Actor Appearance / character creator integration — NOT DESIGNED.**
- **Loose-item renderer — NOT DESIGNED.**
- **Item definitions / quantity / condition beyond 13D weight — NOT DESIGNED.**
- **Road network/topology — NOT DESIGNED.**
- **Property/parcel planner — NOT DESIGNED.**
- **Building/prefab placement — NOT DESIGNED.**
- **Procedural room/layout — NOT DESIGNED.**
- **Furniture/fixture/clutter dressing — NOT DESIGNED.**
- **Vegetation/utilities/civic dressing — NOT DESIGNED.**
- **World/generator validation — NOT DESIGNED.**
- **Prefab authoring tools — NOT DESIGNED.**
- **Construction/destruction — DEFERRED.**
- **Base/community summary — NOT DESIGNED.**
- **Vision/perception — DEFERRED.**
- **Lighting — DEFERRED.**
- **Weather — DEFERRED.**
- **Silent spatial sound — DEFERRED.**
- **Infected AI — DEFERRED.**
- **Combat — DEFERRED.**
- **Vehicles — DEFERRED.**
- **Old raid/extraction/session architecture — SUPERSEDED.**

## 9. Open-world / generation direction

Generation is not the engine and streaming partitions never define logical reality.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Cross-region facts are planned globally. Once world facts exist, persistent WHAT owns later mutations.

## 10. Development invariants

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. One major system per implementation slice by default.
4. No placeholder/fake completion.
5. Generator creates initial WHAT; it does not own persistent reality.
6. Rendering presents world truth; it does not become simulation truth.
7. Input emits semantic intent; it does not implement mechanics.
8. Art is not physics.
9. Phone/Safari is first-class.
10. Do not wire canonical modules into deprecated reboot through temporary adapters.
11. Persistent mechanic state uses typed stable-ID domains rather than a universal metadata bag.
12. Gameplay durations/order use WHEN while mechanic meanings remain external.
13. Controlled-player role is not persistent actor identity.
14. Corpses are persistent future world/mechanic consequences, not living ACTOR presentation state.
15. Hand equipment truth remains separate from held-item presentation and Inventory/Containment.
16. Inventory containment is not universal item disposition or item-stat ownership.
17. Cross-domain physical transitions use 12 rather than mutual imports among low-level state owners.
18. `ItemDispositionQuery` may summarize WHAT/09/11 but is never a fourth serialized truth.
19. A synchronous cross-domain coordinator must account for reentrant low-level signals: revalidate destination truth immediately before its second mutation and compensate explicitly if the second write fails.
20. Actor condition/stat truth is composed from typed peer domains; do not introduce a universal ActorStats/character metadata dictionary.
21. Moodlets primarily derive presentation/status from owning domains rather than duplicating canonical numeric state.
22. Carry weight derives from real physical possession plus item weight; it is not a second inventory total.
23. Stats/HUD presentation reads/composes module contracts and does not own or directly mutate actor mechanics.

## 11. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED `SYSTEM_DESIGNS/*.md`;
9. current DRAFT designs;
10. compatible master-design material;
11. golden/same-owner history for recovered behavior.

## 12. Recommended next action

Review and explicitly approve or revise `SYSTEM_DESIGNS/13C_ACTOR_SKILLS.md`. Once approved, implement only Actor Skills as the first bounded child of the approved 13 umbrella. Do not implement Needs/Health/Weight/Carry/Moodlets in the same slice.
