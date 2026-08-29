# Tick Survival Lab — Latest Changes

This compact ledger records the most recent work. `CHANGELOG.md` remains the historical archive.

## Utility Support Surface Placement Repair — 2026-08-29

Verified executable: `16fe2910ea5f6828ba0c2b6a752a8aa9879b9f29`

- Expanded the streetlight/power-support placement repair from **road surface only** to **constructed vehicle surfaces**, without using vehicle traversability as the rule. Vehicles may still travel off-road; ordinary natural ground remains valid support terrain.
- Utility supports now reject canonical 00D road corridors, including perpendicular crossroads, plus materialized `ground.road_*`, parking/forecourt, driveway, gravel-road and industrial vehicle-surface semantics.
- Covered current generated surface vocabulary including `ground.parking_faded`, `ground.driveway_gravel`, `ground.gravel_dark`, `ground.gravel_light`, `ground.alley_stained` and `ground.concrete_oil`.
- Deliberately did **not** blanket-ban `ground.concrete_clean`, because current urban/suburban generation also uses that semantic for ordinary surrounding/sidewalk-like ground where legitimate streetlight placement must remain possible.
- Extended `System33PowerInfrastructureSmoke.gd` so the same stable support relocates away from each blocked constructed surface while a `ground.grass_lush` control remains legal.
- Preserved the accepted lighting/LOS/input-performance lineage; no renderer, vehicle/traversal, road-generation or utility-service ownership changes were introduced.
- Exact-head verification is green for System 33 power/water and lighting truth, System 27 physical lighting, world generation/materialization, perception, weather, performance architecture, and Pages deployment.

## Powered Non-Bloom Room Lighting — 2026-08-29

Verified executable: `c7592c956a44c31b082db84ae597f43c643231c4`

- Added one persistent invisible `fixture.room_light` WHAT entity per generated System-19 room. The fixture is placed on a real room cell in the non-rendered EFFECT channel, so indoor light has persistent world identity without inventing a visible lamp sprite or collision.
- `UtilityPoweredLightingSourceAdapter` now treats room lights as real fixed System-33 consumers. Each fixture binds to the power service for its actual cell and disappears from System-27 emitter input when that service is unavailable.
- Added `LightEmitterProfile.room_ambient()`: warm omnidirectional physical illumination with `presentation_glow_scale = 0.0`.
- System 27 still receives full physical luminance from room lights. Only additive presentation glare/scatter/source bloom is suppressed, so a powered room gets visibly lighter without a glowing bulb effect.
- Ordinary streetlights, lamps, neon and equipped flashlights retain their normal visible glow behavior.
- Added `RoomLightingPowerSmoke.gd` proving room light materially raises real local luminance while adding no bloom/glare/scatter, and that ordinary lamp glow remains intact.
- Extended `System33LightingTruthSmoke.gd` to prove persistent room-light identity, real placement, System-33 appliance binding, local outage removal and restoration.
- Preserved the human-accepted full-window physical-light renderer and stateless LOS path. No camera-cropped lighting, LOS cache, frame-driven utility work, per-room timers or recurring world scans were introduced.
- Exact-head verification is green for `verify/system33-lighting-truth`, System 33 power/water, System 27 physical lighting, System 19 building generation, System 00F streaming/materialization, performance architecture and Pages deployment.
- **Human browser retest is pending for the new indoor power/light behavior.**

## System 33 Truthful Lighting Repair — 2026-08-29

Verified executable before room-light refinement: `ec7be83146d62055a5d2d4b1233eb7cc50cea630`

- Human play rejected the first System-33 lighting integration because the utility model was real but the visible light sources were not: the player received an unconditional fake flashlight beam and fixed lights came from legacy demo coordinates rather than visible generated-world fixtures.
- Replaced that source boundary with `UtilityPoweredLightingSourceAdapter`, which derives fixed emitters from actual persistent WHAT fixture entities and their actual placements.
- Fixed fixtures bind to the System-33 power service for their real cell; local power loss removes their System-27 emitters and restoration returns them.
- The player now emits a flashlight cone only while an actual WHAT `item.tool.flashlight` is assigned to a real hand-equipment slot. No flashlight is silently granted at spawn.
- Portable flashlight battery depletion/toggle simulation remains deliberately deferred; grid power does not fake-disable a portable light.
- Retired `DemoLightingSourceAdapter` as a gameplay light source. The legacy class remains an inert compatibility/bootstrap shim with zero emitters.
- Added semantic-type indexing in WHAT so fixed-light discovery does not require recurring whole-world scans.
- User browser play subsequently reported the truthful source repair looked good; the next requested refinement was visible powered room illumination because ordinary generated interiors lacked useful indoor light sources.

## Human Acceptance + Phase 3 Design Start — 2026-08-29

- Human browser play accepted the black-screen recovery and responsiveness slice preceding System 33.
- The current playable island was accepted to move forward, closing the stale human-acceptance gate around focused island-local overlap repair `282864f242ba2a5c3df0519591e31990372c4aed`.
- The rejected broad settlement-planner attempt `918f1dbd7b033fa179522a112b1507d9a2c63890` remains explicitly non-canonical.
- System 33 Candidate 001 was described, explicitly approved, implemented and automatically verified. Its first visible lighting integration was human-rejected and then replaced by truthful fixture/equipment ownership.

## Black-Screen Visibility Recovery — 2026-08-29

Validated recovery executable: `1f65bff312853a44858201b57d9df2e26ee64f80`

- Human browser play reported a completely black game after `6e1298da36e9216139f404696275280fcb944033`, despite automated startup/integration checks passing.
- Restored the last human-good full 80x96 physical-light presentation path and prior stateless System-23 LOS query.
- Preserved WHEN decision-pause input locking, one-due-tick-batch-per-render-frame action pumping, immediate next-pause acceptance and coalesced settled light/perception work.
- Retracted camera-cropped lighting presentation and revision-cached LOS optimization from canonical runtime.
- Human browser play later accepted this recovery: black screen fixed and performance improved.

## Compact-Island World Cleanup — accepted lineage

- Rejected broad planner attempt: `918f1dbd7b033fa179522a112b1507d9a2c63890`.
- Rollback: `f6a06add3dfd212c0c29b343d24a8f7d28a89bca`.
- Accepted focused island-local repair: `282864f242ba2a5c3df0519591e31990372c4aed`.
- The accepted repair preserves global settlement layout and only adapts the conflicting inherited island-local site window.

## Project Status

- Roadmap Phase 1 remains complete.
- Roadmap Phase 2 / System 32 Crafting remains **COMPLETE + CI VERIFIED** on executable `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.
- Compact-island/world-seam cleanup is **COMPLETE + HUMAN ACCEPTED**.
- Responsiveness/black-screen recovery is **HUMAN ACCEPTED**.
- Phase 3 / System 33 Candidate 001 plus powered non-bloom room lighting and the utility-support surface-placement repair is **IMPLEMENTED + AUTOMATED VERIFIED**; current verified executable is `16fe2910ea5f6828ba0c2b6a752a8aa9879b9f29`.
- **Phase 3 human acceptance remains pending browser play of the current utility/lighting behavior, including the new support placement surfaces.**
