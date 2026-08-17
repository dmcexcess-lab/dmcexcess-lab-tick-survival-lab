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
- **12 Item Transfer / Pickup / Drop / Equip Actions — DRAFT; direction approved, detailed contract awaiting explicit approval**

11 initial complete code head `1218c62cd04b3821991400918ffa43b29d621181` passed dedicated run `31988099341` with no production repair.

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

### 09 Actor Hand Equipment State

Canonical design: `SYSTEM_DESIGNS/09_ACTOR_HAND_EQUIPMENT_STATE.md`.

- explicit `actor.survivor` enrollment;
- primary = anatomical right hand; secondary = anatomical left;
- stable WHAT `item.*` assignments;
- one physical item cannot occupy multiple hands/actors inside 09;
- missing record differs from enrolled empty hands;
- versioned/copy-safe/deterministic snapshot state;
- no Inventory/Render/Combat/Lighting/WHEN/UI ownership.

### 11 Inventory / Containment

Canonical design: `SYSTEM_DESIGNS/11_INVENTORY_CONTAINMENT.md`.

- explicit container enrollment; no art/name/channel inference;
- stable direct relation `item_id -> direct_container_id`;
- only valid unplaced WHAT `item.*` children accepted by normal `set_container`;
- one direct parent maximum;
- nested item-containers supported;
- self/ancestry cycles rejected;
- reverse direct-contents index derived from canonical parent truth;
- sorted/copy-safe reads;
- global revision + direct-container versions;
- A -> B transfer changes one relation and increments both affected parent versions;
- moving a container item between parents does not alter its own direct-contents version;
- non-empty containers cannot be unenrolled;
- stale item/container state can be explicitly cleaned after WHAT deletion;
- deterministic atomic snapshot/restore;
- no capacity/weight/bulk/stack/quantity values;
- no import of 09, WHEN, render, UI, combat, locomotion, collision, generation, or reboot.

## 4. Physical item-disposition boundary

Current low-level owners intentionally remain separate:

- WHAT placement owns tactically placed/loose physical location;
- 09 owns explicit hand assignments;
- 11 owns direct containment.

These systems do not import each other merely to enforce final gameplay transitions.

Active DRAFT: `SYSTEM_DESIGNS/12_ITEM_TRANSFER_ACTIONS.md`.

12 proposes:

- a **read-only** cross-domain `ItemDispositionQuery` that derives loose-world / hand / contained / unclaimed / conflict status without becoming persistent truth;
- a timed coordinator using WHAT + 09 + 11 + WHEN public contracts;
- request -> validate -> spend time -> commit revalidation -> coordinated mutation;
- `CANCELABLE` transfer actions with no partial physical effect before final commit;
- no item/hand/container reservation; deterministic first valid commit wins races;
- personal-survivor v1 access only: floor items at the actor/one-cell-forward fringe, actor-root inventory, nested personal containers, and held item-containers;
- arbitrary cabinets/trunks/corpses/vehicle cargo deferred until real access/search/open/lock rules exist;
- normal drop at the actor's feet as one single-cell `LOOSE_ITEM` placement;
- explicit timing policy registration rather than invented pickup/drop/equip costs;
- exceptional compensation if a second low-level mutation unexpectedly fails after source removal.

The user's latest “approved” establishes 12 as the next system direction, but does not bypass review of these new detailed mechanics. Do not implement until the detailed DRAFT is explicitly approved.

## 5. Death / corpse direction

Approved cross-system direction: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Future corpse state preserves relation to deceased identity and supports age/decay; accumulated bodies may create local contamination/filth pressure that Health later interprets as sickness risk. Exact corpse representation, decay formula, disposal actions, and rendering are **NOT DESIGNED**.

## 6. Canonical presentation

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

- one focused renderer instantiated as `BACK` or `FRONT`;
- future composition: `10 BACK -> 08 actor body -> 10 FRONT`;
- primary remains anatomical right, secondary anatomical left;
- held art rotates N/E/S/W;
- NORTH/SOUTH both FRONT;
- EAST secondary/left BACK, primary/right FRONT;
- WEST primary/right BACK, secondary/left FRONT;
- no Inventory/Combat/Lighting/WHEN/UI/Input/Camera/Reboot ownership.

## 7. Canonical demo/UI target requested by the user

The next visible canonical demo must not be keyboard-only. Safari/iPhone is first-class.

Eventual target:

- touch Forward, Back, Turn Left, Turn Right and implemented stance/navigation actions;
- desktop keyboard equivalents;
- recovered-style `Looking at: ...` HUD;
- concise **real** actor stats;
- `STATS` button for detailed inspection;
- `INVENTORY` button for real containment/held-item inspection;
- `MENU` button invoking hard application pause;
- Stats/Inventory inspection also pauses safely;
- Menu includes Resume and Leave Game;
- no fabricated HP, stamina, carry weight, names, or inventory contents.

Web note: a webpage cannot reliably open the user's configured browser homepage. Future Leave Game should prefer useful browser-history return, with a safe fallback such as Google.

## 8. Dependency order from the latest request

Completed:

1. **09 Actor Hand Equipment State — IMPLEMENTED.**
2. **10 Actor Hand Equipment Presentation — IMPLEMENTED.**
3. **11 Inventory / Containment — IMPLEMENTED.**

Active design gate:

4. **12 Item Transfer / Pickup / Drop / Equip Actions — DRAFT.** Review/approve the detailed personal-access, reach/drop, timing, interruption, no-reservation and compensation rules before code.

Then remaining prerequisites toward the requested honest demo:

5. **Actor stat domains required for inspector — NOT DESIGNED.** Reuse implemented state where it exists; design Health/Needs only as needed rather than fabricate numbers.
6. **Authored Visual Test Area — NOT DESIGNED.** Real canonical WHAT fixture.
7. **Tactical Renderer / Orchestration — NOT DESIGNED.** Compose Ground/Structure/Prop/10-BACK/08/10-FRONT.
8. **Tactical Camera + Zoom — NOT DESIGNED.**
9. **Touch / Keyboard / Safari Input — NOT DESIGNED.**
10. **Tactical Controls UI — NOT DESIGNED.**
11. **HUD / Facing Inspection / Stats & Inventory Inspector / Pause Menu — NOT DESIGNED.**

Later slices may combine only when their explicit contracts prove they are genuinely one coherent owner.

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
16. Inventory containment must not become universal item disposition or item-stat ownership.
17. Cross-domain physical transitions get a dedicated coordinator instead of mutual imports among low-level state owners.
18. A derived item-disposition query may summarize WHAT/09/11 but must never become a fourth serialized item-location truth.

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

Review and explicitly approve or revise `SYSTEM_DESIGNS/12_ITEM_TRANSFER_ACTIONS.md`. Once approved, implement only the timed personal item-transfer coordinator + disposition query + timing policy + tests, leaving WHAT/WHEN/09/11 production unchanged.
