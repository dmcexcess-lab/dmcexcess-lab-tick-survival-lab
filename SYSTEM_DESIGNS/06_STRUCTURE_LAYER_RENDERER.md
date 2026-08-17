# Tick Survival Lab — 06 Structure Layer Renderer

Status: **DRAFT — design complete enough for review; implementation blocked by missing canonical Door State read contract**

Discussion basis: after 05 Ground Layer Renderer was implemented, the user instructed **“Go for structural layer”**. Per the mandatory project workflow, this prompt designs the next major system but does not implement runtime code before approval.

## 1. Goal

Render visible canonical WHAT structures — walls, doors, and windows — through the recovered 04 Art Catalog while preserving the canonical structure-cell / explicit-axis geometry and keeping presentation independent from generation, collision, interaction, camera, input, and the frozen reboot runtime.

The renderer must be capable of presenting current dynamic door state correctly. It may never infer door openness from collision/passability or silently assume every door is closed.

## 2. Critical prerequisite discovered during design

Current canonical source has no Door State owner.

WHAT intentionally stores only stable entity identity, semantic type, and placement; mechanic-specific durable state such as doors belongs in a typed stable-ID domain outside `WorldEntityRecord`.

Collision intentionally treats an open door as a possible sparse non-blocking override, but its contract explicitly says collision does **not** own door state.

Golden `LocalWorldState.gd` stored each door's open/closed boolean directly and golden `TacticalTiles.gd` selected different open/closed door art from that fact.

Therefore 06 must **not** be implemented until a canonical Door State read contract exists. The smallest required upstream contract is:

- stable door entity ID -> explicit known OPEN or CLOSED state;
- missing/unclassified state remains UNKNOWN rather than defaulting;
- read-only lookup for renderer consumers;
- change/reset notification keyed by stable entity ID so visible doors redraw event-driven;
- persistent/snapshot-capable ownership designed independently from rendering and collision.

The owning Door State system, its writes, timing, interaction actions, and collision synchronization require their own bounded design/approval. 06 only states the read dependency it requires.

## 3. Non-goals

06 does not own or implement:

- door-state persistence or mutation;
- door interaction/open/close actions;
- WHEN timing for door actions;
- collision/passability updates;
- opacity/vision blocking;
- broken/openable window state;
- construction/destruction;
- structure generation or prefab placement;
- props, fixtures, vegetation, actors, corpses, items;
- ground rendering;
- camera/zoom/visible-window calculation;
- input/UI;
- lighting, perception, weather, or sound;
- tactical layer orchestration;
- wiring into deprecated `game/scripts/reboot/`.

## 4. Intended owners

After prerequisite approval/implementation:

- `game/scripts/render/StructureDrawCommand.gd`
- `game/scripts/render/StructureLayerRenderer.gd`
- `game/scripts/ci/StructureLayerRendererSmoke.gd`
- `.github/workflows/structure-renderer.yml`

The Door State owner is deliberately **not** placed under `render/` and is not part of 06.

## 5. Public renderer contract

`StructureLayerRenderer` is a standalone `Node2D` presentation owner.

Dependencies are injected explicitly:

- canonical `WorldState` for read-only entity/placement/STRUCTURE occupancy truth;
- canonical `ArtCatalog` for wall/door/window art selections;
- canonical Door State **read** service for explicit door OPEN/CLOSED/UNKNOWN state.

View state matches 05 Ground's presentation seam:

- global top-left visible cell;
- visible width/height in whole cells;
- positive display cell size in pixels.

`plan_visible_commands()` returns deterministic row-major `StructureDrawCommand` records containing at minimum:

- global cell;
- destination rectangle local to visible origin;
- stable structure entity ID;
- semantic structure type;
- structure kind (wall / door / window / unknown);
- canonical HORIZONTAL/VERTICAL structure axis;
- resolved copied `ArtSelection` or explicit diagnostic state.

## 6. Data ownership

06 owns only ephemeral presentation state:

- visible window / cell scale;
- lazy texture cache;
- bounded diagnostic bookkeeping.

It mutates no WHAT, Door State, Collision, WHEN, Art Catalog, generation, or gameplay state.

## 7. Structure discovery

For each visible global cell, the renderer queries:

`WorldState.entities_at(cell, SpatialLayer.Channel.STRUCTURE)`

It never scans all world entities.

Entity IDs are handled deterministically. WHAT occupancy already returns deterministic stable IDs; renderer command order for structures at the same cell is stable by entity ID.

A normal valid structure cell has exactly one wall/door/window structure entity. Multiple structure entities occupying the same cell are treated as ambiguous invalid presentation/world content and render a diagnostic instead of relying on arbitrary overdraw order.

Multi-cell structure entities are supported: each occupied visible cell produces a cell draw using the entity's semantic structure art. Doors/windows are expected to be single-cell content, but the renderer does not silently rewrite malformed footprints.

## 8. Canonical semantic categories

The renderer consumes semantic structure types, not atlas names.

Initial canonical categories for this layer are:

- `wall.<theme>`
- `door.<theme>`
- `window.<theme>`

Examples already consistent with canonical work include `door.house`; Art Catalog accepts the theme leaf token for the recovered wall/opening vocabulary.

The renderer must not infer a wall/door/window merely because an art mapping exists. A STRUCTURE placement whose semantic type does not belong to one of the recognized categories is diagnostic/UNKNOWN.

This categorization is presentation/content vocabulary only; it does not assign collision, opacity, interaction, or other mechanics.

## 9. Structure-axis rule

Every drawable wall/door/window placement must have a valid canonical `SpatialStructureGeometry.Axis.HORIZONTAL` or `.VERTICAL`.

A STRUCTURE placement with `NO_STRUCTURE_AXIS` or an invalid axis is diagnostic. The renderer does not invent an axis from neighboring cells or sprite appearance.

The axis remains part of each draw command for future art-pack/orientation extension and geometry validation.

### Golden visual behavior

Golden `TacticalTiles.gd` drew the same recovered wall/door/window cell sprite regardless of H/V axis; it did not rotate opening/wall art based on axis.

06 therefore preserves that recovered presentation initially: **axis is authoritative geometry but does not rotate current golden wall/door/window sprites.**

If a future art pack contains authored H/V variants or needs 90-degree rotation, Art Catalog/renderer presentation may add that without changing WHAT geometry.

## 10. Art resolution

### Wall

`wall.<theme>` delegates to:

`ArtCatalog.resolve_wall(semantic_type)`

This preserves recovered final -> world -> tactical wall precedence.

### Door

`door.<theme>` requires known canonical Door State.

- OPEN -> `ArtCatalog.resolve_door(theme, true)`
- CLOSED -> `ArtCatalog.resolve_door(theme, false)`
- UNKNOWN/missing -> visible diagnostic; no default to closed

The renderer never asks Collision whether the door blocks movement.

### Window

`window.<theme>` delegates to:

`ArtCatalog.resolve_window(theme)`

06 represents the currently recovered intact/static window vocabulary only. Future broken/open/barricaded window mechanics require their own persistent state/art contract rather than being guessed here.

## 11. Drawing behavior

FOUND atlas selections use the same recovered cell drawing semantics already proven by 05:

- lazy-load/cache texture from `ArtSelection.source.texture_path`;
- destination rectangle local to visible origin;
- source rectangle from `ArtSelection.region()`;
- `draw_texture_rect_region`;
- white modulation;
- transpose=false;
- clip_uv=true.

Valid future full-texture structure selections may use `draw_texture_rect`.

No texture path or atlas index is stored in WHAT or hardcoded into Structure renderer source.

## 12. Coordinates / visible window

WHAT structure positions remain authoritative global integer cells.

Destination rectangle is local to the supplied visible origin:

`(cell - visible_origin) * cell_pixels`

This mirrors 05 and supports large/negative persistent-world coordinates without giant CanvasItem positions.

Invalid non-positive visible dimensions or cell scale are rejected rather than silently replacing the last valid view.

## 13. Redraw / invalidation

There is no `_process()` redraw loop.

Redraw is requested on:

- dependency configuration;
- view/window/cell-scale change;
- texture-cache clear;
- WHAT `world_reset`;
- WHAT placement/entity changes that can affect a visible wall/door/window cell;
- Door State change for a currently visible door;
- Door State reset.

No structure-neighbor halo is required for recovered 06 art because current wall/opening sprite choice has no neighbor-connectivity topology.

Terrain-only changes do not redraw Structure.

For placement events, the renderer uses change `before_cells` / `after_cells` plus the entity's stable semantic category where still available. Entity removal touching visible cells may redraw conservatively because the removed record no longer exists to classify.

## 14. Diagnostics / fail-visible rules

Visible diagnostic drawing is required for:

- multiple STRUCTURE occupants at one cell;
- missing entity record referenced by occupancy;
- malformed/non-STRUCTURE placement;
- structure placement not actually covering the queried cell;
- missing/invalid structure axis;
- unknown structure semantic category;
- unknown wall/door/window theme art;
- missing/UNKNOWN Door State for a door;
- malformed/non-drawable `ArtSelection`;
- texture load failure.

The renderer does not silently turn bad structure content into a generic wall, closed door, or default window.

## 15. Performance / mobile

- query visible cells only;
- no full-world structure scan;
- no per-frame polling;
- deterministic row-major cell traversal;
- stable ID ordering within a cell;
- cached textures;
- event-driven redraw;
- no input, hover, or Safari-specific interaction in this layer.

Future camera/streaming systems can change the supplied visible window without changing structure semantics.

## 16. Required acceptance tests after prerequisite exists

Dedicated Godot 4.7.1 CI should prove:

- production source boundary guards;
- project import/parse;
- 04 Art Catalog regression remains green;
- 05 Ground renderer regression remains green;
- deterministic visible-only command order/count;
- local destination rectangles including negative global coordinates;
- wall themes use recovered Art Catalog precedence;
- open and closed doors resolve different recovered art from explicit Door State;
- missing Door State is diagnostic and never defaults closed;
- windows resolve recovered themed/default art;
- H/V structure axis is preserved in commands;
- current golden art is not rotated merely because axis differs;
- invalid/missing axis is diagnostic;
- multiple structure occupants are diagnostic;
- unknown semantic category/theme is diagnostic;
- non-structure/terrain/distant changes avoid unnecessary redraw where contract permits;
- visible structure placement/removal and visible Door State changes request redraw;
- resolved textures exist/load;
- no forbidden imports/dependencies.

## 17. Recovery sources

Golden visual source:

- recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`
- `TacticalTiles.gd` blob `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Recovered facts:

- walls select final/world/tactical art by theme;
- doors have separate open/closed art selections;
- windows have recovered themed/default selections;
- all draw as cell-sized atlas regions with transpose=false / clip_uv=true;
- golden wall/door/window drawing did not rotate based on structure axis.

Golden door-state source:

- `LocalWorldState.gd` blob `f8fd11ebbf0ff2b3958fd46000404cbb12142fc5`
- useful semantic fact: each door had explicit open/closed state;
- rejected architecture: coordinate-keyed local world dictionaries mixing walls/obstacles/glass/doors/collision.

## 18. Dependencies / forbidden boundaries

Allowed after prerequisite exists:

- WHAT public entity/placement/STRUCTURE occupancy reads + mechanic-agnostic change notifications;
- WHERE `SpatialLayer` and `SpatialStructureGeometry` public vocabulary;
- 04 Art Catalog / ArtSelection;
- canonical Door State read contract only;
- Godot Node2D/CanvasItem/ResourceLoader.

Forbidden:

- Door State writes/actions internals;
- Collision and collision overrides as visual truth;
- WHEN;
- Movement / Actor Locomotion;
- generation/prefab dictionaries;
- reboot runtime;
- camera/input/UI;
- Ground/Prop/Actor renderer internals;
- lighting/perception/weather/sound.

## 19. Future seams

- Door interaction system mutates canonical Door State and collision at an approved action commit without renderer involvement.
- Window State may later add broken/open/barricaded presentation through an analogous typed read seam.
- Construction/destruction changes WHAT placements; Structure renderer reacts through ordinary world changes.
- Tactical Renderer may orchestrate Ground + Structure + Prop + Actor layers without absorbing them.
- Lighting/perception can modulate/overlay later without becoming structure truth.
- Alternative art packs may add H/V variants while keeping canonical structure axis unchanged.

## 20. North-star fit

Walls, doors, and windows make houses/stores/farms physically readable and are essential to the Ultima-style world presentation. Requiring real dynamic door state preserves the mini-Zomboid consequence rule: the picture reflects the persistent physical world rather than a plausible-looking placeholder.

## 21. Draft recommendation

**Do not implement 06 yet.**

The next bounded design should be the minimal canonical **Door State** domain required by Structure, future interaction actions, collision synchronization, vision/opacity, save/load, AI, and construction.

After Door State is approved and implemented, return to this 06 design, resolve any exact read-contract names, obtain explicit user approval for 06, then implement/verify the renderer.
