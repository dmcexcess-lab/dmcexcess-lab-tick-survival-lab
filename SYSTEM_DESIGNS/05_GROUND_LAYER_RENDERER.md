# Tick Survival Lab — 05 Ground Layer Renderer

Status: **IMPLEMENTED — canonical ground renderer and dedicated Godot CI contract present 2026-08-16**

Approval basis: after 04 recovered the canonical Art Catalog, the user requested the Ground Layer Renderer. The focused design was described in chat and the user replied **“Approved”**.

## 1. Goal

Render canonical WHAT terrain for a supplied visible global-cell window using the recovered 04 Art Catalog, while remaining independent from generation, camera/zoom ownership, structures, props, actors, simulation mechanics, and the frozen reboot runtime.

05 is the first canonical visual layer that turns persistent semantic terrain into actual CanvasItem drawing.

## 2. Owners

- `game/scripts/render/GroundDrawCommand.gd`
- `game/scripts/render/GroundLayerRenderer.gd`
- `game/scripts/ci/GroundLayerRendererSmoke.gd`
- `.github/workflows/ground-renderer.yml`

## 3. Non-goals / forbidden ownership

05 does not own structures/openings, props/vegetation, actors, camera/zoom, generation, road-network planning/classification, collision/traversal, WHEN, input/UI, lighting/perception/weather/sound, tactical orchestration, or reboot compatibility.

Production Ground renderer source contains no preserved texture paths or atlas indices. Those remain owned by 04 Art Catalog.

## 4. Public contract

`GroundLayerRenderer` is a standalone `Node2D`.

Dependencies are injected explicitly:

- read-only canonical `WorldState` terrain truth;
- canonical `ArtCatalog` semantic-to-art selection.

View state is supplied explicitly:

- global top-left visible cell;
- visible whole-cell width/height;
- positive display cell size in pixels.

`plan_visible_commands()` returns deterministic row-major `GroundDrawCommand` values. Each command contains the global cell, destination rectangle local to the visible origin, semantic terrain ID, and copied `ArtSelection`.

Invalid non-positive view dimensions/cell scale are rejected without replacing the last valid view.

## 5. Data ownership

The renderer owns only ephemeral presentation state:

- visible window and display cell size;
- lazy texture cache;
- bounded diagnostic reason set.

It mutates no simulation/world/art state.

## 6. Coordinate rule

WHAT coordinates remain global integer cells. Destination rectangles are local:

`(cell - visible_origin) * cell_pixels`.

This permits large/negative global coordinates without requiring giant CanvasItem coordinates.

## 7. Ground selection

Ordinary terrain delegates to `ArtCatalog.resolve_ground()` and therefore inherits 04 precedence.

Contextual generic terrain:

- `road` -> `resolve_road(cardinal_mask, local)`;
- `dirt_road` -> `resolve_dirt_road(cardinal_mask)`;
- `sidewalk` -> `resolve_sidewalk(adjacent_road_mask)`.

Explicit recovered variants such as `road_ne`, `road_h`, `road_cross`, `dirt_road_h`, etc. remain literal Art Catalog requests and are not recomputed.

## 8. Road topology rule

Generic paved and dirt road cells share one cardinal connectivity family, recovering the useful golden road-cell behavior without restoring generator dictionaries.

Road-like neighbors are limited to generic road/dirt-road semantics and explicit recovered road/dirt-road topology variants. Asphalt/concrete/paint-marking surfaces are not guessed to be roads.

Missing/unmaterialized neighbor terrain contributes no connection. A later terrain materialization/change triggers the normal halo invalidation path.

05 does not invent arterial/local/trail truth. Generic paved roads use local/default Art Catalog topology until a future canonical Road Network system owns richer road metadata.

## 9. Drawing behavior

For a FOUND atlas selection, `GroundLayerRenderer` lazily loads/caches the supplied source texture and draws with:

- `draw_texture_rect_region`;
- destination from the command;
- `ArtSelection.region()` source rectangle;
- white modulation;
- transpose=false;
- clip_uv=true.

These flags recover the golden `TacticalTiles.gd` ground draw behavior.

A valid future full-texture ground selection is supported through `draw_texture_rect` without changing WHAT.

## 10. Diagnostics

Missing WHAT terrain, UNKNOWN art, malformed/non-drawable selection, and texture-load failure render an obvious diagnostic cell rather than silently substituting plausible terrain.

Diagnostic reasons are bounded to 64 unique strings and are presentation-only.

## 11. Redraw/invalidation

There is no `_process()` redraw loop.

Redraw is requested on:

- dependency configuration;
- visible-window/cell-scale change;
- explicit texture-cache clear;
- WHAT `world_reset`;
- WHAT `TERRAIN_SET` / `TERRAIN_REMOVED` inside the visible window;
- those terrain changes in the one-cell **cardinal** topology halo immediately beyond the visible edges.

Diagonal-only offscreen changes and non-terrain WHAT changes do not redraw this layer.

## 12. Performance/mobile

- visible cells only;
- no full-world scan;
- no per-frame polling;
- deterministic row-major planning;
- cached textures;
- bounded event-driven invalidation;
- no input/hover/Safari behavior in the renderer.

Future camera/streaming systems may change the supplied window without changing Ground semantics.

## 13. Recovery source

Golden recovery commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Golden `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Recovered facts:

- atlas regions stretched into destination cells;
- transpose=false / clip_uv=true;
- cardinal road connectivity;
- paved/dirt ground shared the road network;
- sidewalk curb used only when exactly one adjacent road existed.

The golden generator `spec`, road dictionaries, and monolithic draw helper were not restored.

## 14. Verified acceptance

The first complete implementation head `0b1460a89140d0a9d84478c9300dacb84d991a11` passed the dedicated **Ground Layer Renderer contract** under Godot 4.7.1 with no production repair required.

The dedicated contract proves:

- source-boundary isolation;
- project import/parse;
- 04 Art Catalog regression remains green;
- visible-only deterministic command count/order;
- negative global coordinates and local destination rectangles;
- recovered ground precedence;
- road endpoints, straights, corners, T intersections and crossroads;
- paved/dirt shared connectivity;
- horizontal/vertical/mixed dirt-road selection;
- sidewalk curb/plain selection;
- explicit topology variants remain literal;
- missing/unknown terrain is diagnostic;
- resolved textures exist/load;
- non-terrain/distant/diagonal changes do not redraw;
- visible/cardinal-halo terrain, world reset, and view changes do redraw.

## 15. Future seams

- Tactical camera/viewport supplies visible origin/size/scale.
- Future Road Network may provide approved road-class metadata without exposing generator dictionaries.
- Future Tactical Renderer may orchestrate Ground + Structure + Prop + Actor layers without absorbing their internals.
- Lighting/perception/weather remain overlays/modulators, not Ground truth.
- Streaming/materialization may change WHAT availability without changing coordinate semantics.

## 16. North-star fit

This is the smallest real visible layer turning persistent open-world WHAT truth into the recovered readable Ultima-style art. It keeps rendering replaceable and refuses to make generator state, art indices, or physics into presentation truth.

## 17. Approved decisions

Approved 2026-08-16:

- standalone Node2D ground presentation owner;
- canonical WHAT terrain + 04 Art Catalog only;
- supplied visible global-cell window;
- local destination coordinates;
- no per-frame redraw loop;
- cardinal one-cell topology halo invalidation;
- generic road/dirt-road/sidewalk topology from semantic neighbors;
- paved/dirt roads share connectivity;
- explicit variants remain literal;
- default/local road class until a real Road system owns classification;
- visible diagnostics instead of silent terrain substitution;
- lazy/cached texture loading from ArtSelection descriptors;
- preserved art untouched;
- no deprecated reboot wiring.
