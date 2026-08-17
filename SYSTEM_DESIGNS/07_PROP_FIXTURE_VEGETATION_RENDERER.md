# Tick Survival Lab — 07 Prop / Fixture / Vegetation Renderer

Status: **DRAFT — refreshed design awaiting explicit user approval before runtime implementation**

Discussion basis: after 06A Door State and 06 Structure Layer Renderer were implemented and verified, the user instructed: **“Refresh yourself make sure we haven't gotten lost. Then lets get prop render”**. The repository refresh confirmed the project remains aligned with the North Star and already names Prop / Fixture / Vegetation Renderer as the next bounded presentation system.

## 1. Goal

Render visible canonical WHAT `OBJECT` entities representing props, fixtures, and vegetation through the recovered 04 Art Catalog while preserving stable WHAT identity, WHERE placement/facing/footprint facts, and strict presentation/simulation separation.

07 recovers the mature multi-atlas prop vocabulary without making the renderer own object physics, gameplay state, generation, inventory, camera, input, or the frozen reboot runtime.

## 2. North-star / anti-drift result

The refreshed project remains:

> **Ultima-style turn-based mini Zomboid.**

and:

> **Mini means reduced complexity, not reduced consequence or mood.**

07 fits that direction by making homes, stores, farms, streets, utilities, vegetation, and clutter visually readable from persistent world truth while keeping rendering replaceable.

No project-direction reset is required.

## 3. Recovery facts

Golden recovery baseline:

- commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`
- golden `TacticalTiles.gd` blob `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Golden `draw_prop()`:

- selected final-prop exact mappings first;
- then final aliases;
- then building props;
- then clutter props;
- then tactical props;
- drew one 32x32 atlas region into one supplied rectangle;
- performed no facing/orientation transform;
- had no multi-cell visual-geometry system.

04 Art Catalog has already recovered those mappings exactly and intentionally returns typed UNKNOWN instead of the golden silent crate fallback for unknown prop IDs.

## 4. Non-goals

07 does **not** own or implement:

- Ground or Structure rendering;
- player/NPC/corpse rendering;
- `LOOSE_ITEM` rendering;
- `EFFECT` rendering;
- collision/passability;
- movement/pathfinding;
- container contents/searchability;
- inventory/equipment;
- furniture interaction/use actions;
- electrical/power state;
- appliance state;
- vegetation growth/health;
- construction/destruction;
- vehicle rendering;
- animation/VFX;
- lighting/perception/weather/sound;
- generation/prefab placement;
- camera/zoom/visible-window calculation;
- input/UI;
- tactical renderer orchestration;
- deprecated reboot wiring.

Stateful visual variants such as an active generator, open container, burning prop, harvested crop, broken appliance, or damaged furniture require their future owning typed state/art contracts rather than being guessed here.

## 5. Intended owners

After approval:

- `game/scripts/render/PropDrawCommand.gd`
- `game/scripts/render/PropLayerRenderer.gd`
- `game/scripts/ci/PropLayerRendererSmoke.gd`
- `.github/workflows/prop-renderer.yml`

No new simulation domain is required for the initial renderer.

## 6. Public contract

`PropLayerRenderer` is a standalone `Node2D` presentation owner.

Dependencies are injected explicitly:

- canonical `WorldState` read/query contract;
- canonical `ArtCatalog` descriptor contract.

View state matches 05 Ground and 06 Structure:

- global top-left visible cell;
- positive whole-cell visible width/height;
- positive display cell size in pixels.

Public surface includes:

- `configure(world_state, art_catalog) -> bool`
- `is_configured() -> bool`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `has_valid_view() -> bool`
- `plan_visible_commands() -> Array[PropDrawCommand]`
- `clear_texture_cache()`
- bounded diagnostic-reason access equivalent to existing focused render layers.

The renderer emits presentation-only `redraw_requested(reason)` and uses `queue_redraw()`; there is no simulation meaning in that signal.

## 7. Canonical semantic families

07 initially recognizes exactly these semantic entity families on WHAT's `OBJECT` channel:

- `prop.<kind>`
- `fixture.<kind>`
- `vegetation.<kind>`

All three delegate their full semantic ID to `ArtCatalog.resolve_prop()`; the catalog's leaf-token normalization provides the recovered vocabulary.

Examples consistent with current project vocabulary include:

- `prop.utility_pole`
- `fixture.kitchen_sink`
- `vegetation.deciduous_large`

An `OBJECT` entity outside those semantic families is diagnostic rather than inferred from whichever atlas entry happens to exist.

These prefixes classify content for presentation only. They do not imply collision, interaction, inventory, power, opacity, growth, or destructibility.

## 8. Discovery and deterministic ordering

The renderer scans only the supplied visible global-cell window using:

`WorldState.entities_at(cell, SpatialLayer.Channel.OBJECT)`

Because a multi-cell OBJECT appears in occupancy for multiple cells, IDs are deduplicated before command creation.

Each visible/intersecting entity produces **at most one** draw command.

Commands are deterministically ordered by:

1. placement anchor Y;
2. placement anchor X;
3. stable entity ID.

That provides stable top-down draw order independent of dictionary/hash order. Multiple OBJECT entities may legally coexist in one cell at the WHAT level; 07 draws them deterministically rather than declaring overlap invalid or inventing collision legality.

## 9. Placement, footprint, and anchor rule

Every drawable OBJECT must have a valid WHAT placement on `SpatialLayer.Channel.OBJECT`.

`PropDrawCommand` retains:

- stable entity ID;
- semantic type;
- semantic family (`prop` / `fixture` / `vegetation` / `unknown`);
- placement anchor;
- canonical N/E/S/W facing;
- a copied whole-cell footprint / rotated world-cell list sufficient for diagnostics and future visual extension;
- destination rectangle;
- copied `ArtSelection` or diagnostic UNKNOWN selection.

### Initial recovered visual geometry

Current recovered prop sources are one-cell 32x32 atlas regions and golden `draw_prop()` drew one region into one rectangle. 07 therefore draws **one cell-sized sprite at the entity anchor**, even when the entity has a multi-cell physical footprint.

The physical footprint remains authoritative WHERE/WHAT geometry for collision, placement, construction, vehicles, etc. The renderer does not repeat one sprite over every occupied footprint cell and does not stretch a one-cell icon over an arbitrary footprint bounding box.

This is an explicit **art-is-not-physics** choice, not missing data.

If future large-object art needs multi-cell visual geometry, add a presentation-owned art geometry/anchor descriptor rather than changing WHAT footprints or teaching the renderer to guess from physics.

## 10. Facing / orientation rule

WHAT placement facing is authoritative and is retained in every draw command.

However, golden prop drawing did not define a native facing for atlas regions and performed no 90-degree rotation. Rotating every current prop would therefore invent a visual convention not recovered from the source.

Initial 07 behavior:

- preserve facing in the command;
- draw current recovered prop art unrotated;
- do not discard or normalize facing;
- do not infer visual orientation from semantic names.

Future art may add an explicit presentation-only orientation policy (native facing, rotatable flag, directional variant source). That can consume the already-preserved WHAT facing without changing persistent world geometry.

## 11. Art resolution

For each recognized semantic family:

`ArtCatalog.resolve_prop(entity.semantic_type)`

This preserves 04's recovered precedence:

1. final prop exact;
2. final prop alias;
3. building prop;
4. clutter prop;
5. tactical prop.

The special recovered `barrel` tactical mapping remains owned by Art Catalog and requires no renderer exception.

Unknown kind returns typed UNKNOWN and becomes a visible diagnostic. The renderer never substitutes crate/tree/chair/etc. art.

## 12. Drawing behavior

FOUND atlas selections use the same proven recovered cell draw path as Ground and Structure:

- lazy-load/cache texture from `ArtSelection.source.texture_path`;
- one-cell destination rectangle local to the visible origin at the placement anchor;
- source rectangle from `ArtSelection.region()`;
- `draw_texture_rect_region`;
- white modulation;
- transpose=false;
- clip_uv=true.

Valid future full-texture selections may use `draw_texture_rect`.

No atlas path, atlas index, or source-family switch is hardcoded into Prop renderer production code.

## 13. Coordinates / visible window

Global WHAT coordinates remain authoritative.

Destination rectangle is:

`(placement.anchor - visible_origin) * cell_pixels`

with a one-cell destination size.

This supports large and negative world coordinates without giant CanvasItem positions.

An entity is considered relevant to the visible renderer when any of its rotated footprint cells intersects the supplied visible window. Its anchor may be just outside the visible window; the resulting local destination may therefore be outside the nominal visible rectangle. Normal viewport clipping handles that without changing world truth.

Invalid non-positive visible dimensions or scale are rejected without replacing the last valid view.

## 14. Redraw / invalidation

There is no `_process()` redraw loop.

Redraw is requested on:

- dependency configuration;
- view/window/cell-scale change;
- texture-cache clear;
- WHAT `world_reset`;
- placement set/removal that touches the visible window and may affect an OBJECT;
- entity removal whose previous occupied cells touch the visible window.

Initial entity creation without placement does not redraw.

Terrain-only changes do not redraw.

STRUCTURE/ACTOR/LOOSE_ITEM/EFFECT placement changes should not redraw when the current change record provides enough after-state classification to prove irrelevance. Where WHAT's mechanic-agnostic removal/move record no longer contains prior channel information, conservative visible redraw is acceptable for correctness, matching the existing Structure approach.

No neighbor halo is required because current prop art has no connectivity topology.

## 15. Diagnostics / fail-visible behavior

Visible diagnostic behavior covers at least:

- occupancy references missing entity record;
- missing placement;
- placement not on OBJECT channel;
- occupancy/placement mismatch;
- unknown semantic family;
- unknown Art Catalog prop mapping;
- invalid/non-drawable selection;
- texture load failure.

Multiple OBJECT occupants in one cell are **not automatically diagnostic**. WHAT permits overlap and 07 does not become the collision/construction legality owner.

Diagnostic reason collection is bounded like the existing render layers.

## 16. Performance / mobile

- scan visible OBJECT occupancy only;
- deduplicate stable IDs;
- at most one command/draw per relevant entity;
- no full-world entity scan;
- no per-frame polling;
- deterministic sorting;
- lazy texture cache;
- event-driven redraw;
- no input/hover/Safari-specific behavior.

This is compatible with phone/Safari and a large persistent world because invisible/unmaterialized objects do not create render Nodes or per-frame work.

## 17. Required acceptance tests after approval

Dedicated Godot 4.7.1 CI should prove:

- source-boundary isolation;
- project import/parse;
- 04 Art Catalog regression remains green;
- 05 Ground regression remains green;
- 06 Structure regression remains green;
- `OBJECT` channel filtering;
- `prop.*`, `fixture.*`, and `vegetation.*` recognition;
- final exact, final alias, building, clutter, tactical, and barrel prop resolutions through real Art Catalog;
- unknown semantic family diagnostic;
- unknown prop kind diagnostic;
- deterministic anchor-row-major + stable-ID ordering;
- negative/global coordinates map to local destinations correctly;
- multi-cell footprint is deduplicated to one command;
- footprint/facing are retained in commands;
- recovered current art is not rotated merely because placement facing changes;
- overlapping OBJECT occupants produce deterministic separate commands rather than an invented collision error;
- visible OBJECT placement/removal requests redraw;
- terrain and clearly irrelevant non-OBJECT changes avoid redraw;
- world reset redraws;
- texture paths resolve/load;
- production Prop renderer imports no Collision, WHEN, Movement, Actor Locomotion, Door State, generation, reboot, camera/input/UI, lighting/perception/weather/sound, inventory, or other render-layer internals.

## 18. Allowed dependencies

Production 07 may depend only on:

- WHAT public entity/placement/OBJECT occupancy + mechanic-agnostic change notifications;
- WHERE `SpatialLayer` / facing / footprint value contracts already carried through WHAT placement;
- 04 Art Catalog / ArtSelection;
- Godot `Node2D` / CanvasItem / ResourceLoader primitives.

## 19. Forbidden dependencies

Production 07 must not import or inspect:

- Collision / movement / actor capability;
- Door State;
- WHEN;
- generation/prefab internals;
- reboot runtime;
- camera/input/UI;
- Ground/Structure/Actor renderer internals;
- inventory/container state;
- power/utilities simulation;
- vegetation simulation;
- construction/destruction;
- lighting/perception/weather/sound;
- AI.

## 20. Future seams

- **Large-object visual geometry:** presentation-owned descriptor can map one semantic art selection to authored multi-cell visual bounds/anchor without changing physical WHAT footprint.
- **Directional art:** presentation-owned orientation metadata can define native facing/rotatability/directional variants while consuming existing WHAT facing.
- **Stateful fixtures/props:** future typed mechanic stores can provide state-specific visual requests without putting state into WHAT or Art Catalog by accident.
- **Vehicles:** separate renderer/system can use multi-cell vehicle state without forcing ordinary prop renderer to become vehicle logic.
- **Construction/destruction:** mutates WHAT placement/entity truth; 07 reacts through ordinary world changes.
- **Tactical Renderer:** later composes Ground + Structure + Prop + Actor layers without absorbing their internals.
- **Lighting/perception:** later overlays/modulates presentation without becoming prop truth.

## 21. Expected implementation impact

### Files/modules expected to change after approval

- `game/scripts/render/PropDrawCommand.gd`
- `game/scripts/render/PropLayerRenderer.gd`
- `game/scripts/ci/PropLayerRendererSmoke.gd`
- `.github/workflows/prop-renderer.yml`
- this design status;
- `SYSTEM_DESIGNS/README.md`;
- `README_CONTEXT.md`;
- `CHANGELOG.md` after implementation.

### Protected neighboring modules

No contract changes expected to:

- WHERE / WHAT / WHEN;
- Collision / Movement / Locomotion / Door State;
- Art Catalog;
- Ground / Structure renderers;
- preserved art assets;
- generation / prefab systems;
- camera / input / UI;
- frozen reboot runtime.

## 22. North-star fit

Props, fixtures, and vegetation are a large part of making the persistent world visually legible as actual homes, businesses, streets, farms, and abandoned spaces. This renderer restores that visual density through persistent semantic WHAT facts while keeping collision, interaction, inventory, state, and generation causal and independently replaceable.

The deliberate single-anchor visual rule preserves the recovered one-cell art honestly instead of faking a multi-cell art system that does not yet exist.

## 23. Approval state

**DRAFT.**

The user requested the next Prop renderer after a repository refresh. This document records the refreshed design, but runtime implementation remains blocked until the user explicitly approves this 07 contract under the mandatory DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY workflow.
