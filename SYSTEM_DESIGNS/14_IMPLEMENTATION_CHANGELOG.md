# 14 Canonical Playable Demo — Implementation Changelog

Date: 2026-08-16

## Implemented

- Replaced the live `game/main.tscn` Reboot entry point with `CanonicalDemoMain.gd` composition.
- Added a real 13x13 authored canonical WHAT fixture with complete terrain, cross-road, small house shell, six props, and exactly one survivor.
- Added explicit demo Collision profiles and recovered 10-tick walking traversal for the two authored terrain types.
- Added `TacticalRendererStack.gd` as orchestration over the already-implemented Ground, Structure, Prop, and Living Actor renderers. No duplicate drawing or art-selection implementation was introduced.
- Added semantic navigation intents and a keyboard adapter: W/Up forward, S/Down backward, A/Left turn left, D/Right turn right.
- Added native Godot touch Buttons for Safari/mobile using the exact same semantic intents.
- Added `DemoPlayerActionController.gd` as the thin intent -> existing Movement -> WHEN coordinator. It observes real Movement commit/failure signals and reports action/tick results to presentation.
- Deliberately omitted camera/zoom because the complete authored map fits the existing 640x844 virtual viewport at 38 pixels per tactical cell.
- Deliberately omitted NPCs, infected, AI, items, combat, Stats/Inventory screens, generated-world plumbing, and door interaction from this minimal walking demo.
- Preserved all frozen `game/scripts/reboot/` files unchanged as recovery/reference code; they are no longer the live entry point.
- Updated Pages startup validation to require `CANONICAL_DEMO_BOOT_OK` and to run the canonical integration smoke before Web export/deploy while retaining the independent frozen-Reboot regression smokes.

## Initial implementation verification

Candidate head `41ccfedd658082f5d249b5107363658705ea4b03` passed dedicated **Canonical Playable Demo contract** run `31993465800`:

- source-boundary checks;
- Godot 4.7.1 import/parse;
- WHAT, WHEN, Collision, Movement, Locomotion, and Art Catalog regressions;
- existing Ground, Structure, Prop, and Actor renderer regressions;
- canonical demo integration smoke;
- canonical main-scene startup smoke.

The integration smoke proves:

- all 169 sample-map cells contain canonical terrain;
- exactly one living actor exists and it is the controlled survivor;
- no NPC or infected actor exists;
- all placed collision-relevant actor/structure/object semantics are explicitly classified;
- renderer stack plans 169 ground, 11 structure, 6 prop, and 1 actor commands with zero planned diagnostics;
- forward intent commits `(6,10) -> (6,9)` and spends exactly 10 world ticks;
- turn-right then commits EAST facing and spends exactly 3 additional world ticks;
- an authored wall cell is BLOCKED through the real Collision query.

Final exact-SHA verification is recorded by the CI runs on the promotion head rather than by changing production mechanics after this candidate.