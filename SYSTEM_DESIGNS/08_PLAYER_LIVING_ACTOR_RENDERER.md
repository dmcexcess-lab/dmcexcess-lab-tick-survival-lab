# Tick Survival Lab — 08 Player / Living Actor Renderer

Status: **DRAFT — detailed renderer contract awaiting explicit approval before implementation**

Discussion basis: after 07 Prop / Fixture / Vegetation Renderer was implemented, the user confirmed that the next actor presentation layer should include non-player actors and then explicitly approved the rule that corpses are persistent post-death world problems rather than living ACTOR render entries.

## 1. Goal

Render every visible **living** canonical WHAT actor through one focused presentation layer while preserving stable actor identity, authoritative WHAT placement/facing, deterministic draw order, recovered same-owner actor art, and strict separation from AI, combat, health, inventory, corpse decay, camera, input, and simulation ownership.

08 covers:

- the currently controlled survivor;
- non-player living human/survivor actors;
- living infected actors.

08 does **not** render corpses. Death transitions physical presentation out of the living ACTOR layer; persistent corpse identity/state/rendering belongs to a later Corpse / Decay / Contamination system.

## 2. Approved cross-system direction already locked

The following direction is already approved independently of the remaining 08 details:

1. Corpses are not ordinary living ACTORs.
2. Death leaves a persistent physical corpse/world consequence rather than deleting the event.
3. Corpse age/decay can later create accumulated local contamination/filth pressure and sickness risk when bodies are ignored for too long or accumulate in enclosed living spaces.
4. The corpse model should follow the mini-Zomboid rule: preserve meaningful cleanup/disposal/health consequences without detailed microbiology.
5. The corpse remains tied to the identity of the person/infected that died; exact same-ID versus linked corpse-ID representation is deferred to the dedicated corpse design because current WHAT entity semantic type is intentionally not a generic mutable metadata bag.
6. 08 therefore stays living-actor-only.

## 3. Recovery facts

### Tick retained/golden art

Current protected Tick `game/assets/tactical_atlas.svg` already contains one real four-facing First Fire survivor variant at historical atlas indices **96–99**. The golden Tick `TacticalTiles.gd` did not consume those survivor atlas cells for non-player actors; it only used the four independent `player_*.svg` textures for the player.

Current 04 Art Catalog already exposes:

`resolve_player(facing)`

which maps canonical WHERE NORTH/EAST/SOUTH/WEST to the four exact retained player textures.

### First Fire same-owner recovery source

`FIRST_FIRE_REUSE.md` explicitly allows recovery of coherent same-owner First Fire tactical/world work without importing First Fire runtime architecture.

Current `dmcexcess-lab/first-fire` contains a richer actor section in its tactical atlas and `FFTacticalVisuals.gd` documents its exact use:

- survivor variants: atlas **96–127** = 8 variants × 4 facings;
- infected/zombie variants: atlas **128–159** = 8 variants × 4 facings;
- survivor corpse variants: **160–167**;
- infected corpse variants: **176–183**;
- carried weapon silhouettes begin at **192**.

First Fire facing order is NORTH, EAST, SOUTH, WEST and uses:

- survivor: `96 + variant * 4 + facing_index`;
- infected: `128 + variant * 4 + facing_index`.

This is real solved same-owner art, not a placeholder.

## 4. Proposed art recovery boundary

08 should **not modify** the protected Tick `tactical_atlas.svg` or the protected four player textures.

Instead, implementation should add a new narrow actor-only retained asset, tentatively:

`game/assets/actor_atlas.svg`

It should be extracted from the existing same-owner First Fire actor artwork without stylistic regeneration:

- 8 survivor variants × 4 facings;
- 8 infected variants × 4 facings;
- no corpse rows in 08;
- no weapon/item rows in 08.

The new actor atlas should use the same 32×32 cell geometry. 04 Art Catalog should gain a focused actor source + resolver rather than making Actor renderer know atlas indices.

Corpse and carried-equipment art remain available recovery sources for their later owning systems but are deliberately not pulled into 08 merely because the source sheet contains them.

## 5. Non-goals

08 does **not** own or implement:

- AI/decision making/pathfinding;
- infected behavior;
- combat/hit resolution;
- health/injury/death processing;
- corpse creation, corpse state, decay, contamination, cleanup, burial, burning or disposal;
- inventory/equipment mechanics;
- weapon stats or carried-item state;
- actor names, biographies, relationships or population simulation;
- character creator / appearance customization;
- animation timing;
- movement interpolation;
- perception/vision/fog;
- lighting/weather/sound;
- collision;
- movement actions;
- WHEN scheduling;
- camera/zoom;
- input/UI;
- Tactical Renderer orchestration;
- generation;
- frozen reboot wiring.

## 6. Intended owners

After approval:

- `game/scripts/render/ActorDrawCommand.gd`
- `game/scripts/render/ActorLayerRenderer.gd`
- `game/scripts/ci/ActorLayerRendererSmoke.gd`
- `.github/workflows/actor-renderer.yml`

Narrow 04 Art Catalog extension expected:

- new actor art source registration;
- actor-family/facing/variant descriptor resolver;
- new recovered actor asset + immutable baseline identity check.

No actor simulation state store is introduced by 08.

## 7. Public renderer contract

`ActorLayerRenderer` is a standalone `Node2D`.

Injected read dependencies:

- canonical `WorldState`;
- canonical `ArtCatalog`.

Presentation configuration:

- `configure(world_state, art_catalog) -> bool`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `set_controlled_actor_id(actor_id: String) -> bool`
- `plan_visible_commands() -> Array[ActorDrawCommand]`
- `clear_texture_cache()`
- bounded diagnostic access matching existing focused render layers.

`controlled_actor_id` is a **presentation/session role**, not a WHAT semantic type. Taking control of a different survivor must not require changing that person's persistent entity type.

Changing the controlled actor ID requests redraw but mutates no world/simulation state.

## 8. Canonical living actor semantic families

Initial recognized WHAT ACTOR semantic families:

- `actor.survivor`
- `actor.infected`

The controlled actor is identified by stable entity ID, not by inventing `actor.player` as permanent world identity.

Future actor families such as animals require explicit art/design registration rather than being guessed.

A WHAT entity on ACTOR channel with an unrecognized semantic family becomes diagnostic.

## 9. Discovery and ordering

08 scans only visible cells through:

`WorldState.entities_at(cell, SpatialLayer.Channel.ACTOR)`

Stable IDs are deduplicated because arbitrary WHAT footprints can intersect more than one visible cell.

Each visible/intersecting living actor creates at most one draw command.

Deterministic order:

1. placement anchor Y;
2. placement anchor X;
3. stable actor ID.

If ACTOR placements overlap, 08 draws them deterministically rather than becoming collision legality. Collision/Movement owns whether an overlap should have been allowed.

## 10. Placement / facing / footprint

Every drawable actor requires:

- existing WHAT entity record;
- WHAT placement on ACTOR channel;
- valid canonical N/E/S/W facing;
- placement footprint that actually covers the occupancy entry used to discover it.

`ActorDrawCommand` retains at least:

- stable actor ID;
- semantic actor family;
- whether this ID is currently controlled;
- global anchor;
- facing;
- copied physical footprint/world cells;
- presentation variant index where applicable;
- local destination rect;
- copied `ArtSelection` or diagnostic state.

Like 07, current living actor art renders once at the actor anchor. Physical footprint remains world truth and is not turned into stretched/duplicated actor art.

## 11. Player-controlled actor art

The currently controlled actor uses current 04:

`ArtCatalog.resolve_player(facing)`

This preserves the exact four independent player-facing sprites already protected by the golden baseline.

The renderer does not add an arrow/ring solely to identify the player. A later explicit accessibility/selection presentation can add one if desired.

## 12. Non-player survivor / infected art

04 Art Catalog should gain a semantic living-actor resolver with typed UNKNOWN failure, conceptually:

`resolve_living_actor(actor_family, facing, variant) -> ArtSelection`

Allowed families initially:

- survivor;
- infected.

The renderer must not know atlas indices.

### Proposed default visual-variant rule

Until a future persistent Actor Appearance system exists, non-player variant choice should be a deterministic **presentation default derived from the stable actor ID**, modulo the 8 recovered variants.

Requirements:

- same stable actor ID always produces the same default variant across runs/platforms;
- use an explicitly defined stable hash/byte algorithm, not dictionary order or RNG state;
- this variant is presentation default only and has no gameplay meaning;
- a future explicit Actor Appearance profile may override the default without changing WHAT placement or Actor renderer geometry.

This avoids making every NPC identical while also avoiding fake persistent appearance state before that system is designed.

This default-variant rule is part of the DRAFT and still requires user approval with the rest of 08.

## 13. Stance

08 v1 should **not invent crouch art**.

The recovered living actor sprites have directional variants but no authored standing/crouched variant set. Therefore:

- physical stance remains owned by 03 Actor Locomotion;
- 08 does not require a locomotion record merely to render an actor;
- crouched actors currently use their normal living-actor sprite;
- no fake ring, scaling squash, or arbitrary opacity change is added to simulate crouching.

A future actor-visual contract may consume stance-specific art or a deliberate stance presentation rule.

This keeps infected or other ACTOR entities renderable even if they do not use 03's voluntary human stance domain.

## 14. Drawing geometry

Controlled player art follows the existing full-cell player texture path.

Recovered First Fire non-player actor art historically rendered at approximately **29×29 px centered inside a 32×32 cell**. 08 should preserve that proportion at arbitrary display scale:

`actor_draw_size = cell_pixels * (29.0 / 32.0)`

centered in the actor's anchor cell.

This is presentation geometry only and does not shrink the physical WHAT footprint/collision body.

FOUND selections use cached textures and the same proven `draw_texture_rect_region` / `draw_texture_rect` paths as existing canonical renderers.

## 15. Redraw / invalidation

No `_process()` polling.

Redraw on:

- configure;
- visible window / cell scale change;
- controlled actor ID change;
- texture cache clear;
- WHAT world reset;
- visible ACTOR placement set/removal/move;
- entity removal affecting visible actor cells.

Terrain/STRUCTURE/OBJECT/LOOSE_ITEM/EFFECT changes should not redraw when WHAT change information proves they are irrelevant.

08 has no dependency on AI ticks or movement scheduler events. It reacts when persistent WHAT placement actually changes.

## 16. Diagnostics

Fail visibly for:

- occupancy references missing actor entity;
- missing placement;
- wrong placement channel;
- occupancy/placement mismatch;
- invalid facing;
- unknown actor semantic family;
- unknown actor art family/variant;
- invalid/non-drawable ArtSelection;
- texture load failure.

Do not substitute survivor art for unknown future animals or infected art for unknown actor types.

## 17. Performance / mobile

- visible ACTOR occupancy only;
- stable-ID deduplication;
- at most one base actor sprite command per visible actor;
- deterministic sorting;
- texture cache;
- event-driven redraw;
- no per-frame world scan;
- no permanent render Node per persistent distant actor;
- no input/hover/Safari-specific behavior inside renderer.

## 18. Acceptance tests after approval

Dedicated Godot 4.7.1 CI should prove:

- source boundary isolation;
- project parse/import;
- Art Catalog, Ground, Structure and Prop regressions remain green;
- ACTOR-only filtering;
- controlled actor uses exact N/E/S/W player art;
- non-player survivor uses recovered survivor art;
- infected uses recovered infected art;
- all 8 recovered non-player variants resolve for all four facings;
- stable-ID default variant is deterministic;
- different stable IDs can map to different variants without RNG/global state;
- unknown actor family is diagnostic;
- negative/global coordinates map locally;
- multi-cell actor occupancy deduplicates to one command;
- facing/footprint/world cells retained;
- overlapping ACTOR occupants remain deterministic rather than renderer-owned collision errors;
- controlled actor change redraws;
- visible ACTOR move/removal redraws;
- clearly irrelevant terrain/structure/object changes do not redraw;
- recovered actor texture loads;
- protected existing Tick art remains byte-identical;
- production renderer imports no Collision, Movement, WHEN, AI, Health, Inventory, Corpse, generation, reboot, camera/input/UI, lighting/perception/weather/sound, or other render-layer internals.

## 19. Corpse / decay future seam

08 explicitly stops at living actors.

Future death/corpse design should decide:

- physical corpse entity/channel representation;
- relation back to deceased persistent person/infected identity;
- death tick / age;
- simplified decay stages;
- local contamination/filth contribution;
- aggregation in enclosed/occupied spaces;
- Health interpretation of sustained exposure;
- moving/dragging/searching/cleaning/burial/burning/disposal actions;
- corpse collision/passability changes;
- corpse visual variants recovered from First Fire;
- persistence and streaming/coarse simulation.

A likely mini-Zomboid model is:

`corpse age/stage × corpse count × local environmental modifiers -> contamination pressure`

with Health later interpreting sustained pressure. Exact formula/stages are **not** approved here and belong to the dedicated Corpse / Decay design.

## 20. Future visual seams

- persistent Actor Appearance / character creator may override default art variant;
- equipment renderer may add recovered weapon/carried-item silhouettes without inventory logic entering 08;
- stance-specific visuals may consume 03 stance later;
- damage/status VFX remain separate overlays;
- animals add explicit actor family/art registration;
- Tactical Renderer later composes Ground + Structure + Prop + Actor;
- perception/lighting may later hide/modulate actors without changing their persistent world state.

## 21. Expected implementation impact

### Expected to change after full 08 approval

- new actor-only recovered art asset;
- narrow Art Catalog actor-source/resolver extension + baseline checks;
- `ActorDrawCommand.gd`;
- `ActorLayerRenderer.gd`;
- actor renderer smoke/workflow;
- 08 design promotion + routing/context/changelog docs.

### Must remain untouched

- WHERE / WHAT / WHEN contracts;
- Collision / Movement / Actor Locomotion;
- Door State;
- Ground / Structure / Prop production renderers;
- protected existing art assets;
- AI / Health / Inventory / Corpse mechanics;
- generation / reboot / camera / input / UI.

### Contract impact

04 Art Catalog receives an additive actor-art source/resolver. No existing resolver semantics change.

No simulation public contract changes are intended.

## 22. North-star fit

Rendering the player, autonomous survivors, and infected through the same living ACTOR truth is necessary for a causally populated persistent world. Separating corpses from the living actor layer preserves death as an enduring physical consequence and leaves room for the approved cleanup/decay health pressure without turning rendering into a death or disease simulator.

The actor art recovery also follows the project's archaeology rule: use real solved same-owner survivor/infected art rather than fake colored markers while keeping First Fire runtime architecture out.

## 23. Approval state

**DRAFT.**

The user has already approved the corpse-vs-living-actor boundary and the future corpse-decay consequence direction. The remaining 08 details — especially recovered actor-atlas extraction, stable-ID default non-player variants, controlled-actor presentation role, and no fake crouch presentation — require explicit approval before implementation.