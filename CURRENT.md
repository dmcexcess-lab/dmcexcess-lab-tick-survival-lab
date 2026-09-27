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

Real iPhone/Safari acceptance after the first bootstrap repair still failed: NEW GAME -> starts loading map -> waits -> Godot loading screen -> startup menu. Treat that as the active release defect until real Safari proves otherwise.

Two concrete bootstrap peaks have now been removed/bounded:

1. `_resolve_playable_boot()` no longer fully materializes a disposable initial neighborhood before authoritative materialization.
2. Production streaming bootstrap no longer synchronously keeps a radius-1 3x3 set of 128x128 regions active before the first playable frame. The focus region alone is active. One 128x128 region already exceeds the 80x96 visible render window; existing look-ahead/region-crossing streaming keeps the same procedural world available as the player moves.

This changes representation/scheduling only: world bounds, procedural generation, stable identity and gameplay truth remain unchanged.

Focused bounded-footprint run `36286982875`: **SUCCESS**, including canonical production boot regression. Existing production bootstrap run `36286982809`: **SUCCESS** on the same head.

A diagnostic seed (`271828`) exposed a pre-existing utility-topology failure (`Power span cannot be supported`) and was not used as acceptance evidence. The established production seed `20001` boots successfully with the bounded footprint. If future random-seed play exposes that utility-topology failure visibly, repair it as its own concrete generation defect rather than conflating it with WebKit memory pressure.

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

- `game/scripts/ci/MobileStreamingFootprintSmoke.gd`
- `.github/workflows/mobile-streaming-footprint.yml`

The older first-bootstrap verifier/workflow also remains present because repository deletion was unavailable during this repair; it is green on the same head and does not own new production behavior.

The next code-changing operation should retire prompt-local bootstrap verification and create fresh verification scoped to the actual next operation.

## NEXT

**Retry NEW GAME on real iPhone/Safari after the bounded-streaming Pages deployment.**

If it reaches the playable map without WebKit/Godot restarting, close the mobile bootstrap defect and proceed to Phase 4 independent shelter utilities, starting from existing portable-generator owners unless targeted inspection finds an earlier missing power/water link.

If Safari still restarts, keep this defect active and diagnose the next measured/proven bootstrap peak. Do not advance gameplay work and do not shrink procedural-world truth to hide the problem.
