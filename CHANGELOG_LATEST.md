# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Production world bootstrap separation — 2026-09-27

- Confirmed the canonical playable game was incorrectly booting through `scripts/demo/GeneratedIslandCritiqueFixture.gd`; production identity, spawn, map UI and downstream app composition still inherited demo-era ownership.
- Added `generation/integration/ProductionWorldBootstrap.gd` and promoted generated-world collision/traversal rule installation into production integration code.
- Canonical app chain now uses `_boot_production_world()` and `WorldBootstrapClass`; production player identity is `actor.player`.
- Production spawn is selected from actual generated area sites/roads near world center rather than requiring `area.rural.crossroads.001`, `dev.rural_crossroads`, the diner fixture or `actor.player.demo`.
- Utility runtime binds initial service truth to the actual production player cell rather than the demo central-settlement constant.
- `PlayerMapBootstrap` now reads the production global plan/player identity directly.
- NEW GAME only retries failures classified as genuine procedural generation/spawn invalidity; deterministic bootstrap/materialization/configuration failures are surfaced with their production reason instead of being mislabeled as bad seeds.
- The focused verifier statically rejects demo dependencies anywhere in canonical app scripts, boots the real gameplay scene, verifies generated spawn/render/one-region materialization, crosses a streaming-region boundary, snapshots the durable session, and proves Continue restores the same seed/player/world identity.
- Focused run `36348729521`: **SUCCESS**, marker `PRODUCTION_WORLD_BOOTSTRAP_OK ... demo_free=true save_continue=true`.
- The previous rejected-seed recovery was symptom treatment and is superseded by this production ownership repair.

## Mobile/Safari rejected-seed recovery — 2026-09-26 (superseded)

- The bounded retry exposed that the canonical runtime still depended on demo bootstrap ownership. Its prompt-local verifier/workflow has been retired.

## Mobile/Safari bootstrap footprint repair — 2026-09-26

- Initial streaming was bounded from a 3x3 128x128 neighborhood to the single 128x128 focus region while preserving the procedural world and streaming identity.
- Focused run `36286982875`: **SUCCESS**.

## Mobile/Safari new-game bootstrap repair — 2026-09-26

- Removed duplicate disposable initial-neighborhood materialization before authoritative world materialization.
- Focused production run `36281756339`: **SUCCESS**.

## Phase 4 — existing-window fortification route — 2026-09-26

- Existing windows/doors contextually BOARD to three authoritative layers through existing tool/material/Mechanical/WHEN semantics.
- Three layers materially reduce infected opening-pressure damage from 55 to 40.
- Save/reopen/Continue preserves fortification without duplicating consumed materials.
- Focused/protected run `36276349197`: **SUCCESS**.

## Phase 4 — contextual deconstruction route — 2026-09-26

- Generated dining chairs expose contextual DECONSTRUCT through established world interaction.
- Existing tool/Mechanical/WHEN semantics remove the chair and yield one existing wood plank; cancellation is safe and Continue is durable.
- Focused/protected run `36275247010`: **SUCCESS**.

## Phase 4 — powered stove cooking route — 2026-09-26

- Generated stove -> contextual crafting -> real carried input/tool -> WHEN crafting -> heated soup.
- Live System 33 power gates cooking; cooked food enters EAT and persists through Continue.
- Focused route run `36273690260`: **SUCCESS**.

## Phase 3 — durable save / leave / reopen / Continue — 2026-09-26

- Versioned checksum-verified primary/backup durable sessions restore existing authoritative WHAT/WHEN/mechanic state without duplicate persistence truth.
- New Game, Continue, Save/Save & Menu and safe checkpoints are production-wired.
- Protected/focused run `36271614098`: **SUCCESS**; exact-head Pages run `36271614056`: **SUCCESS**.
