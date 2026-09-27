# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Mobile/Safari bootstrap footprint repair — 2026-09-26

Functional repair head before documentation: `a1aaf45c61788fe379fabf92791a0ba46aa0da61`.

- Real iPhone/Safari retest of the first bootstrap repair still restarted WebKit/Godot: NEW GAME -> map loading wait -> Godot loading screen -> startup menu.
- The initial streaming policy was still synchronously materializing a radius-1 3x3 neighborhood of 128x128 regions before the first playable frame, even though the renderer shows only an 80x96-cell window.
- Production bootstrap now keeps only the 128x128 focus region active. Existing streaming identity, procedural world truth and edge look-ahead remain intact; this is representation/scheduling, not a smaller world.
- This reduces initial active surface footprint from as many as 147,456 cells (384x384 neighborhood) to 16,384 cells while still covering more than the visible render window.
- A first diagnostic seed exposed a pre-existing utility-topology seed failure and was not treated as evidence for/against the streaming change. The established production seed 20001 boots successfully with the bounded footprint.
- Fresh focused verifier/workflow: `game/scripts/ci/MobileStreamingFootprintSmoke.gd` + `.github/workflows/mobile-streaming-footprint.yml`.
- Focused run `36286982875`: **SUCCESS**; canonical production boot regression also passed.
- Existing mobile bootstrap run `36286982809`: **SUCCESS** on the same production head.
- Real iPhone/Safari NEW GAME remains the decisive acceptance gate for the reported WebKit restart.

## Mobile/Safari new-game bootstrap repair — 2026-09-26

Functional repair head before documentation: `b4f2a317883be7759d7e8ab69ad11eb3c163ee00`.

- Investigated the reported real iPhone/Safari failure: startup menu loads, NEW GAME begins world generation, then WebKit/Godot restarts before the playable map appears.
- Found a concrete bootstrap memory defect in `GeneratedIslandCritiqueFixture`: every candidate seed fully materialized the initial 3x3 streaming neighborhood into a disposable probe world, then immediately materialized the same neighborhood again into authoritative WHAT.
- Removed the disposable full-world streaming probe. Seed selection still validates global generation, central-area generation and a valid player start; the selected world is then materialized exactly once into authoritative WHAT.
- Focused production run `36281756339`: **SUCCESS**, marker `MOBILE_NEW_GAME_BOOTSTRAP_OK production_boot=true single_initial_materialization=true player=true streaming=true`.

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
