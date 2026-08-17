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

## 3. Foundation / mechanic truth

### WHERE
Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT
One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic change notifications, and deterministic snapshot/restore. Persistent mechanic state attaches in typed domains keyed by the same stable IDs.

### WHEN
One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion
Collision owns hard occupancy. Movement owns forward/back/turn request -> time -> commit semantics. Actor Locomotion owns standing/crouched state and movement-capability composition. Running remains deferred until it has real costs.

### Door State
06A owns persistent OPEN/CLOSED truth keyed by stable WHAT door ID. Missing state is UNKNOWN. Door State does not infer from or mutate Collision/WHEN.

### Actor Hand Equipment State
Canonical design: `SYSTEM_DESIGNS/09_ACTOR_HAND_EQUIPMENT_STATE.md`.

Locked implemented rules:

- explicit `actor.survivor` enrollment;
- `PRIMARY_RIGHT` = anatomical right hand;
- `SECONDARY_LEFT` = anatomical left hand;
- assignments reference stable WHAT `item.*` entities, not item-name strings;
- held items must be tactically unplaced when newly assigned;
- one physical item cannot occupy two hands or two actors simultaneously;
- missing hand-state record is distinct from enrolled empty hands;
- copy-safe reads, reverse assignment lookup, global revision, per-actor versions;
- deterministic schema-versioned atomic snapshot/restore;
- explicit lifecycle cleanup after WHAT removal;
- no Art/Render/Inventory/Combat/Health/WHEN/AI/Input/UI/Reboot ownership.

Implementation code head `c108083744f474c80b06f8dc02673b60f1dca7cd` passed dedicated Actor Hand Equipment run `31986162867` with no production repair.

## 4. Death / corpse direction

Approved cross-system direction: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Future corpse state preserves relation to deceased identity and supports age/decay; accumulated bodies may create local contamination/filth pressure that Health later interprets as sickness risk. Exact corpse representation, decay formula, disposal actions, and rendering are **NOT DESIGNED**.

## 5. Canonical presentation

### 04 Art Catalog
Recovered environmental multi-atlas selection plus protected player textures and a separately recovered living-actor atlas. Art Catalog selects descriptors only.

### 05 Ground
Visible WHAT terrain -> Art Catalog; event-driven visible-window rendering.

### 06 Structure
Visible WHAT STRUCTURE occupancy -> Art Catalog + Door State; walls/doors/windows only.

### 07 Prop / Fixture / Vegetation
Visible WHAT OBJECT occupancy for `prop.*`, `fixture.*`, `vegetation.*`; one visual per stable entity.

### 08 Player / Living Actor
Visible WHAT ACTOR entities for `actor.survivor` and `actor.infected`. Controlled status is stable-ID presentation/session state; NPC survivor/infected art is real recovered same-owner artwork. Corpses are outside 08.

## 6. Active next design — Actor Hand Equipment Presentation

This is now the recommended next bounded design.

It should read:

- visible living ACTOR placement/facing from WHAT / 08-compatible geometry;
- 09 primary/right + secondary/left stable item IDs;
- item semantic types from WHAT;
- recovered held-item art through an additive Art Catalog contract.

Requested presentation behavior:

- both held objects float beside the actor;
- recover same-owner First Fire weapon silhouettes and utility icons before inventing new art;
- hand art rotates with N/E/S/W facing;
- north/south show both hands clearly;
- east/west use **back hand -> actor body -> front hand** ordering so the far object is naturally occluded;
- primary/right and secondary/left never swap semantic meaning when facing changes;
- EAST: secondary/left is far/back; primary/right is near/front;
- WEST: primary/right is far/back; secondary/left is near/front;
- presentation changes no physics or item state.

## 7. Canonical demo/UI target requested by the user

The next visible canonical demo must not be keyboard-only. Safari/iPhone is first-class.

Requested eventual target:

- real touch buttons for Forward, Back, Turn Left, Turn Right and implemented stance/navigation actions;
- keyboard equivalents retained on desktop;
- concise HUD with recovered-style `Looking at: ...` display;
- concise **real** actor stats;
- `STATS` button for detailed actor inspection;
- `INVENTORY` button for real inventory/held-item inspection;
- `MENU` button invoking hard application pause;
- Stats/Inventory inspection also pauses safely;
- Menu includes Resume and Leave Game;
- no fabricated HP, stamina, carry weight, names, or inventory contents merely to fill UI.

Web note: a webpage cannot reliably open the user's configured browser homepage. Future Leave Game should prefer useful browser-history return, with a safe fallback such as Google.

## 8. Dependency order from the latest request

1. **09 Actor Hand Equipment State — IMPLEMENTED.**
2. **Actor Hand Equipment Presentation — NEXT DESIGN.**
3. Inventory / Containment and any actor-stat domains required for honest inspector data — NOT DESIGNED / DEFERRED.
4. Authored Visual Test Area — NOT DESIGNED.
5. Tactical renderer/orchestration — NOT DESIGNED.
6. Tactical camera + zoom — NOT DESIGNED.
7. Touch/keyboard/Safari input — NOT DESIGNED.
8. Tactical Controls UI — NOT DESIGNED.
9. HUD / Facing Inspection / Stats & Inventory Inspector / Pause Menu — NOT DESIGNED.

Later slices may combine only if their approved contracts prove they are truly one coherent owner. Do not hide them inside a monolithic demo scene.

## 9. Open-world / generation direction

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
11. Persistent mechanic state uses typed stable-ID domains rather than a universal metadata bag.
12. Gameplay durations/order use WHEN while mechanic meanings remain external.
13. Controlled-player role is not persistent actor identity.
14. Corpses are persistent future world/mechanic consequences, not living ACTOR presentation state.
15. Hand equipment truth is separate from held-item presentation and Inventory/Containment.

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

Design **Actor Hand Equipment Presentation** with recovered weapon/utility art, N/E/S/W rotation, and the requested east/west body occlusion. Do not code it until that detailed design is approved.
