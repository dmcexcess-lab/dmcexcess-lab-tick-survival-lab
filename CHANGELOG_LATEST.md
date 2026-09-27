# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

## Mobile/Safari rejected-seed recovery — 2026-09-26

Functional repair head before documentation: `cb44d6e444f6c8d1927400a45b7170484c330bca`.

- Real iPhone/Safari retest reached an application-level `gameplay_boot_failed` instead of a WebKit restart, proving the bounded bootstrap footprint survived far enough for production boot validation to reject the generated world.
- The earlier memory repair intentionally removed disposable full-world seed probes; that exposed an existing reality: some procedural seeds pass global/start planning but fail later materialization/topology validation (known fixture seed `271828`).
- NEW GAME now treats that as ordinary procedural-generation rejection: it frees the rejected game, yields a frame, and tries a fresh procedural island up to six bounded attempts. It does not silently retry Continue/save restoration failures.
- The menu now reports NEW GAME generation failures as NEW GAME failures instead of the misleading `Continue failed safely` message.
- Fresh focused verifier/workflow: `game/scripts/ci/NewGameSeedRecoverySmoke.gd` + `.github/workflows/new-game-seed-recovery.yml`.
- Focused/protected run `36287621698`: **SUCCESS**. It proves a known rejected seed fails, a replacement production seed boots, bounded NEW GAME recovery is installed, and canonical production boot remains green.
- Real iPhone/Safari NEW GAME remains the decisive acceptance gate.

## Mobile/Safari bootstrap footprint repair — 2026-09-26

Functional repair head before documentation: `a1aaf45c61788fe379fabf92791a0ba46aa0da61`.

- Real iPhone/Safari retest of the first bootstrap repair still restarted WebKit/Godot: NEW GAME -> map loading wait -> Godot loading screen -> startup menu.
- The initial streaming policy was still synchronously materializing a radius-1 3x3 neighborhood of 128x128 regions before the first playable frame, even though the renderer shows only an 80x96-cell window.
- Production bootstrap now keeps only the 128x128 focus region active. Existing streaming identity, procedural world truth and edge look-ahead remain intact; this is representation/scheduling, not a smaller world.
- This reduces initial active surface footprint from as many as 147,456 cells (384x384 neighborhood) to 16,384 cells while still covering more than the visible render window.
- A first diagnostic seed exposed a pre-existing utility-topology seed failure and was not treated as evidence for/against the streaming change. The established production seed 20001 boots successfully with the bounded footprint.
- Focused run `36286982875`: **SUCCESS**; canonical production boot regression also passed.

## Mobile/Safari new-game bootstrap repair — 2026-09-26

Functional repair head before documentation: `b4f2a317883be7759d7e8ab69ad11eb3c163ee00`.

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
