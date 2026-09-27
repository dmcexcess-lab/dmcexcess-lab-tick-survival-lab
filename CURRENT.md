# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = mobile new-game bootstrap acceptance
ROADMAP_CHANGE = false
```

## Completed / closed for current release

- Phase 1: live survivor/society dependencies retired.
- Phase 2 engineering foundation: shared-tick combat, commitment/interruption, simultaneous melee consequences, causal movement/shove, mob force, canonical fear, bounded eight-infected perception/callback path, coherent consequence presentation and crowded-fight technical acceptance.
- Phase 3 durable continuation.
- Phase 4 powered cooking, contextual deconstruction and existing-building fortification vertical routes.
- Vision observer-pose invalidation regression repaired.
- Lighting presentation simplified to direct tile tint while preserving physical-light gameplay truth.
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Mobile/Safari bootstrap checkpoint

Real iPhone/Safari has now provided two distinct failure signatures:

1. Before footprint repairs: NEW GAME -> map loading -> WebKit/Godot restart -> startup menu.
2. After bounded streaming: NEW GAME returned cleanly to the menu with `gameplay_boot_failed`, proving the browser survived bootstrap far enough for application-level world validation to reject that procedural island.

Three concrete repairs are now present:

1. `_resolve_playable_boot()` no longer fully materializes a disposable initial neighborhood before authoritative materialization.
2. Production streaming bootstrap keeps only the 128x128 focus region active before the first playable frame instead of a 3x3 region neighborhood. The procedural world itself is unchanged and streams normally as the player moves.
3. NEW GAME now owns conventional bounded procedural-seed recovery. A rejected generated island is freed, a frame is yielded, and a fresh procedural seed is attempted, up to six attempts. Continue/save restoration remains single-attempt and fail-safe; it is never silently rerolled.

The menu also now distinguishes NEW GAME generation failure from Continue failure instead of labeling both as `Continue failed safely`.

Known diagnostic seed `271828` reaches a materialization/topology rejection; established production seed `20001` boots. This is now explicitly exercised by the focused recovery verifier.

Focused/protected run `36287621698`: **SUCCESS**, including rejected-seed -> replacement-seed recovery evidence and canonical production boot regression.

## Active roadmap phase — expedition + fortified-house loop

Once real iPhone/Safari confirms NEW GAME reaches the playable map, continue the next release requirement: practical independent shelter utilities / real utility failure recovery.

Existing production source already contains portable-generator and utility power repair owners. Start there rather than inventing another utility architecture.

A base remains an existing place the player has fortified and supplied.

## Current interaction invariants

- Survival actions originate from the thing being acted upon.
- Food/drink -> EAT/DRINK; bed/furniture -> REST/SLEEP; powered potable fixture -> DRINK; stove -> contextual crafting; deconstructable object -> DECONSTRUCT; existing opening -> BOARD/REMOVE BOARD/BREAK/opening actions.
- No generic survival/crafting/construction action strip.
- Existing WHAT/WHEN/combat/perception/lighting/open-world persistence contracts remain fixed unless a concrete defect requires a targeted repair.

## Verification lifecycle

Current focused verifier/workflow:

- `game/scripts/ci/NewGameSeedRecoverySmoke.gd`
- `.github/workflows/new-game-seed-recovery.yml`

The previous prompt-local bounded-streaming verifier/workflow was retired before this production repair. The older first-bootstrap verifier/workflow remains as historical protected coverage.

The next code-changing operation should retire this prompt-local recovery verifier/workflow and create fresh verification scoped to the actual next operation.

## NEXT

**Retry NEW GAME on real iPhone/Safari after the seed-recovery Pages deployment.**

If it reaches the playable map without restart or `gameplay_boot_failed`, close the mobile bootstrap defect and proceed to Phase 4 independent shelter utilities, starting from existing portable-generator owners unless targeted inspection finds an earlier missing power/water link.

If Safari still fails, keep this defect active and use the exact new visible failure signature to diagnose the next concrete bootstrap defect. Do not advance gameplay work and do not shrink procedural-world truth to hide the problem.
