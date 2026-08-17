# Tick Survival Lab — System 07A Prop Art Orientation / Facing-Aware Rotation

Status: **IMPLEMENTED — facing-aware recovered prop art rotation present 2026-08-17**

Approval basis: direct user instruction on 2026-08-17: **“Also we need item rotation so sinks and shelves face correctly.”** This is a bounded presentation revision of implemented System 07, using the directional-prop seam already reserved by that design.

## 1. Goal

Render directional props/fixtures/furniture in the same N/E/S/W orientation already stored by canonical WHAT placement, so sinks, shelves, sofas, beds, counters, appliances and similar objects visually face the direction their world placement says they face.

## 2. Non-goals

07A does not change:

- WHAT placement/facing or footprints;
- generator room/prop placement rules;
- collision or interaction direction;
- inventory/item state;
- art assets or atlas cell contents;
- large-object visual geometry;
- doors/structures/actors;
- camera/input/UI.

This is presentation only. Art remains separate from physics.

## 3. Owners

- `game/scripts/art/PropArtOrientationCatalog.gd`
- `game/scripts/render/PropLayerRenderer.gd`
- `game/scripts/ci/PropArtOrientationSmoke.gd`
- existing `.github/workflows/prop-renderer.yml`

`PropDrawCommand` remains unchanged because it already retains both the selected art and authoritative WHAT facing needed at draw time.

## 4. Public/semantic contract

### `PropArtOrientationCatalog`

Presentation-only native-facing metadata:

- `native_facing(selection) -> int`
- `is_directional(selection) -> bool`
- `quarter_turns(selection, world_facing) -> int`

A negative native facing means the art is nondirectional and must not rotate.

The catalog consumes only `ArtSelection` presentation descriptors plus canonical WHERE facing vocabulary. It reads no WHAT, generator, collision, item, UI or simulation state.

### Prop renderer

The existing `PropLayerRenderer.configure(world, art_catalog)` API is unchanged.

For each valid command it now:

1. reads the command's already-preserved WHAT facing;
2. asks `PropArtOrientationCatalog` for the recovered sprite's native facing;
3. calculates a deterministic 0/1/2/3 quarter-turn transform;
4. rotates the one-cell sprite around the center of its existing destination cell;
5. restores the CanvasItem transform before drawing the next command.

No world state is mutated.

## 5. Recovered native-facing convention

Inspection of the preserved recovered art shows the indoor/furniture sprites are authored with their functional/front direction toward **screen SOUTH/down**.

Examples:

- kitchen sink: faucet/back edge at the north/top side, usable basin/front toward south;
- counters: back/countertop edge at north/top, cabinet/front toward south;
- sofas/chairs: backrest toward north/top, seat/front toward south;
- beds: pillow/head end toward north/top, foot direction toward south;
- retail shelving and indoor appliances follow the same front-facing convention.

07A therefore marks these recovered groups native SOUTH:

- final-props indoor/retail/industrial atlas cells 64–127;
- building-props cells 0–19;
- directional clutter cells 0–6 and 18;
- tactical indoor fixture cells 37–47.

Outdoor/nondirectional recovered art such as trees, rocks and vegetation is left without a native facing and therefore remains visually unrotated.

## 6. Rotation math

Canonical facing ordinal is N/E/S/W.

`quarter_turns = (world_facing - native_facing) mod 4`

For native-SOUTH art:

- SOUTH -> 0 turns;
- WEST -> 1 clockwise quarter turn;
- NORTH -> 2 turns;
- EAST -> 3 clockwise quarter turns.

The square one-cell destination remains the same size and anchor; only its presentation transform changes.

## 7. Generator relationship

Generation already stores semantic N/E/S/W prop facing and rotates that facing with the building orientation. 07A deliberately does not modify either Trailer v2 or Farmhouse Candidate 001 generator rules.

Therefore:

- the accepted trailer's east-facing stove/fridge/sink now visually rotate east;
- farmhouse wall-facing furniture/appliances present according to the exact facings already in its semantic plan;
- rotating an entire generated building also rotates its props automatically through existing world-facing truth.

## 8. Failure/edge behavior

- invalid or UNKNOWN selection -> existing diagnostic path;
- invalid WHAT facing -> zero visual rotation rather than inventing direction;
- selection with no orientation metadata -> zero rotation;
- full-texture/non-atlas prop selections currently have no native-facing metadata and remain unrotated;
- transform is always reset after a rotated draw so later layers/commands do not inherit it.

## 9. Performance/mobile

Rotation is a bounded per-visible-prop draw transform only. There is:

- no per-frame simulation;
- no extra world scan;
- no Node per prop;
- no additional persistent state;
- no Safari/input behavior.

## 10. Verification

First fully green implementation candidate:

- SHA `6a41dd24a2fa0a594c14ef83ea2ba1015b333124`;
- Prop Fixture Vegetation Renderer workflow run `32008973352`: **SUCCESS**.

That run passed:

- source-boundary checks;
- Godot 4.7.1 project parse;
- recovered Art Catalog regression;
- dedicated prop-orientation smoke;
- Ground renderer regression;
- Structure renderer regression;
- existing Prop renderer regression.

The orientation smoke specifically proves sink SOUTH/WEST/NORTH/EAST quarter-turn mapping, retail-shelf and bookshelf orientation, building-prop native facing, and nondirectional vegetation staying unrotated.

Exact documentation-promotion SHA must re-pass the 07A/Prop workflow, System 19 live-building integration and Web/Pages before completion is claimed.

## 11. Future seams

- explicit directional-variant art instead of rotation where a sprite cannot be cleanly rotated;
- presentation-owned large-object visual geometry/anchors;
- more recovered source cells can be added to native-facing metadata without changing WHAT or generation;
- future construction/player-placement UI can set WHAT facing and automatically receive the same visual behavior.

## 12. North-star fit

This makes the world more physically readable without adding simulation complexity: world orientation already existed as truth; presentation now respects it. The result improves believable interiors while preserving the rule that art is not physics and generator data never contains sprite-specific rotation hacks.
