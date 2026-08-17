# Tick Survival Lab — 05 Ground Layer Renderer

Status: **APPROVED — implementation authorized by the user on 2026-08-16**

Approval basis: after 04 recovered the canonical Art Catalog, the user requested the Ground Layer Renderer. The focused design was described in chat and the user replied **“Approved”**.

## 1. Goal

Render canonical WHAT terrain for a supplied visible global-cell window using the recovered 04 Art Catalog, while remaining independent from generation, camera/zoom ownership, structures, props, actors, simulation mechanics, and the frozen reboot runtime.

This is the first canonical visual layer that turns persistent semantic terrain into actual CanvasItem drawing.

## 2. Non-goals

05 does not own or implement:

- structures, walls, doors or windows;
- props, fixtures, vegetation or loose items;
- actors/player sprites;
- camera position, zoom selection or visible-window calculation;
- procedural generation or authored-world creation;
- road-network planning/classification;
- collision, traversal or other physics;
- vision/perception, lighting, weather or sound;
- input/UI;
- tactical renderer orchestration;
- wiring into deprecated `game/scripts/reboot/`.

## 3. Owners

- `game/scripts/render/GroundDrawCommand.gd`
- `game/scripts/render/GroundLayerRenderer.gd`
- `game/scripts/ci/GroundLayerRendererSmoke.gd`
- `.github/workflows/ground-renderer.yml`

## 4. Public contract

`GroundLayerRenderer` is a standalone `Node2D` presentation owner.

It receives dependencies explicitly:

- canonical `WorldState` as read-only terrain truth;
- canonical `ArtCatalog` for semantic-to-art selection.

It receives view state explicitly from a future camera/viewport owner:

- global top-left visible cell;
- visible width/height in whole cells;
- positive display cell size in pixels.

It exposes deterministic planning for the current visible window as an ordered array of `GroundDrawCommand` values. Commands contain:

- global cell;
- destination rectangle local to the supplied visible-window origin;
- semantic terrain ID;
- resolved `ArtSelection` or explicit diagnostic UNKNOWN selection.

The renderer owns texture loading/caching and CanvasItem drawing from those commands.

## 5. Data ownership

The renderer owns only ephemeral presentation state:

- current visible-cell window;
- current display cell size;
- texture cache;
- bounded diagnostic bookkeeping.

It mutates no WHAT, WHERE, WHEN, collision, movement, actor, generation or art-catalog state.

## 6. Allowed dependencies

Allowed:

- `WorldState` read methods `has_terrain(cell)` / `terrain_at(cell)`;
- `WorldState.changed` / `world_reset` notifications;
- typed `WorldChange` terrain change vocabulary;
- `ArtCatalog` and `ArtSelection`;
- Godot CanvasItem/Node2D drawing and `ResourceLoader`.

## 7. Forbidden dependencies

Production `game/scripts/render/Ground*` source must not import or inspect:

- `game/scripts/reboot/`;
- generation modules or generator dictionaries/specs;
- collision or movement;
- actor locomotion/capability;
- WHEN/tick kernel;
- camera/zoom internals;
- input/UI;
- structure/prop/actor renderers;
- lighting/perception/weather/sound.

It must not contain atlas indices or preserved texture paths. Those belong to 04 Art Catalog selections.

## 8. Visible window and coordinates

WHAT coordinates remain authoritative global integer cells.

The renderer draws only the explicitly supplied visible window. A global cell `(x, y)` maps to local destination position:

`(cell - visible_origin) * cell_pixels`.

This keeps CanvasItem coordinates local even when global world coordinates become very large or negative.

Commands are generated deterministically in row-major order: top-to-bottom, left-to-right.

A view with non-positive dimensions or non-positive cell size is invalid and must be rejected rather than silently drawing nonsense.

## 9. Ground art selection

Ordinary semantic terrain delegates directly to `ArtCatalog.resolve_ground(semantic_id)` and therefore preserves 04 precedence.

Three generic semantic terrain families receive contextual topology selection:

- `ground.road` / leaf token `road` -> `ArtCatalog.resolve_road(mask, &"local")`;
- `ground.dirt_road` / leaf token `dirt_road` -> `ArtCatalog.resolve_dirt_road(mask)`;
- `ground.sidewalk` / leaf token `sidewalk` -> `ArtCatalog.resolve_sidewalk(touching_road_mask)`.

Explicit authored topology/surface variants such as `ground.road_ne`, `ground.road_h`, `ground.kitchen_tile`, etc. remain literal Art Catalog requests and are not overwritten by contextual selection.

## 10. Local road topology recovery

For generic road/dirt-road/sidewalk terrain, the renderer derives cardinal N/E/S/W connectivity only from neighboring canonical semantic terrain.

Paved and dirt roads participate in one connected road-neighbor family, matching the useful golden behavior where a separate road-cell set carried both paved and dirt road cells.

Road-like neighbors for this bounded slice are the generic road/dirt-road semantics and the explicitly recovered road/dirt-road topology variants. The renderer does not treat arbitrary asphalt/concrete/road-marking surfaces as roads merely because they visually resemble a road.

Missing/unmaterialized neighbor terrain simply contributes no connection. If that neighbor materializes later, the normal terrain change notification invalidates the visible topology through the one-cell halo rule below.

### Road class

05 does **not** invent arterial/local/trail classification. Canonical WHAT currently has no road-class domain. Generic paved roads therefore use Art Catalog's normal/local topology behavior.

A future Road Network/Topology system may provide richer semantic road metadata through a separately approved seam. Generator-specific dictionaries must never become the renderer's source of truth.

## 11. Drawing behavior

For a FOUND atlas selection:

- load/cache the texture from the ArtSelection source descriptor;
- draw with `draw_texture_rect_region` into the command destination rectangle;
- use the `ArtSelection.region()` source rectangle;
- preserve the golden draw flags: no transpose, clipping enabled.

If a future valid ground selection is a full texture rather than an atlas region, the renderer may draw it with `draw_texture_rect` using the same destination rectangle without moving source knowledge into WHAT.

The preserved art assets remain untouched.

## 12. Unknown/missing diagnostics

Missing WHAT terrain and Art Catalog UNKNOWN results are visible presentation failures, not silent substitutions.

The renderer draws an obvious diagnostic tile for that destination and records a bounded diagnostic reason. It does not silently replace missing/unknown ground with grass, asphalt, concrete or another plausible surface.

Diagnostic presentation changes no simulation truth.

## 13. Invalidation / redraw rules

The renderer has no `_process()` redraw loop.

A redraw is requested when:

- dependencies are configured/reconfigured;
- the visible window or display cell size changes;
- WHAT emits `world_reset`;
- WHAT emits `TERRAIN_SET` or `TERRAIN_REMOVED` for a cell inside the visible window or its one-cell cardinal/topology halo.

Non-terrain WHAT changes do not redraw the Ground layer.

The one-cell halo is required because changing a just-offscreen road cell can change the topology sprite of an onscreen boundary road/sidewalk cell.

## 14. Texture cache

Textures are loaded lazily from `ArtSelection.source.texture_path` and cached by path for reuse.

The cache is presentation-only and may be cleared explicitly or on dependency reset. It owns no source paths beyond those supplied by the Art Catalog.

A failed texture load produces a diagnostic draw rather than a silent omission.

## 15. Performance / mobile

- iterate only supplied visible cells;
- no full-world scan;
- no per-frame polling/redraw;
- row-major deterministic command generation;
- cached texture resources;
- terrain events redraw only when they affect visible/topology-relevant cells;
- no hover, input, or Safari-specific behavior belongs in this renderer.

This is compatible with phone/Safari because future camera/input systems can change the visible window without changing renderer mechanics.

## 16. Failure cases / edge cases

Must handle:

- negative global coordinates;
- missing terrain inside the visible window;
- unknown semantic ground IDs;
- invalid view dimensions/cell size;
- road endpoints, straights, corners, T intersections and crossroads;
- mixed paved/dirt road adjacency;
- dirt-road horizontal/vertical/mixed selection;
- sidewalk with zero, one, or multiple adjacent road cells;
- terrain changes just outside the visible window;
- world reset;
- texture load failure.

## 17. Verification / acceptance

Dedicated Godot 4.7.1 CI must prove:

- production source boundary guards;
- project import/parse;
- deterministic visible-window command count/order;
- destination rectangles relative to visible origin;
- negative global coordinates;
- ordinary Art Catalog precedence through real semantic IDs;
- road straight/corner/T/cross/end behavior;
- paved/dirt road shared connectivity;
- dirt-road orientation;
- sidewalk curb selection;
- explicit topology variants remain literal;
- missing and unknown terrain become diagnostics;
- texture paths used by found commands exist/load;
- non-terrain WHAT changes do not request redraw;
- visible/halo terrain changes do request redraw;
- distant terrain changes do not request redraw;
- world reset/view change requests redraw;
- 04 Art Catalog regression smoke remains green.

## 18. Recovery source

Golden recovery commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Golden `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Recovered draw facts used by 05:

- 32px source atlas regions were stretched to destination cell rectangles;
- `draw_texture_rect_region` used transpose=false and clip_uv=true;
- road connectivity was cardinal;
- paved/dirt ground shared the road-cell network;
- sidewalk used a curb variant only when exactly one adjacent road existed.

The golden generator `spec`, road dictionaries and monolithic draw helper are not restored.

## 19. Future seams

Future consumers/extensions:

- Tactical camera/viewport owner supplies the visible global-cell window and display scale;
- future Road Network may provide explicit road class/topology metadata through an approved presentation seam;
- a Tactical Renderer may orchestrate Ground + Structure + Prop + Actor layers without absorbing their internals;
- lighting/perception/weather may overlay or modulate presentation later without moving simulation truth into Ground;
- streaming/materialization can change available WHAT terrain without changing renderer coordinate semantics.

## 20. North-star fit

This is the smallest real visible layer that turns the persistent open-world WHAT truth into the recovered readable Ultima-style art. It preserves mood/readability while keeping rendering replaceable and refusing to make generator state, art indices or physics into presentation truth.

## 21. Approved decisions

Approved 2026-08-16:

- Ground Renderer is a standalone Node2D presentation system;
- reads canonical WHAT terrain and 04 Art Catalog only;
- draws only a supplied visible global-cell window;
- destination coordinates are local to the visible origin;
- no `_process()` full-scene redraw loop;
- terrain event invalidation includes a one-cell topology halo;
- generic road/dirt-road/sidewalk topology is derived from neighboring semantic terrain;
- paved and dirt roads share connectivity;
- explicit authored topology variants stay literal;
- generic road class is local/default until a real Road system owns classification;
- missing/unknown art is visibly diagnostic, never silently substituted;
- texture loading is lazy/cached from ArtSelection descriptors;
- do not touch preserved art or wire into deprecated reboot code.
