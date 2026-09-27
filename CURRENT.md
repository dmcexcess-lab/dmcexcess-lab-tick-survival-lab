# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = production world bootstrap repaired; infrastructure reservation defect repaired; real iPhone/Safari acceptance pending
ROADMAP_CHANGE = false
```

## Completed / closed for current release

- Phase 1 live survivor/society dependencies retired.
- Phase 2 engineering foundation closed.
- Phase 3 durable continuation closed.
- Phase 4 powered cooking, contextual deconstruction and existing-building fortification vertical routes closed.
- Vision observer-pose invalidation repaired; lighting presentation simplified while preserving physical-light truth; generic survival-action strip removed.

Do not reopen closed work merely for improvement. A concrete active-play defect may justify a targeted repair.

## Production world bootstrap checkpoint

Canonical runtime is now:

`GameMain -> ProductionWorldBootstrap -> IslandWorldPlanner / System 20 / materialization / streaming`

Production app/UI no longer imports or executes `scripts/demo` to create the playable world. Production spawn comes from actual generated content, player identity is `actor.player`, initial materialization is the bounded single focus region, adjacent streaming remains active, and durable Continue targets the same production world.

The latest real iPhone/Safari attempt progressed through production bootstrap far enough to expose a genuine System 20 generation defect:

`generation_failed:area.smalltown.center.001:infrastructure_reservation_unresolved...`

Root cause: `InfrastructureReservationPlanner` required a facility footprint to fit immediately perpendicular to the exact global infrastructure source cell. A legitimate power node near an inherited-road/area edge could therefore have no legal local substation rectangle even though legal frontage existed a short distance along the same road.

Repair: the global node remains authoritative semantic source truth, while its local facility reservation deterministically searches along that same inherited road and chooses the nearest legal roadside footprint. This does not reroll the island, create a fallback town, move infrastructure to another road, or restore demo ownership.

Current focused verifier/workflow:

- `game/scripts/ci/InfrastructureReservationRecoverySmoke.gd`
- `.github/workflows/infrastructure-reservation-recovery.yml`

Run `36350128246`: **SUCCESS**. It proves edge-constrained facility recovery and then passes the existing procedural-island seed matrix.

The previous production-bootstrap prompt-local verifier/workflow was retired before this production edit per SOP.

## Active roadmap phase — expedition + fortified-house loop

After real iPhone/Safari confirms NEW GAME reaches the visible playable map, continue the next release requirement: practical independent shelter utilities / real utility failure recovery.

Existing production source already contains portable-generator and utility power repair owners. Start there rather than inventing another utility architecture.

A base remains an existing place the player fortified and supplied.

## Current interaction invariants

- Survival actions originate from the thing being acted upon.
- Food/drink -> EAT/DRINK; bed/furniture -> REST/SLEEP; powered potable fixture -> DRINK; stove -> contextual crafting; deconstructable object -> DECONSTRUCT; existing opening -> BOARD/REMOVE BOARD/BREAK/opening actions.
- No generic survival/crafting/construction action strip.
- Existing WHAT/WHEN/combat/perception/lighting/open-world persistence contracts remain fixed unless a concrete defect requires a targeted repair.

## NEXT

**Real iPhone/Safari acceptance: NEW GAME must reach the visible playable procedural map with the infrastructure-reservation repair deployed.**

If it succeeds, close the mobile/bootstrap release defect and proceed to Phase 4 independent shelter utilities, starting from the existing portable-generator owners unless targeted inspection finds an earlier missing power/water link.

If Safari still fails, keep this defect active and diagnose the exact new visible production-path failure. Do not restore demo ownership, add a fallback island, hard-code a known-good seed, or shrink procedural-world truth to hide the failure.
