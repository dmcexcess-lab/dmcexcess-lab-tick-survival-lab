# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win over stale assumptions.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project is in staged modular replacement of the deprecated playable runtime.

`game/scripts/reboot/` is **frozen/deprecated reference code**. Do not extend it or add temporary adapters just to make canonical systems appear in the old playable build.

Golden recovery commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Golden mature `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

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
- **09 Actor Hand Equipment State — DRAFT**

## 3. Foundation and simulation truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic change notifications, and deterministic snapshot/restore. Rendering reads WHAT; it does not own it. Mechanic state such as door openness remains in typed stable-ID domains outside `WorldEntityRecord`.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion

Collision owns hard occupancy, not door state. Movement owns forward/back/turn target/commit semantics with no destination reservation and typed policy decisions. Actor Locomotion owns standing/crouched state, timed stance changes, and future mobility-provider composition. Running remains deferred until it has real consequences.

### Door State

06A owns persistent OPEN/CLOSED truth keyed by stable WHAT door ID. Missing state is UNKNOWN. Door State does not infer from or mutate Collision/WHEN.

### Death / corpse direction

Approved cross-system direction: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Future corpse state should preserve relation to deceased identity and support age/decay; accumulated bodies/decay may create local contamination/filth pressure that Health later interprets as sickness risk. Exact corpse representation, decay stages/formula, disposal actions and rendering are **NOT DESIGNED** yet.

## 4. Canonical presentation

### 04 Art Catalog — IMPLEMENTED

Recovered environmental multi-atlas selection plus four protected player textures remain intact. 08 additively recovered a separate same-owner living-actor atlas (`game/assets/actor_atlas.svg`) with 8 survivor variants × four facings and 8 infected variants × four facings. Original ten Tick baseline art assets remain byte-identical; the actor source is separately pinned/provenanced. Art Catalog selects descriptors only.

### 05 Ground Layer Renderer — IMPLEMENTED

Standalone ground-only `Node2D`; visible WHAT terrain -> Art Catalog; local visible-window coordinates; event-driven redraw; recovered road/dirt-road/sidewalk topology; explicit diagnostics; no camera/generation/physics/input ownership.

### 06 Structure Layer Renderer — IMPLEMENTED

Visible WHAT `STRUCTURE` occupancy -> Art Catalog + Door State. Supports `wall.<theme>`, `door.<theme>`, `window.<theme>`, preserves H/V axis, uses distinct OPEN/CLOSED door art, and fails visibly for unknown state/content.

### 07 Prop / Fixture / Vegetation Renderer — IMPLEMENTED

Reads WHAT `OBJECT` occupancy only + 04 Art Catalog. Recognizes `prop.*`, `fixture.*`, and `vegetation.*`; multi-cell occupancy deduplicates to one draw command per stable entity; current recovered one-cell art draws once at the anchor; overlap order is deterministic; no `_process()` polling.

### 08 Player / Living Actor Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/08_PLAYER_LIVING_ACTOR_RENDERER.md`.

Locked rules:

- reads visible WHAT `ACTOR` occupancy only + 04 Art Catalog;
- exact living semantic types are `actor.survivor` and `actor.infected`;
- controlled actor is a stable-ID presentation/session role, not a permanent WHAT player type;
- controlled survivor uses exact protected N/E/S/W `player_*.svg` textures;
- NPC survivors/infected use the separately recovered actor atlas;
- NPC default appearance uses deterministic 32-bit FNV-1a of stable actor ID modulo 8;
- no fake crouch visual;
- arbitrary ACTOR footprints deduplicate to one base actor draw;
- actual ACTOR-channel placement drives redraw relevance;
- no AI/Health/Inventory/Corpse/Collision/Movement/WHEN/generation/reboot/camera/input/UI ownership.

## 5. Active design — 09 Actor Hand Equipment State

Canonical DRAFT:

`SYSTEM_DESIGNS/09_ACTOR_HAND_EQUIPMENT_STATE.md`

The user requested visible primary/right-hand and secondary/left-hand items for the controlled survivor and survivor NPCs. The state prerequisite is intentionally separated from the renderer so held-item graphics never become inventory truth.

Current DRAFT direction:

- primary = anatomical right hand;
- secondary = anatomical left hand;
- persistent assignments reference stable WHAT `item.*` entities, not item-name strings;
- equipped items are normally tactically unplaced while held;
- one physical item cannot occupy multiple hands/actors simultaneously;
- missing hand-state record is not silently equivalent to empty hands;
- 09 owns no art, rendering, inventory containment, combat, lighting, WHEN, input or UI;
- future equip actions coordinate Inventory/Containment + 09 + WHEN rather than putting action rules in the store.

**Do not implement until the user explicitly approves the detailed 09 contract.**

## 6. Held-item presentation direction requested for the next design

After 09, design a separate **Actor Hand Equipment Presentation** owner.

Requested behavior:

- both held objects float beside the actor;
- recover same-owner First Fire weapon silhouettes and secondary utility icons before inventing new art;
- hand art rotates with N/E/S/W facing;
- north/south show both hands clearly;
- east/west use back-hand -> actor body -> front-hand draw ordering so the far-side object is naturally occluded by the body;
- primary/right and secondary/left never swap semantic meaning when the actor turns;
- presentation rotation/occlusion changes no physics or item state.

Requested E/W anatomical ordering from the approved grid orientation:

- EAST: primary/right is south/near/front; secondary/left is north/far/back;
- WEST: primary/right is north/far/back; secondary/left is south/near/front.

## 7. Canonical demo/UI target requested by the user

The next visible canonical demo should **not be keyboard-only**. Safari/iPhone is first-class and requires real UI controls.

Requested target:

- touch buttons for Forward, Back, Turn Left, Turn Right and implemented stance/navigation actions;
- keyboard equivalents retained on desktop;
- concise HUD with recovered-style `Looking at: ...` display;
- concise real actor stats;
- `STATS` button for detailed actor inspection;
- `INVENTORY` button for real inventory/held-item inspection;
- `MENU` button that invokes hard application pause;
- Stats/Inventory inspection also pauses safely while open;
- menu includes Resume and Leave Game.

Do not invent HP, stamina, carry weight, names, gear contents or other values merely to fill the HUD. UI consumes only canonical state that actually exists. Health/Needs/Inventory can expand the inspector later.

The old golden `MapPreview.gd` is a recovery source for the exact `Looking at:` concept and the prior pause menu; First Fire `FFInspector.gd` is a recovery source for touch-friendly scrollable survivor/inventory inspection patterns. Neither old runtime architecture should be restored.

Web note: a webpage cannot reliably open the user's configured browser homepage. Future Leave Game behavior should prefer browser-history return when useful, with a safe fallback such as Google.

## 8. Dependency order created by the latest request

The latest request spans multiple major owners, so it must be built in bounded slices:

1. **09 Actor Hand Equipment State** — DRAFT, first prerequisite.
2. Actor Hand Equipment Presentation — NOT DESIGNED.
3. Inventory / Containment and any actor-stat domains required for honest inspector data — NOT DESIGNED/DEFERRED.
4. Authored Visual Test Area — NOT DESIGNED.
5. Tactical renderer/orchestration — NOT DESIGNED.
6. Tactical camera + zoom — NOT DESIGNED.
7. Touch/keyboard/Safari input — NOT DESIGNED.
8. Tactical Controls UI — NOT DESIGNED.
9. HUD / Facing Inspection / Stats & Inventory Inspector / Pause Menu — NOT DESIGNED.

This order may be tightened later where contracts prove two pieces are genuinely one coherent slice, but none should be hidden inside a monolithic demo scene.

## 9. Open-world/generation direction

Generation is not the engine and streaming partitions never define logical reality.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Cross-region facts are planned globally. Once world facts exist, persistent WHAT owns later mutations.

## 10. Development invariants

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Key rules:

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
11. Persistent mechanic state uses typed stable-ID domain stores rather than a universal metadata bag.
12. Gameplay durations/order use WHEN while mechanic meanings remain external.
13. World/generator data never stores atlas indices or texture paths.
14. Camera/viewport owns visible-window calculation; focused renderers only consume it.
15. Controlled-player role is not persistent actor identity.
16. Corpses are persistent future world/mechanic consequences, not living ACTOR presentation state.
17. Hand equipment truth must remain separate from held-item presentation and future inventory containment.

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

Review **09 Actor Hand Equipment State**. If approved, implement and verify only that state prerequisite. Then design the held-item presentation layer with the requested rotation and E/W body-occlusion behavior.