# Tick Survival Lab — 07 Prop / Fixture / Vegetation Renderer

Status: **IMPLEMENTED — canonical Prop/Fixture/Vegetation renderer and dedicated Godot CI contract present 2026-08-16**

Approval basis: after a full repository/North-Star refresh, the user requested the Prop renderer. The focused DRAFT recovered golden prop behavior and preserved current WHAT facing/footprint facts without inventing art geometry. The user explicitly approved that contract with **“Approved”** on 2026-08-16.

## 1. Goal

Render visible canonical WHAT `OBJECT` entities representing props, fixtures, and vegetation through the recovered 04 Art Catalog while preserving stable WHAT identity, WHERE placement/facing/footprint facts, and strict presentation/simulation separation.

07 restores the mature multi-atlas prop vocabulary without making rendering own physics, gameplay state, generation, inventory, camera, input, or the frozen reboot runtime.

## 2. Recovery source

Golden recovery baseline:

- commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`
- golden `TacticalTiles.gd` blob `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Recovered golden facts:

- prop precedence was final exact -> final alias -> building -> clutter -> tactical;
- one 32x32 atlas region was drawn into one supplied rectangle;
- prop drawing defined no facing/orientation transform;
- golden code had no multi-cell visual-geometry model.

04 Art Catalog already owns the exact recovered mappings and intentionally returns typed UNKNOWN instead of the old silent crate fallback for missing prop IDs.

## 3. Owners

- `game/scripts/render/PropDrawCommand.gd`
- `game/scripts/render/PropLayerRenderer.gd`
- `game/scripts/ci/PropLayerRendererSmoke.gd`
- `.github/workflows/prop-renderer.yml`

No new simulation domain is owned by 07.

## 4. Public contract

`PropLayerRenderer` is a standalone `Node2D`.

Injected dependencies:

- canonical `WorldState` read/query contract;
- canonical `ArtCatalog` descriptor contract.

Public surface:

- `configure(world_state, art_catalog) -> bool`
- `is_configured() -> bool`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `has_valid_view() -> bool`
- `visible_origin()` / `visible_size()` / `cell_pixels()`
- `plan_visible_commands() -> Array[PropDrawCommand]`
- `clear_texture_cache()`
- `diagnostic_reasons()`
- presentation-only `redraw_requested(reason)` signal.

The visible-window seam matches Ground and Structure: global top-left cell, positive whole-cell dimensions, and positive display cell size.

## 5. Semantic families

07 recognizes exactly these WHAT `OBJECT` semantic families:

- `prop.<kind>`
- `fixture.<kind>`
- `vegetation.<kind>`

All delegate to `ArtCatalog.resolve_prop(entity.semantic_type)`. Art Catalog leaf-token normalization owns the recovered vocabulary.

Examples include `prop.utility_pole`, `fixture.kitchen_sink`, and `vegetation.deciduous_large`.

These prefixes classify presentation content only. They imply no collision, interaction, inventory, power, opacity, growth, searchability, or destructibility.

## 6. Discovery and deterministic ordering

The renderer scans only the supplied visible window using:

`WorldState.entities_at(cell, SpatialLayer.Channel.OBJECT)`

Multi-cell occupancy is deduplicated by stable entity ID. Each visible/intersecting entity creates at most one command.

Commands sort deterministically by:

1. placement anchor Y;
2. placement anchor X;
3. stable entity ID.

WHAT may contain overlapping OBJECT entities. 07 draws them in deterministic order rather than treating overlap as a renderer-owned collision error.

## 7. PropDrawCommand

Each command retains:

- stable entity ID;
- semantic type;
- family (`prop` / `fixture` / `vegetation` / `unknown`);
- placement anchor;
- canonical N/E/S/W facing;
- copied whole-cell footprint;
- copied rotated world-cell list;
- local destination rectangle;
- copied `ArtSelection` or explicit UNKNOWN diagnostic selection.

The command contains no simulation mutation or camera ownership.

## 8. Multi-cell physical footprint versus visual geometry

The physical WHAT/WHERE footprint remains authoritative world geometry.

Current recovered prop sources are one-cell atlas regions and golden `draw_prop()` drew one region into one rectangle. Therefore 07 draws **one cell-sized sprite at the entity anchor**, even if the physical entity occupies multiple cells.

It does not:

- repeat one icon across every occupied cell;
- stretch one cell of art over an arbitrary physical footprint;
- change the WHAT footprint to fit the picture.

An object counts as visible when any rotated footprint cell intersects the visible window. Its anchor may be outside the window; the command still keeps the true anchor-local destination and normal viewport clipping handles the result.

Future large-object art belongs in a presentation-owned visual-geometry/anchor descriptor, not in physical WHAT geometry.

## 9. Facing/orientation

WHAT facing is authoritative and preserved in every command.

Current recovered prop art is deliberately drawn unrotated because golden prop drawing defined no native facing or rotation convention. The renderer does not guess visual orientation from semantic names.

Future art may add presentation-only orientation metadata such as native facing, rotatable flag, or directional variants while consuming the already-preserved WHAT facing.

## 10. Art resolution

Recognized objects call:

`ArtCatalog.resolve_prop(entity.semantic_type)`

This preserves:

1. final prop exact;
2. final prop alias;
3. building prop;
4. clutter prop;
5. tactical prop.

The recovered tactical barrel special case remains owned by Art Catalog. Unknown kinds remain typed UNKNOWN and draw diagnostically; no crate/tree/chair fallback is invented.

## 11. Drawing behavior

FOUND atlas selections use the same recovered drawing semantics proven by Ground and Structure:

- lazy/cached texture from `ArtSelection.source.texture_path`;
- one-cell destination at the placement anchor relative to visible origin;
- source rectangle from `ArtSelection.region()`;
- `draw_texture_rect_region`;
- white modulation;
- transpose=false;
- clip_uv=true.

Valid future full-texture selections use `draw_texture_rect`.

The renderer contains no hardcoded atlas paths, source-family switches, or atlas indices.

## 12. Redraw/invalidation

There is no `_process()` redraw loop.

Redraw occurs for:

- dependency configuration;
- view/cell-scale change;
- texture-cache clear;
- WHAT `world_reset`;
- visible/relevant OBJECT placement set/removal;
- visible entity removal where WHAT's mechanic-agnostic before-cells require conservative redraw.

Terrain changes and initial clearly non-OBJECT placement do not redraw Prop. No neighbor halo exists because current prop art has no connectivity topology.

## 13. Diagnostics

Fail-visible behavior covers:

- occupancy referencing a missing entity;
- missing placement;
- placement not on OBJECT channel;
- occupancy/placement mismatch;
- unknown semantic family;
- unknown Art Catalog prop kind;
- malformed/non-drawable selection;
- texture-load failure.

Multiple OBJECT occupants in one cell are not inherently diagnostic. Diagnostic-reason bookkeeping is bounded.

## 14. Non-goals / forbidden ownership

07 does not own or import:

- Ground/Structure/Actor renderer internals;
- ACTOR / LOOSE_ITEM / EFFECT rendering;
- vehicles;
- Collision, Movement, Actor Locomotion, Door State, or WHEN;
- container/search/inventory/equipment state;
- fixture use, power/appliance state, vegetation growth/health;
- construction/destruction;
- generation/prefab internals;
- camera/zoom/input/UI;
- lighting/perception/weather/sound;
- AI;
- deprecated reboot wiring.

Stateful visual variants such as open containers, powered appliances, harvested crops, burning/damaged objects, or active generators require their future typed state + art contracts rather than renderer guesses.

## 15. Performance/mobile

- visible OBJECT occupancy only;
- stable-ID deduplication;
- at most one command/draw per relevant entity;
- no full-world entity scan;
- no permanent Node per persistent object;
- deterministic sorting;
- lazy texture cache;
- event-driven redraw;
- no hover/input/Safari-specific behavior.

This remains suitable for phone/Safari and a large persistent world.

## 16. Verified acceptance

Initial complete implementation head:

`5c2df6439678abaf8c9a031f5b6ed7bb8fb68a86`

Dedicated workflow run:

`31983182247` — **Prop Fixture Vegetation Renderer contract** — success under Godot 4.7.1 with no production repair commit.

The contract proved:

- source-boundary isolation and project import/parse;
- Art Catalog regression;
- Ground renderer regression;
- Structure renderer regression;
- OBJECT-channel filtering;
- all three semantic families;
- final exact, final alias, building, clutter, tactical, and barrel selections through real Art Catalog;
- deterministic anchor-row-major + stable-ID ordering;
- negative/global coordinate destination math;
- multi-cell occupancy deduplication to one command;
- retained facing/footprint/world cells;
- outside-anchor footprint intersection behavior;
- overlapping OBJECTs as deterministic separate commands;
- unknown family/kind diagnostics;
- visible OBJECT redraw and irrelevant terrain/non-OBJECT filtering;
- world-reset redraw;
- resolved texture existence/loading;
- no forbidden production dependencies or current prop-art rotation transform.

## 17. Future seams

- large-object visual geometry descriptor;
- directional/native-facing art policy;
- typed state-specific prop/fixture visual requests;
- separate vehicle renderer;
- ordinary WHAT mutation from construction/destruction;
- later Tactical Renderer composition;
- later lighting/perception overlays.

None requires changing the current physical footprint/facing contract.

## 18. North-star fit

Props, fixtures, and vegetation make persistent homes, businesses, streets, farms, utilities, and abandoned spaces visually legible while keeping physical and mechanic truth independent from art. The single-anchor rule honestly recovers the existing art instead of faking a multi-cell art system.

## 19. Approved decisions

Approved 2026-08-16:

- WHAT `OBJECT` only;
- `prop.*` / `fixture.*` / `vegetation.*` families;
- recovered `resolve_prop()` precedence only;
- one command per stable entity despite multi-cell occupancy;
- one recovered sprite at the physical anchor;
- retain facing/footprint without inventing current rotation;
- deterministic overlap draw order rather than renderer-owned collision legality;
- fail visibly for missing semantic/art content;
- event-driven visible-window rendering;
- no reboot compatibility adapter.
