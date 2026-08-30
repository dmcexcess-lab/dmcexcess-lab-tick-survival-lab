# Tick Survival Lab — 06 Structure Layer Renderer

Status: **IMPLEMENTED — canonical Structure renderer and dedicated Godot CI contract present 2026-08-16**

Approval basis: after 05 Ground Layer Renderer, the user requested the structural layer. Design identified canonical Door State as a prerequisite. The user approved that prerequisite and then explicitly authorized implementation of both systems with **“Program both”** on 2026-08-16.

## 1. Goal

Render visible canonical WHAT structures — walls, doors, and windows — through the recovered 04 Art Catalog while preserving canonical structure-cell / explicit-axis geometry and keeping presentation independent from generation, collision, interaction, camera, input, and the frozen reboot runtime.

Dynamic door art reads authoritative 06A Door State. Door openness is never inferred from collision/passability and an unknown door is never silently drawn closed.

## 2. Satisfied prerequisite

06A Door State is implemented under `game/scripts/simulation/doors/`.

The renderer consumes only its read/signaling contract:

- stable door entity ID -> OPEN / CLOSED / UNKNOWN;
- event signals for enrollment/removal/change/reset;
- no renderer access to Door State mutation internals.

Door interaction, timing, and Collision synchronization remain separate future systems.

## 3. Non-goals

06 does not own or implement:

- Door State persistence or mutation;
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
- deprecated reboot wiring.

## 4. Owners

- `game/scripts/render/StructureDrawCommand.gd`
- `game/scripts/render/StructureLayerRenderer.gd`
- `game/scripts/ci/StructureLayerRendererSmoke.gd`
- `.github/workflows/structure-renderer.yml`

Door State is separately owned by 06A under `game/scripts/simulation/doors/`.

## 5. Public renderer contract

`StructureLayerRenderer` is a standalone `Node2D`.

Dependencies are injected explicitly:

- canonical `WorldState` for read-only entity/placement/STRUCTURE occupancy truth;
- canonical `ArtCatalog` for wall/door/window selections;
- canonical `DoorStateStore` read/signaling contract.

View state matches Ground's seam:

- global top-left visible cell;
- visible whole-cell width/height;
- positive display cell size in pixels.

`plan_visible_commands()` returns deterministic row-major `StructureDrawCommand` records for visible occupied structure cells. Each command contains:

- global cell;
- destination rectangle local to visible origin;
- stable structure entity ID;
- semantic structure type;
- structure kind (`wall` / `door` / `window` / `unknown`);
- canonical HORIZONTAL/VERTICAL structure axis;
- copied `ArtSelection` or explicit diagnostic UNKNOWN selection.

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

Entity IDs are sorted deterministically. A normal valid structure cell has exactly one wall/door/window structure entity. Multiple STRUCTURE occupants in one cell produce one diagnostic command rather than arbitrary overdraw.

Multi-cell structure entities are supported: each occupied visible cell produces a cell draw using the entity's semantic structure art. Doors/windows are expected to be single-cell content, but malformed footprints are not silently rewritten.

## 8. Canonical semantic categories

Initial categories are exactly:

- `wall.<theme>`
- `door.<theme>`
- `window.<theme>`

The renderer does not infer category from atlas availability. A STRUCTURE placement outside those semantic families is diagnostic.

This vocabulary is presentation/content classification only; it does not assign collision, opacity, interaction, or other mechanics.

## 9. Structure-axis rule

Every drawable wall/door/window placement requires a valid `SpatialStructureGeometry.Axis.HORIZONTAL` or `.VERTICAL`.

Missing/invalid axis is diagnostic. The renderer does not invent an axis from neighboring cells or sprite appearance.

Golden `TacticalTiles.gd` did not rotate current recovered wall/door/window art by axis. 06 preserves that behavior: axis remains authoritative geometry and is retained in commands, but existing recovered opening/wall sprites are not rotated solely because axis differs.

Future art packs may add H/V variants or rotation without changing WHAT geometry.

## 10. Art resolution

### Wall

`wall.<theme>` delegates to `ArtCatalog.resolve_wall(semantic_type)`, preserving recovered final -> world -> tactical wall precedence.

### Door

`door.<theme>` reads canonical Door State:

- OPEN -> `ArtCatalog.resolve_door(theme, true)`
- CLOSED -> `ArtCatalog.resolve_door(theme, false)`
- UNKNOWN/missing -> diagnostic `door_state_unknown`

The renderer never asks Collision whether the door blocks movement.

### Window

`window.<theme>` delegates to `ArtCatalog.resolve_window(theme)`.

06 represents the currently recovered intact/static window vocabulary only. Broken/open/barricaded windows require their own future persistent state/art contract.

## 11. Drawing behavior

FOUND atlas selections use the same recovered cell drawing semantics proven by 05:

- lazy-load/cache texture from `ArtSelection.source.texture_path`;
- destination rectangle local to visible origin;
- source rectangle from `ArtSelection.region()`;
- `draw_texture_rect_region`;
- white modulation;
- transpose=false;
- clip_uv=true.

Valid future full-texture structure selections are supported through `draw_texture_rect`.

No texture path or atlas index is stored in WHAT or hardcoded into Structure renderer source.

## 12. Coordinates / visible window

WHAT positions remain authoritative global integer cells.

Destination rectangle is local to the supplied visible origin:

`(cell - visible_origin) * cell_pixels`

This supports large/negative persistent-world coordinates without giant CanvasItem coordinates.

Invalid non-positive visible dimensions or scale are rejected rather than replacing the last valid view.

## 13. Redraw / invalidation

There is no per-frame redraw polling.

Redraw is requested on:

- dependency configuration;
- view/window/cell-scale change;
- texture-cache clear;
- WHAT `world_reset`;
- visible structure placement/removal/entity removal changes;
- Door State enrollment/removal/change for a currently visible door;
- Door State reset.

No neighbor halo is required because current wall/opening art has no connectivity topology.

Terrain changes do not redraw Structure. Initial non-STRUCTURE object placement does not redraw Structure. Some removal/move events are conservatively redrawn when WHAT's mechanic-agnostic change record no longer contains enough prior-channel detail; correctness wins over hiding stale pixels.

## 14. Diagnostics / fail-visible rules

Visible diagnostic drawing covers:

- multiple STRUCTURE occupants at one cell;
- missing entity record referenced by occupancy;
- malformed/non-STRUCTURE placement;
- occupancy/placement mismatch;
- missing/invalid structure axis;
- unknown structure semantic category;
- unknown wall/door/window theme art;
- missing/UNKNOWN Door State;
- malformed/non-drawable `ArtSelection`;
- texture load failure.

The renderer never silently substitutes a generic wall, closed door, or default-looking structure for invalid content.

## 15. Performance / mobile

- visible cells only;
- no full-world structure scan;
- no per-frame polling;
- deterministic row-major cell traversal;
- stable ID ordering;
- cached textures;
- event-driven redraw;
- no input, hover, or Safari-specific interaction.

Future camera/streaming systems can change the supplied visible window without changing Structure semantics.

## 16. Verified acceptance

The first complete implementation head `2c69a98633b7a8bccfa64001921e0a6a19b36583` passed the dedicated **Structure Layer Renderer contract** under Godot 4.7.1 with no production repair required.

The dedicated contract proves:

- source-boundary isolation;
- project import/parse;
- Art Catalog regression remains green;
- Ground renderer regression remains green;
- Door State regression remains green;
- deterministic visible-only command order/count;
- local destination rectangles including negative global coordinates;
- recovered wall precedence;
- distinct explicit CLOSED/OPEN door art from Door State;
- missing Door State is diagnostic rather than default CLOSED;
- recovered themed window art;
- H/V structure axis retained in commands;
- current golden wall art does not swap solely by axis;
- missing axis diagnostic behavior;
- overlapping STRUCTURE occupants diagnostic behavior;
- unknown category/theme diagnostics;
- terrain and initial non-structure changes avoid unnecessary redraw;
- visible structure and Door State changes redraw;
- distant Door State changes do not redraw;
- resolved textures exist and load.

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
- rejected architecture: coordinate-keyed local dictionaries mixing walls/obstacles/glass/doors/collision.

## 18. Dependencies / forbidden boundaries

Allowed:

- WHAT public entity/placement/STRUCTURE occupancy reads + mechanic-agnostic change notifications;
- WHERE `SpatialLayer` and `SpatialStructureGeometry` vocabulary;
- 04 Art Catalog / ArtSelection;
- 06A Door State read/signaling contract;
- Godot Node2D/CanvasItem/ResourceLoader.

Forbidden:

- Door State writes/action internals;
- Collision and collision overrides as visual truth;
- WHEN;
- Movement / Actor Locomotion;
- generation/prefab dictionaries;
- reboot runtime;
- camera/input/UI;
- Ground/Prop/Actor renderer internals;
- lighting/perception/weather/sound.

## 19. Future seams

- Door Interaction later mutates Door State + Collision at an approved WHEN commit without renderer involvement.
- Window State may later add broken/open/barricaded presentation through an analogous typed read seam.
- Construction/destruction changes WHAT placements; Structure reacts through world changes.
- Tactical Renderer may orchestrate Ground + Structure + Prop + Actor layers without absorbing them.
- Lighting/perception may modulate/overlay later without becoming structure truth.
- Alternative art packs may add H/V variants while keeping canonical structure axis unchanged.

## 20. North-star fit

Walls, doors, and windows make houses/stores/farms physically readable and are essential to the persistent-world world presentation. Requiring real dynamic door state preserves the reduced-complexity survival consequence rule: the picture reflects persistent physical truth rather than a plausible placeholder.

## 21. Approved decisions

Approved and authorized by the user on 2026-08-16:

- standalone structure-only `Node2D`;
- visible WHAT STRUCTURE occupancy + Art Catalog + read-only Door State only;
- `wall.<theme>` / `door.<theme>` / `window.<theme>` semantic categories;
- explicit H/V axis required and retained;
- recovered art is not rotated solely by current axis;
- OPEN/CLOSED art comes only from canonical Door State;
- UNKNOWN door state is diagnostic;
- fail-visible invalid structure content;
- visible-window local coordinates and cached/event-driven drawing;
- no collision/WHEN/generator/reboot/camera/input ownership;
- implementing Door State and Structure in the same prompt was explicitly authorized with **“Program both”**.