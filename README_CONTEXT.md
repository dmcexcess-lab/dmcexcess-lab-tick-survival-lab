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
- **08 Player / Living Actor Renderer — DRAFT; active design review**

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

### Approved corpse direction

Corpses are persistent post-death world consequences, not living ACTOR render entries. Future Corpse / Decay / Contamination design should preserve the deceased identity relationship, corpse age/decay, and a simplified accumulated contamination/filth pressure that can create health/sickness consequences when bodies accumulate or remain too long. Exact representation, formula, disposal actions, and corpse channel are not yet designed.

## 4. Canonical presentation

### 04 Art Catalog — IMPLEMENTED

Recovered six atlas families + four player sprites, exact semantic precedence, themed openings, road topology, and typed UNKNOWN behavior. Art Catalog selects descriptors only.

### 05 Ground Layer Renderer — IMPLEMENTED

Standalone ground-only `Node2D`; visible WHAT terrain -> Art Catalog; local visible-window coordinates; event-driven redraw; recovered road/dirt-road/sidewalk topology; explicit diagnostics; no camera/generation/physics/input ownership.

### 06 Structure Layer Renderer — IMPLEMENTED

Visible WHAT `STRUCTURE` occupancy -> Art Catalog + Door State. Supports `wall.<theme>`, `door.<theme>`, `window.<theme>`, preserves H/V axis, uses distinct OPEN/CLOSED door art, and fails visibly for unknown state/content.

### 07 Prop / Fixture / Vegetation Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/07_PROP_FIXTURE_VEGETATION_RENDERER.md`.

Owners:

- `game/scripts/render/PropDrawCommand.gd`
- `game/scripts/render/PropLayerRenderer.gd`
- `game/scripts/ci/PropLayerRendererSmoke.gd`
- `.github/workflows/prop-renderer.yml`

Locked rules:

- reads WHAT `OBJECT` occupancy only + 04 Art Catalog;
- recognized families are `prop.*`, `fixture.*`, `vegetation.*`;
- all recovered art selection delegates to `ArtCatalog.resolve_prop()`;
- multi-cell occupancy deduplicates to one draw command per stable entity;
- command retains anchor, N/E/S/W facing, copied footprint, and rotated world cells;
- current recovered one-cell prop art draws once at the physical anchor;
- current prop art is not automatically rotated because golden `draw_prop()` defined no native-facing transform;
- overlapping OBJECT occupants draw deterministically rather than becoming renderer-owned collision errors;
- unknown family/art/selection/texture facts fail visibly;
- visible-window only, lazy texture cache, event-driven redraw, no `_process()` polling;
- no Collision/WHEN/Movement/Locomotion/Door State/generation/inventory/camera/input/reboot ownership.

Initial implementation head `5c2df6439678abaf8c9a031f5b6ed7bb8fb68a86` passed dedicated run `31983182247` with Art Catalog + Ground + Structure regressions and no production repair.

### 08 Player / Living Actor Renderer — ACTIVE DRAFT

Canonical draft: `SYSTEM_DESIGNS/08_PLAYER_LIVING_ACTOR_RENDERER.md`.

Settled boundary:

- renders living WHAT `ACTOR` entities only;
- includes the controlled survivor, non-player survivors/humans, and infected;
- controlled-player role is a stable-ID presentation/session role rather than a permanent `actor.player` world type;
- corpses are excluded and belong to the future Corpse / Decay / Contamination system.

Recovery discovery:

- protected Tick art already contains one real four-facing survivor variant;
- current same-owner First Fire tactical art contains 8 survivor variants × 4 facings and 8 infected variants × 4 facings, plus separate corpse/weapon art;
- 08 proposes extracting living actor art into a new narrow actor atlas without modifying protected Tick assets;
- corpse art remains reserved for the future corpse renderer/mechanic.

Still awaiting explicit approval with the detailed 08 draft: additive Art Catalog actor resolver, deterministic stable-ID default non-player variant selection, exact actor draw geometry, and the rule that 08 does not fake crouch art before authored stance visuals exist.

## 5. Graphics recovery status

Canonical graphics now include:

1. recovered multi-atlas semantic art selection;
2. actual Ground drawing;
3. actual wall/door/window Structure drawing with persistent Door State;
4. actual Prop/Fixture/Vegetation drawing from persistent OBJECT entities.

Living Actor rendering is now the active draft. Visible full-scene recovery remains incomplete until Actor plus composition/test-area and camera systems exist canonically.

The deployed Web page still intentionally runs the frozen reboot reference. Do not claim it demonstrates canonical 05/06/07/08 until the new presentation stack has an approved composition path.

## 6. Open-world/generation direction

Generation is not the engine and streaming partitions never define logical reality.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Cross-region facts are planned globally. Once world facts exist, persistent WHAT owns later mutations.

## 7. Development invariants

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
14. Render layers consume semantic world facts through 04 Art Catalog.
15. Camera/viewport owns visible-window calculation; focused renderers only consume it.
16. Door State owns door OPEN/CLOSED truth; Collision owns blocking truth; neither infers the other.
17. Physical WHAT footprints/facing remain world truth; presentation-specific large-object geometry/orientation must be explicit rather than inferred from physics.
18. Living ACTOR rendering and corpse persistence/decay are separate concerns; death must not be represented by leaving a dead body as an ordinary living ACTOR.

## 8. Documentation source order

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
11. golden history for recovered behavior.

## 9. Recommended next bounded step

**Review/approve `08_PLAYER_LIVING_ACTOR_RENDERER.md`.**

The draft covers player + non-player survivors + infected using real recovered same-owner art while keeping AI, combat, health, inventory, corpses, camera/input, and tactical composition outside the renderer.

Keep Corpse / Decay / Contamination, Authored Visual Test Area, Tactical composition, camera/zoom, touch/keyboard/Safari input, loose-item rendering, vehicles, stateful prop variants, and Door Interaction as separate approved systems.