# Tick Survival Lab — 08 Player / Living Actor Renderer

Status: **IMPLEMENTED — canonical living-ACTOR renderer and dedicated Godot CI contract present 2026-08-16**

Approval basis: after 07 Prop / Fixture / Vegetation Renderer was implemented, the user confirmed that the next actor presentation layer should include non-player actors, approved the rule that corpses are persistent post-death world problems rather than living ACTOR render entries, and then explicitly approved the full 08 contract on 2026-08-16.

## 1. Goal

Render every visible **living** canonical WHAT actor through one focused presentation layer while preserving stable actor identity, authoritative WHAT placement/facing, deterministic draw order, recovered same-owner actor art, and strict separation from AI, combat, health, inventory, corpse decay, camera, input, and simulation ownership.

08 covers:

- the currently controlled survivor;
- non-player living human/survivor actors;
- living infected actors.

08 does **not** render corpses. Death transitions physical presentation out of the living ACTOR layer; persistent corpse identity/state/rendering belongs to a later Corpse / Decay / Contamination system.

## 2. Approved cross-system corpse direction

1. Corpses are not ordinary living ACTORs.
2. Death leaves a persistent physical corpse/world consequence rather than deleting the event.
3. Corpse age/decay can later create accumulated local contamination/filth pressure and sickness risk when bodies are ignored for too long or accumulate in enclosed living spaces.
4. The corpse model follows the mini-Zomboid rule: preserve meaningful cleanup/disposal/health consequences without detailed microbiology.
5. The corpse remains tied to the identity of the person/infected that died; exact same-ID versus linked corpse-ID representation is deferred to the dedicated corpse design because current WHAT entity semantic type is intentionally not a generic mutable metadata bag.
6. 08 is therefore living-actor-only.

Cross-system rationale is recorded in `DESIGN_DECISIONS.md`.

## 3. Recovery facts

### Tick retained/golden art

Protected Tick `game/assets/tactical_atlas.svg` contains one historical four-facing First Fire survivor variant at indices 96–99. Golden Tick `TacticalTiles.gd` did not use those cells for non-player actors; it used the four independent `player_*.svg` textures for the player.

04 Art Catalog exposes `resolve_player(facing)`, mapping canonical WHERE NORTH/EAST/SOUTH/WEST to those exact protected player textures.

### First Fire same-owner recovery source

`FIRST_FIRE_REUSE.md` permits recovery of coherent same-owner First Fire tactical/world work without importing First Fire runtime architecture.

The inspected First Fire tactical atlas and `FFTacticalVisuals.gd` establish:

- survivor variants: source atlas 96–127 = 8 variants × 4 facings;
- infected/zombie variants: source atlas 128–159 = 8 variants × 4 facings;
- survivor corpse variants: 160–167;
- infected corpse variants: 176–183;
- carried weapon silhouettes begin at 192.

Facing order is NORTH, EAST, SOUTH, WEST. Historical living actor selection was:

- survivor: `96 + variant * 4 + facing_index`;
- infected: `128 + variant * 4 + facing_index`.

This is real solved same-owner art, not a placeholder.

## 4. Implemented art recovery boundary

08 does **not modify** protected Tick `tactical_atlas.svg` or the protected player textures.

Implementation added:

`game/assets/actor_atlas.svg`

This is a narrow actor-only extraction/repack from the same-owner First Fire artwork without stylistic regeneration:

- 8 survivor variants × 4 facings at canonical actor-atlas indices 0–31;
- 8 infected variants × 4 facings at indices 32–63;
- no corpse rows;
- no weapon/item rows;
- 32×32 cells, 16 columns.

Recovered actor asset Git blob:

`205036fff8ffb24f828a09cf033abcf615ce6fe0`

First Fire source tactical-atlas blob recorded for provenance:

`2caff9a1c2ec84fc7d56e6b2c64bce953c575029`

The original ten protected Tick art files remain byte-identical and retain their existing golden-baseline contract. The actor asset has a separate immutable recovery identity rather than being falsely described as part of that golden Tick baseline.

Corpse and carried-equipment art remain recovery sources for later owning systems.

## 5. Non-goals

08 does **not** own or implement:

- AI/decision making/pathfinding or infected behavior;
- combat/hit resolution;
- health/injury/death processing;
- corpse creation/state/decay/contamination/cleanup/burial/burning/disposal;
- inventory/equipment mechanics or weapon stats;
- names/biographies/relationships/population simulation;
- character creation or persistent appearance customization;
- animation timing or movement interpolation;
- perception/vision/fog, lighting/weather/sound;
- collision, Movement, WHEN scheduling;
- camera/zoom, input/UI;
- Tactical Renderer orchestration;
- generation;
- frozen reboot wiring.

## 6. Owners

- `game/assets/actor_atlas.svg`
- `game/scripts/render/ActorDrawCommand.gd`
- `game/scripts/render/ActorLayerRenderer.gd`
- `game/scripts/ci/ActorLayerRendererSmoke.gd`
- `.github/workflows/actor-renderer.yml`

Narrow 04 Art Catalog extension:

- `SOURCE_ACTORS` registration for `res://assets/actor_atlas.svg`;
- `resolve_living_actor(actor_family, facing, variant)`;
- actor mapping counts;
- separately pinned actor recovery asset/provenance;
- expanded `ArtCatalogSmoke.gd` and art-catalog CI.

No actor simulation state store was introduced.

## 7. Public renderer contract

`ActorLayerRenderer` is a standalone `Node2D` with injected read dependencies:

- canonical `WorldState`;
- canonical `ArtCatalog`.

Public presentation surface:

- `configure(world_state, art_catalog) -> bool`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `set_controlled_actor_id(actor_id: String) -> bool`
- `controlled_actor_id() -> String`
- `plan_visible_commands() -> Array[ActorDrawCommand]`
- `clear_texture_cache()`
- bounded diagnostic access.

`controlled_actor_id` is a **presentation/session role**, not a WHAT semantic type. Taking control of a different survivor does not rewrite that person's persistent identity.

Changing controlled actor requests redraw but mutates no world/simulation state.

## 8. Canonical living actor semantic families

Initial recognized WHAT ACTOR semantic types are exactly:

- `actor.survivor`
- `actor.infected`

The controlled actor is identified by stable entity ID, not a permanent `actor.player` type.

Future actor families such as animals require explicit art/design registration. Unknown ACTOR-channel semantic types become diagnostic.

A controlled actor must currently be an `actor.survivor`; assigning control to an infected produces a visible diagnostic rather than rendering infected truth as the survivor player sprite.

## 9. Discovery and ordering

08 scans only visible cells through:

`WorldState.entities_at(cell, SpatialLayer.Channel.ACTOR)`

Stable IDs are deduplicated because arbitrary WHAT footprints can intersect multiple visible cells. Each visible/intersecting living actor creates at most one draw command.

Deterministic order:

1. placement anchor Y;
2. placement anchor X;
3. stable actor ID.

Overlapping ACTOR placements draw deterministically rather than becoming renderer-owned collision legality.

## 10. Placement / facing / footprint

Every drawable actor requires an existing WHAT entity record and placement on ACTOR channel. WHAT already validates canonical facing/footprint geometry; 08 additionally verifies occupancy consistency.

`ActorDrawCommand` retains:

- stable actor ID;
- semantic type/family;
- controlled role;
- global anchor;
- facing;
- copied physical footprint/world cells;
- presentation variant where applicable;
- local destination rect;
- copied `ArtSelection` or diagnostic state.

Current living actor art renders once at the actor anchor. Physical footprint remains world truth and is not stretched or duplicated into presentation geometry.

## 11. Player-controlled actor art

The controlled survivor uses:

`ArtCatalog.resolve_player(facing)`

This preserves the exact four independent protected player-facing sprites. No arrow/ring was added merely to identify the player.

## 12. Non-player survivor / infected art

04 Art Catalog now exposes:

`resolve_living_actor(actor_family, facing, variant) -> ArtSelection`

Allowed families are survivor and infected. The renderer never knows actor-atlas indices.

### Deterministic default appearance

Until a persistent Actor Appearance system exists, non-player variant choice is a deterministic presentation default derived from stable actor ID using explicit 32-bit FNV-1a over the UTF-8 ID bytes, modulo 8.

Properties:

- same stable actor ID produces the same default variant across runs/platforms;
- no RNG/global state or dictionary order participates;
- the variant has no gameplay meaning;
- a future Actor Appearance profile can override it without changing WHAT placement or renderer geometry.

## 13. Stance

08 does **not invent crouch art**.

Physical stance remains owned by 03 Actor Locomotion. 08 does not require a locomotion record merely to render an actor; crouched actors currently use normal directional living-actor art. No fake ring, squash or opacity effect is used as substitute crouch art.

## 14. Drawing geometry

Controlled player art uses the full visible cell rectangle.

Recovered First Fire non-player art preserves the historical approximately 29×29-in-32 proportion:

`actor_draw_size = cell_pixels * (29.0 / 32.0)`

centered in the anchor cell. This is presentation geometry only and does not shrink the physical footprint/collision body.

FOUND selections use cached textures and the same `draw_texture_rect_region` / `draw_texture_rect` paths as existing canonical renderers.

## 15. Redraw / invalidation

No `_process()` polling.

Redraw occurs on:

- configure;
- visible window / cell scale change;
- controlled actor ID change;
- texture-cache clear;
- WHAT world reset;
- relevant visible ACTOR placement set/removal/move;
- relevant visible actor entity removal.

The renderer keeps a narrow ACTOR-placement relevance index so terrain and non-ACTOR placement changes do not redraw merely because an unrelated entity happens to have actor-like semantic text.

08 has no dependency on AI ticks or movement scheduler events. It reacts when WHAT placement truth changes.

## 16. Diagnostics

Visible failure covers:

- missing actor entity/placement;
- wrong channel/occupancy mismatch;
- unknown actor semantic family;
- unknown art family/variant/facing;
- controlled infected/non-survivor role mismatch;
- invalid/non-drawable selection;
- texture load failure.

Unknown future animals are never silently substituted with survivor/infected art.

## 17. Performance / mobile

- visible ACTOR occupancy only;
- stable-ID deduplication;
- one base sprite command per visible actor;
- deterministic sorting;
- texture cache;
- event-driven redraw;
- no per-frame world scan;
- no permanent render Node per distant persistent actor;
- no input/hover/Safari behavior inside renderer.

## 18. Verified acceptance

Implementation candidate `77f2a86e964bef9128fd2b52a0799d46c146601e` introduced the production system. A CI-only correction at `c37be260e273e70a2bb2f5a91261d99a8a5cb898` fixed a mistyped assertion for the already-protected final-props hash; no production or actor-art repair was required.

Dedicated **Player Living Actor Renderer contract** run `31985099706` passed on `c37be260...`:

- source boundary isolation;
- all ten protected Tick asset hashes + recovered actor asset hash;
- Godot 4.7.1 project parse/import;
- Art Catalog regression;
- Ground regression;
- Structure regression;
- Prop regression;
- controlled N/E/S/W exact player art;
- survivor/infected recovered art;
- deterministic stable-ID appearance defaults;
- negative/global coordinate mapping;
- multi-cell dedup/physical geometry retention;
- deterministic ACTOR overlap;
- diagnostics/channel filtering;
- controlled-role redraw and relevant WHAT invalidation.

Dedicated **Recovered Art Catalog contract** run `31985099764` also passed independently on the same code head and validates all 64 living-NPC actor cells plus the existing recovered catalog.

## 19. Corpse / decay future seam

08 stops at living actors.

Future corpse design should decide:

- physical corpse entity/channel representation;
- durable relation to deceased persistent identity;
- death tick / age and simplified decay stages;
- contamination/filth contribution and environmental aggregation;
- Health interpretation of sustained exposure;
- moving/dragging/searching/cleaning/burial/burning/disposal actions;
- corpse collision/passability changes;
- separately recovered corpse visual variants;
- persistence and streaming/coarse simulation.

Conceptual direction remains:

`corpse age/stage × corpse count × local environmental modifiers -> contamination pressure`

Exact formula/stages are not part of 08.

## 20. Future visual seams

- persistent Actor Appearance / character creator can override default NPC variant;
- equipment presentation can add recovered weapon/carried-item silhouettes without inventory logic entering 08;
- stance-specific visuals can later consume 03 stance;
- damage/status VFX remain separate overlays;
- animals add explicit family/art registration;
- Tactical composition later combines Ground + Structure + Prop + Actor;
- perception/lighting can later hide/modulate actors without changing persistent world truth.

## 21. Implementation impact

Changed:

- new actor-only recovered art asset;
- additive Art Catalog actor source/resolver/provenance + tests;
- `ActorDrawCommand.gd`;
- `ActorLayerRenderer.gd`;
- actor renderer smoke/workflow.

Untouched:

- WHERE / WHAT / WHEN contracts;
- Collision / Movement / Actor Locomotion;
- Door State;
- Ground / Structure / Prop production renderers;
- all ten protected existing art assets;
- AI / Health / Inventory / Corpse mechanics;
- generation / reboot / camera / input / UI.

Contract impact is additive only: 04 Art Catalog gains actor-art selection; existing resolver semantics are unchanged. No simulation public contract changed.

## 22. North-star fit

Rendering the player, autonomous survivors, and infected through the same living ACTOR truth supports a causally populated persistent world. Separating corpses from the living actor layer preserves death as an enduring physical consequence and leaves room for cleanup/decay health pressure without turning rendering into a death or disease simulator.

The actor art recovery follows the archaeology rule: use real solved same-owner survivor/infected art rather than fake colored markers while keeping First Fire runtime architecture out.

## 23. Approved decisions

Approved 2026-08-16:

- one living-ACTOR renderer covers controlled survivor, NPC survivors and infected;
- controlled status is a stable-ID presentation role, not permanent world type;
- protected player textures remain the controlled-survivor art;
- recover the real same-owner 8×4 survivor and 8×4 infected art into a separate actor atlas;
- NPC default appearance is deterministic from stable ID using an explicit stable hash;
- no fake crouch presentation;
- corpses remain outside 08 and are a persistent future mechanic/domain.
