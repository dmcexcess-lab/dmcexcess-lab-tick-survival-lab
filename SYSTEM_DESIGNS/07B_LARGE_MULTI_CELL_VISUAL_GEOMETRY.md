# Tick Survival Lab — System 07B Large / Multi-cell Object Visual Geometry

Status: **IMPLEMENTED + CI VERIFIED — Roadmap Phase 1D complete**

Approved: **2026-08-27**

Implemented: **2026-08-27**

Verified executable/workflow head: `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`

Permanent exact-head context: `verify/system07b-large-visual-geometry`

## 1. Core rule

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

System 07B is the presentation-only large-object child of System 07. It removes the old one-cell visual-size assumption while keeping WHAT / WHERE physical truth authoritative.

## 2. Implemented result

Candidate 001 implements:

- Node-free `PropVisualGeometryDescriptor` and `PropVisualGeometryCatalog` presentation contracts;
- authored whole-cell visual span and anchor-attached pivot;
- one stable entity -> one shared logical visual plan, regardless of physical footprint cell count;
- exact historical 1x1 fallback for unmapped props;
- System-07A facing/orientation applied to the complete authored geometry around its pivot;
- one cached visible-window-plus-halo planning pass shared by base and foreground drawing;
- a catalog-bounded maximum discovery halo of two cells for visual overhang from just-offscreen physical anchors;
- visual-AABB culling after bounded physical discovery;
- a persistent z=20 base/body pass plus optional z=35 foreground/overhang pass above actors and below physical lighting;
- dedicated 2x2 large deciduous-tree base + canopy artwork;
- dedicated larger traffic-light pole/base + signal-head/arm artwork;
- large traffic-light rotation derived from authoritative System-07A / WHAT facing;
- no per-object Sprite2D/Node2D/Timer/`_process` and no whole-world object scan.

## 3. Ownership

System 07B owns only presentation geometry:

- visual span;
- visual pivot;
- optional base/foreground art split;
- rotated visual bounds;
- bounded overhang discovery;
- cached visual planning and culling.

System 07B does **not** own:

- stable entity identity or persistence;
- WHAT placement;
- WHERE occupancy/footprints/collision;
- movement legality;
- System-29 reach or interaction legality;
- System-23 LOS/perception truth;
- System-27 physical light/shadow truth;
- System-26 sound;
- generation morphology;
- streaming identity;
- WHEN;
- vehicles or movable-object gameplay.

A canopy or signal arm drawn over a neighboring cell therefore does not make that cell physically occupied, blocked, reachable, opaque, illuminated or saved.

## 4. Public presentation contract

`PropVisualGeometryDescriptor` supplies presentation-only facts including:

- stable visual/catalog identity;
- base art key;
- optional foreground art key;
- positive whole-cell draw span;
- fractional pivot in unrotated visual-cell space.

The authoritative attachment point is the center of the WHAT anchor cell. The default descriptor is exactly one cell with pivot `(0.5, 0.5)`, preserving pre-07B destination geometry.

System 04 remains art-source/selection owner. System 07A remains facing owner. WHAT / WHERE remain physical owner.

## 5. Fixed presentation stack

Candidate 001 retains the existing fixed renderer architecture rather than introducing generic Y-sort:

1. ordinary props/base bodies — z=20;
2. living actors — z=30;
3. optional large-object foreground/overhang — z=35;
4. physical-lighting presentation — z=40;
5. later Weather / perception layers retain their existing ordering.

Examples:

- tree trunk/lower mass below actors, canopy above actors;
- traffic-light pole below actors, signal arm/head above actors.

Both passes consume the same stable-entity visual plan. Foreground presentation does not trigger a second WHAT discovery scan.

## 6. Bounded discovery and performance

Large art may overlap the camera even when its physical anchor is just outside visible bounds. System 07B therefore expands OBJECT discovery by the catalog's bounded maximum visual overhang, currently two cells, then culls plans whose rotated visual AABB does not actually intersect the visible rectangle.

Protected performance rules:

- no full-world scan;
- no per-frame world query merely for foreground composition;
- no per-entity runtime object graph;
- no WHEN work;
- static descriptors/art selections are cacheable;
- planning cost scales with the visible render window plus the tiny fixed halo, not total persistent world population;
- technical streaming-region dimensions do not define visual identity.

## 7. Physical-light glow enhancement included with Phase 1D

The approved implementation also improved the existing System-27 presentation shader with a broader soft two-ring bloom/glow.

Critical ownership rule:

> **Bright artwork may look emissive, but only a real System-27 emitter may create physical-light presentation glow.**

The traffic-light art contains readable bright signal lenses, but those pixels do not invent illumination. `physical_lighting_glow.gdshader` derives the expanded bloom from the existing physical-lighting presentation input. Streetlights, emergency lights, flashlights and future powered fixtures therefore reuse the same visual treatment only when real emitter truth exists.

No `TIME`-driven fake flicker, new light-source state, illumination calculation change, perception change or Power behavior was introduced.

## 8. Verification

`PropVisualGeometrySmoke.gd` plus protected regressions prove:

1. multi-cell physical occupancy deduplicates to one stable visual plan;
2. a one-cell physical object may legally own larger visual geometry without changing occupancy;
3. unmapped props retain exact one-cell fallback geometry;
4. pivots attach to the authoritative anchor-cell center;
5. System-07A quarter-turn orientation is presentation-only and deterministic;
6. offscreen physical anchors whose visual overhang intersects view are discovered through the bounded halo;
7. entities beyond the maximum halo are never found through an unbounded search;
8. base and foreground consume one shared planning/dedup result;
9. base/actor/foreground/lighting layer order is preserved;
10. visual geometry changes no collision, reach, LOS/perception truth or WHEN ticks;
11. existing prop-renderer, prop-orientation and physical-lighting presentation regressions remain green;
12. canonical project startup succeeds.

On exact head `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`, all **18 required contexts** are green:

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/system25-world-time-light`
- `verify/system26-spatial-sound`
- `verify/system27-physical-lighting`
- `verify/system28-weather`
- `verify/system29-interaction-affordance`
- `verify/system30-item-freshness`
- `verify/system31-semantic-ui-icons`
- `verify/system07b-large-visual-geometry`
- `verify/performance-architecture`
- `verify/pages-deploy`

The final workflow correction changed only the startup success assertion to the canonical `CANONICAL_DEMO_BOOT_OK` marker; the project was already booting successfully.

## 9. Human visual acceptance

Automated implementation/CI verification is complete. A separate human visual-acceptance claim for the new tree/traffic-light proportions and expanded glow is **not yet recorded**. Visual playtest may tune art while preserving this contract.

## 10. Future consumers

Roadmap Phase 1E may now deploy 07B geometry broadly for trees, traffic furniture and other approved static world objects. Future vehicles and final prop shadows may reuse this geometry seam, but remain independently owned later work.

Any future replacement must preserve authoritative WHAT / WHERE physical truth, one logical visual plan per stable object, System-07A orientation ownership, bounded visible-plus-halo discovery, no persistent presentation state in WHAT and no per-object runtime-object requirement.
