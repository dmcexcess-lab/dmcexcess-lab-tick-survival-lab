# System 07A — Prop Art Orientation — Implementation Changelog

Status: **IMPLEMENTED**

## Player-visible change

- Directional props/fixtures now visually honor the N/E/S/W facing already stored in WHAT.
- Recovered indoor/furniture art uses SOUTH/down as its native presentation direction.
- Sinks, shelves, sofas, beds, counters, appliances and similar directional furniture rotate around the center of their existing one-cell draw destination.
- Trees/rocks/vegetation and other nondirectional art remain unrotated.
- No building geometry or prop placement was changed.

## Architecture

- Added `game/scripts/art/PropArtOrientationCatalog.gd` as presentation-only native-facing metadata.
- Kept `ArtCatalog.resolve_prop` and `PropLayerRenderer.configure` APIs unchanged.
- Kept generator and WHAT semantics unchanged; renderer consumes existing world facing.
- Added centered quarter-turn transforms in `PropLayerRenderer` and resets the transform after each rotated draw.
- Added focused `PropArtOrientationSmoke.gd` coverage.
- Updated the existing Prop Renderer workflow: rotation is now required rather than forbidden.

## Recovered orientation coverage

Native SOUTH groups currently include:

- final props 64–127;
- building props 0–19;
- directional clutter 0–6 and 18;
- tactical indoor fixtures 37–47.

## Verification

First green implementation candidate:

- SHA `6a41dd24a2fa0a594c14ef83ea2ba1015b333124`
- Prop renderer workflow run `32008973352`: **SUCCESS**

Exact promoted-head verification and Pages deployment are required before completion is claimed.
