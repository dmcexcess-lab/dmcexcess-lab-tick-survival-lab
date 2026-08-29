# Tick Survival Lab — Latest Changes

This compact ledger records the most recent work. `CHANGELOG.md` remains the historical archive.

## System 33 Truthful Lighting Repair — 2026-08-29

Verified executable: `ec7be83146d62055a5d2d4b1233eb7cc50cea630`

- Human play rejected the first System-33 lighting integration because the utility model was real but the visible light sources were not: the player received an unconditional fake flashlight beam and fixed lights came from legacy demo coordinates rather than visible generated-world fixtures.
- Replaced that source boundary with `UtilityPoweredLightingSourceAdapter`, which derives fixed emitters from actual persistent WHAT fixture entities and their actual world placements.
- Fixed fixtures now bind to the System-33 power service for their real cell; local power loss removes the corresponding System-27 emitter and service restoration restores it.
- The player now emits a flashlight cone only while an actual WHAT entity with semantic type `item.tool.flashlight` is assigned to a real hand-equipment slot. No flashlight is silently granted at spawn.
- Portable flashlight battery depletion/toggle simulation remains deliberately deferred; the grid does not fake-disable a portable light.
- Retired `DemoLightingSourceAdapter` as a gameplay light source. The legacy class remains an inert compatibility/bootstrap shim that reports zero emitters.
- Added a semantic-type index/query seam in WHAT so fixed-light discovery does not require recurring whole-world entity scans.
- Added `System33LightingTruthSmoke.gd` and `verify/system33-lighting-truth` coverage proving real fixture position/facing, local power causality, no unequipped flashlight, equip/unequip behavior and legacy-source retirement.
- Updated stale System-27 and responsiveness regressions that had accidentally encoded the fake flashlight as required behavior. A facing-only turn with no equipped light now proves the physical-light solver stays asleep.
- Preserved the human-accepted full-window physical-light presentation path and stateless LOS path; no camera-cropped lighting or rejected LOS cache was reintroduced.
- Exact-head `ec7be83...` verification is green for System 33 power/water, System 33 lighting truth, System 27 physical lighting, performance architecture, player responsiveness, System 07B geometry, Pages deploy and all reported neighboring exact-head contexts.
- **Human browser retest remains the System-33 acceptance gate. Phase 3 is not marked human accepted yet.**

## Human Acceptance + Phase 3 Design Start — 2026-08-29

- Human browser play confirmed the black-screen recovery is fixed and performance is improved, accepting the responsiveness/visibility slice preceding System 33.
- The current playable island was accepted to move forward, closing the stale human-acceptance gate around focused island-local overlap repair `282864f242ba2a5c3df0519591e31990372c4aed`.
- The rejected broad settlement-planner attempt `918f1dbd7b033fa179522a112b1507d9a2c63890` remains explicitly non-canonical.
- System 33 Candidate 001 was described, explicitly approved, implemented and automatically verified. Its first visible lighting integration was then human-rejected and repaired as recorded above.

## Black-Screen Visibility Recovery — 2026-08-29

Validated recovery executable: `1f65bff312853a44858201b57d9df2e26ee64f80`

- Human browser play reported a completely black game after `6e1298da36e9216139f404696275280fcb944033`, despite automated startup/integration checks passing.
- Restored the last human-good full 80x96 physical-light presentation path and prior stateless System-23 LOS query.
- Preserved WHEN decision-pause input locking, one-due-tick-batch-per-render-frame action pumping, immediate next-pause acceptance and coalesced settled light/perception work.
- Retracted camera-cropped lighting presentation and revision-cached LOS optimization from canonical runtime.
- Strengthened `PlayerInputResponsivenessSmoke.gd` to require a usable visible field plus initialized non-black lighting textures.
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
- Phase 3 / System 33 Power and Water Candidate 001 is **IMPLEMENTED + AUTOMATED VERIFIED** on executable `ec7be83146d62055a5d2d4b1233eb7cc50cea630` after the truthful-lighting repair.
- **Phase 3 human acceptance is pending a fresh browser playtest of the repaired real-fixture lighting behavior.**
