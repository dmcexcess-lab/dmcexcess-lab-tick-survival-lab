# Tick Survival Lab — System 07B Large / Multi-cell Object Visual Geometry

Status: **DRAFT — awaiting approval; Roadmap Phase 1D**

Updated: **2026-08-27**

## 1. Goal

System 07B extends the existing System 07 prop / fixture / vegetation presentation so a stable physical entity may have an authored visual span, pivot and decorative overhang that differ from its authoritative WHAT / WHERE footprint.

Core rule:

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

Candidate 001 is deliberately a child of System 07 rather than a new top-level gameplay system. System 07 already owns one-command-per-stable-object prop rendering, and System 07A already owns presentation-only facing/orientation. System 07B removes the remaining one-cell visual assumption without creating a second object renderer or a second spatial truth.

## 2. Problem being solved

The current `PropLayerRenderer` already does the important physical work correctly:

- it queries WHAT OBJECT occupancy;
- deduplicates multi-cell occupancy by stable entity ID;
- retains the authoritative footprint and anchor;
- emits one draw command per stable entity;
- does not repeat one icon on every occupied cell.

The remaining limitation is presentation: every command is currently drawn into exactly one tactical cell at the entity anchor, even when the physical footprint contains multiple cells.

That makes a double bed, large tree, traffic signal, large machine, future vehicle, etc. visually collapse into a one-cell icon despite having larger physical or decorative geometry.

System 07B replaces only that visual-size assumption.

## 3. Ownership

### System 07B owns

- presentation-only visual geometry descriptors for OBJECT-channel semantics;
- visual draw span in tactical-cell space;
- the visual pivot that attaches authored art to the authoritative anchor cell;
- optional decorative visual overhang outside the physical footprint;
- bounded discovery of objects whose visual overhang enters the current view while their physical footprint is just outside it;
- one shared cached visual-plan list consumed by the ordinary prop pass and optional foreground-overhang pass;
- visual-bounds intersection/culling;
- applying System 07A's already-resolved orientation around the authored visual pivot.

### System 07B does not own

- entity identity or persistence;
- WHAT placement;
- WHERE footprints, occupancy or collision;
- movement legality;
- System 29 reach / interaction legality;
- System 23 LOS, visibility state or memory;
- System 27 physical light / shadow truth;
- System 26 sound;
- generation choice of physical footprint;
- streaming identity or technical region size;
- WHEN;
- vehicles or movable-object gameplay;
- final prop-shadow art.

A visual canopy over a neighboring cell therefore does **not** make that cell blocked, reachable, interactable, opaque, illuminated, audible, saved, or occupied.

## 4. Relationship to existing systems

### System 07 — Prop / Fixture / Vegetation Renderer

System 07 remains the renderer owner. Candidate 001 should evolve the existing `PropLayerRenderer` rather than replace it.

The existing invariant remains:

> **One stable OBJECT entity produces one logical visual plan, regardless of how many physical cells it occupies.**

System 07B does not authorize one Sprite/Node per entity and does not authorize one copied icon per occupied cell.

### System 07A — Prop Art Orientation

System 07A remains the facing/orientation owner.

System 07B consumes the resolved quarter-turn/orientation and applies it to the complete authored visual geometry around the descriptor pivot. System 07B must not invent another facing field or store presentation rotation in WHAT.

### System 04 — Art Catalog

System 04 remains the art-selection/source owner.

System 07B may map a physical semantic type to presentation-only art keys for:

- a base/body visual;
- an optional foreground/overhang visual.

Those keys are presentation identifiers only. They are never written into WHAT as semantic identity.

Candidate 001 may add a dedicated large-environment-prop source/texture through System 04. `ArtSelection` already supports full-texture sources, so Candidate 001 does not require arbitrary multi-cell atlas-rectangle semantics merely to draw large assets.

### Systems 00A / 00B — WHERE / WHAT

Authoritative placement remains `record.footprint.anchor`, `record.footprint`, channel and facing.

Visual geometry is derived after reading those facts. No save-schema or persistent-record field is added for visual span or pivot.

## 5. Candidate 001 data contract

Add a Node-free presentation descriptor such as `PropVisualGeometryDescriptor` and a shared `PropVisualGeometryCatalog`.

A descriptor contains at minimum:

- `visual_id: StringName` — stable presentation/catalog identity;
- `base_art_key: StringName` — System-04-resolved base/body artwork;
- `foreground_art_key: StringName` — optional System-04-resolved transparent foreground/overhang artwork; empty means no foreground pass;
- `draw_span_cells: Vector2i` — positive authored visual width/height in tactical cells;
- `pivot_cells: Vector2` — point inside the unrotated visual rectangle that is attached to the authoritative anchor-cell center.

Candidate 001 keeps `draw_span_cells` on whole-cell dimensions. This preserves the deliberate low-resolution tile language and simple nearest-neighbor scaling. The pivot may be fractional so a wide/tall object can attach naturally to one anchor location.

Validation requires:

- both span components >= 1;
- pivot is finite;
- required base art resolves;
- optional foreground art resolves if declared;
- the default/fallback descriptor is exactly one cell with pivot `(0.5, 0.5)`.

The catalog is static during normal Candidate-001 runtime. It is not a mutable gameplay registry.

## 6. Placement math

The authoritative attachment point is the **center of the WHAT anchor cell**.

For an unrotated visual:

`anchor_world = Vector2(anchor_cell) + Vector2(0.5, 0.5)`

`visual_top_left_world = anchor_world - pivot_cells`

`visual_rect_world = Rect2(visual_top_left_world, Vector2(draw_span_cells))`

The renderer converts that world-space rectangle into screen/local pixels using the existing render-window origin and cell-pixel size.

The default descriptor `(span=1×1, pivot=0.5,0.5)` must produce the current one-cell destination exactly. Existing unmapped props therefore remain visually unchanged.

## 7. Orientation and rotated bounds

System 07A supplies the resolved orientation. System 07B rotates visual geometry around `pivot_cells`, not around the rectangle center unless the authored pivot happens to be centered.

For each allowed quarter-turn:

- the attachment point remains the authoritative anchor-cell center;
- base and foreground parts receive the same orientation;
- physical footprint/facing truth is read-only;
- the visual axis-aligned bounding box is computed from the rotated authored rectangle for culling/discovery.

Four quarter-turns must return to identical visual geometry with no accumulated floating-point drift in the logical plan.

## 8. Base + foreground presentation passes

A single large image rendered entirely below actors makes tall objects look wrong: the survivor would always appear in front of a tree canopy or traffic-signal head. Moving every prop above actors causes the opposite problem.

Candidate 001 therefore uses **two fixed presentation passes fed by one shared visual plan**:

1. **Base/body pass — z=20**
   - existing System-07 prop layer;
   - below doors/actors as today;
   - draws the descriptor's base art.

2. **Optional foreground/overhang pass — z=35**
   - one additional persistent renderer surface, not one Node per object;
   - above living actors at z=30;
   - below physical lighting at z=40, Weather at z=50 and Perception at z=100;
   - draws only the descriptor's optional transparent foreground art.

Examples:

- large tree base art: trunk/lower mass; foreground art: upper canopy;
- traffic light base art: pole/base; foreground art: signal head/cross-arm;
- dumpster or bed: base only, with no foreground layer if no actor-overlap effect is desired.

This is not a generic Y-sort rewrite. Candidate 001 deliberately retains the existing fixed renderer stack.

## 9. One logical visual plan per stable entity

The roadmap's one-command-per-entity rule means System 07B must never multiply drawing by physical footprint cells.

Candidate 001 may represent one stable entity's plan with a base draw plus an optional foreground subpass, but both parts belong to the **same stable visual plan and the same entity ID**. Planning/deduplication happens once.

No second WHAT query or entity-discovery scan is permitted merely for the foreground pass.

Stable ordering remains deterministic from physical anchor / semantic / stable entity ID unless a later approved design proves another ordering key is necessary.

## 10. Visual-overhang discovery halo

Current System 07 discovers objects by scanning physical occupancy inside the visible bounds. That is insufficient once visual art may extend beyond physical occupancy: an offscreen tree trunk could have a canopy that should still be visible onscreen.

Candidate 001 adds a **catalog-bounded discovery halo**.

Rules:

- `PropVisualGeometryCatalog` exposes the maximum possible rotated visual overhang in cells across its registered descriptors;
- the renderer expands the current physical query rectangle only by that small maximum halo;
- discovery still uses direct WHAT `entities_at()` occupancy queries and stable-ID deduplication;
- after a visual plan is built, its rotated visual AABB must intersect the actual visible rectangle or it is culled;
- no full-world scan is allowed;
- changing the 128×128 technical streaming region size must not change visual identity or geometry.

Candidate 001's first assets should keep the maximum halo deliberately small. A 1–2-cell halo is the intended scale; unusually huge artwork requires a later explicit review rather than silently expanding query cost.

## 11. Caching and invalidation

System 07B follows the performance north star.

Candidate 001 requirements:

- no per-entity Node/Sprite/Timer/`_process`;
- no WHEN work;
- no per-frame world scan;
- one cached planned-command list for the visible window + bounded halo;
- base and foreground passes consume that same cache;
- ordinary render-window movement and relevant OBJECT placement/reset changes invalidate the plan through the existing System-07 pathway;
- static visual descriptors/art selections may be cached;
- actor movement does not require a prop-world requery merely because a foreground overlay is composited above the actor.

Planning cost is bounded by visible-window-plus-halo OBJECT occupancy, not total persistent world population.

## 12. First implementation examples

Candidate 001 implementation should prove the contract with at least:

### Large tree

- a real stable vegetation semantic such as `vegetation.deciduous_large`;
- authored visual geometry of at least 2×2 cells;
- visual pivot attached to the physical anchor;
- optional canopy foreground part above actors;
- a focused fixture proving a 2×2 physical footprint still yields one stable visual plan.

### Traffic / stop light

- an existing traffic-light / traffic-furniture semantic;
- authored visual geometry visibly larger/taller than one cell;
- pole/base below actors and optional signal head/arm above actors;
- orientation driven by System 07A/WHAT facing, not a renderer-only second facing state.

The implementation may add focused test fixtures with the required physical footprints. Globally changing generator collision footprints for existing content is **not** part of System 07B and should be deferred to content integration unless already-authoritative footprint data supports it.

## 13. Verification contract

A dedicated `verify/system07b-large-visual-geometry` context should prove at minimum:

1. A 2×2/four-cell WHAT footprint produces one stable visual plan rather than four repeated sprites.
2. A one-cell physical footprint may legally have a larger visual rectangle without changing occupancy/collision.
3. An unmapped/default prop produces the exact historical one-cell destination rectangle.
4. The authored pivot lands on the anchor-cell center.
5. System-07A quarter-turns rotate around the authored pivot and preserve WHAT placement/footprint.
6. Four quarter-turns return to the original logical geometry deterministically.
7. An entity whose entire physical footprint is just outside view is still planned when its visual AABB overlaps the view.
8. An entity outside the catalog maximum halo is not discovered by an unbounded search.
9. Halo-discovered plans whose visual AABB does not intersect the real view are culled.
10. Base and optional foreground passes use one shared stable-entity plan/dedup result.
11. Base remains below actors; foreground remains above actors and below physical lighting/perception.
12. Visual overhang changes no WHERE occupancy, collision, System-29 reach, System-23 acquisition truth or WHEN ticks.
13. Existing `PropLayerRendererSmoke`, System-07A orientation smoke, canonical startup and performance-architecture regressions remain green.
14. The exact executable head passes all existing required contexts plus the new System-07B context and Pages deployment.

## 14. Phone / browser presentation constraints

Phone/Safari remains first-class.

Candidate 001 therefore keeps:

- integer cell draw spans;
- nearest/low-resolution presentation conventions;
- no per-object scene-tree proliferation;
- bounded halo queries;
- cached art selections/textures;
- no continuous animation requirement.

Large art must improve readability without turning the screen into high-resolution decorative clutter that hides tactical cells.

## 15. Explicit non-goals for Candidate 001

Not authorized by this design:

- changing collision or physical footprints merely to match artwork;
- generic isometric/Y-sort/world-depth renderer replacement;
- per-object Sprite2D/Node2D instances;
- animated vegetation or prop simulation;
- physical prop shadows or changes to System 27 light truth;
- arbitrary visual hitboxes used for gameplay;
- interaction selection by visible sprite pixels;
- vehicle movement/rotation/damage;
- broad world-content expansion;
- final graphics/UI polish.

Phase 1E may consume the approved 07B seam for broader trees, traffic furniture, fixtures and ordinary world-object content. Vehicles and final prop shadows may reuse the same presentation geometry later but remain independently owned work.

## 16. Replacement boundary

A future System-07/07B renderer rewrite is acceptable if it preserves:

- authoritative WHAT / WHERE footprint and stable entity identity;
- one logical visual plan per stable OBJECT entity;
- semantic Art-Catalog resolution;
- System-07A orientation ownership;
- authored span/pivot/overhang semantics;
- bounded visible-plus-halo discovery;
- no persistent visual state in WHAT;
- no WHEN cost;
- no per-entity runtime-object requirement.

## 17. Approval gate

This document completes the **DESCRIBE** stage only.

No System-07B runtime implementation is authorized until the user approves this design. On approval, implementation should remain bounded to the presentation/art/verification seams described above, with protected gameplay/world systems treated as regressions rather than refactor targets.
