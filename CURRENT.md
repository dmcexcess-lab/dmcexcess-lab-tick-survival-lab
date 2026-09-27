# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = production procedural-world bootstrap acceptance repaired; real iPhone/Safari acceptance pending
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

Canonical runtime remains:

`GameMain -> ProductionWorldBootstrap -> IslandWorldPlanner / System 20 / materialization / streaming`

Production app/UI does not import or execute `scripts/demo` to create the playable world. Production spawn comes from generated content, player identity is `actor.player`, initial materialization is the bounded focus region, adjacent streaming remains active, and durable Continue targets the same production world.

The retired `GeneratedIslandCritiqueFixture` was inspected directly after repeated iPhone failures. It confirmed an important accidental contract: the old demo-owned bootstrap did not accept the first requested seed blindly. It tried up to 128 candidate seeds and accepted only one whose generated island/local-generation contract succeeded. Removing demo ownership correctly removed the fixture, but production bootstrap initially failed to replace that seed-acceptance responsibility.

Current `IslandWorldPlanner` already validates advertised local sites through `IslandPopulationPlanner -> LocalAreaGenerator.generate_manifest()`. Therefore failures such as:

- `area.smalltown.center.001:infrastructure_reservation_unresolved...`
- `area.rural.scattered.003:parcel_access...`

are genuine seed-sensitive procedural rejections discovered while validating the complete island contract, not reasons to boot a partially invalid island.

Repair: `ProductionWorldBootstrap._resolve_new_game_plan()` now owns production seed acceptance. NEW GAME generates a candidate island, accepts it only when `IslandWorldPlanner` returns a generated plan, and deterministically advances/retries bounded candidate seeds for recognized seed-sensitive procedural failures. Deterministic/configuration failures remain diagnostic instead of being hidden by retries. No demo town, fixture, fallback island, known-good seed or compatibility wrapper was restored.

The prompt-local production-seed verifier/workflow was created before production edits and retired before this checkpoint per SOP.

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

**Real iPhone/Safari acceptance: NEW GAME must survive any rejected procedural candidate(s), resolve a valid production island, and reach the visible playable procedural map.**

If it succeeds, close the mobile/bootstrap release defect and proceed to Phase 4 independent shelter utilities, starting from the existing portable-generator owners unless targeted inspection finds an earlier missing power/water link.

If Safari still fails, keep this defect active and diagnose the exact new visible production-path failure. Do not restore demo ownership, add a fallback island, hard-code a known-good seed, or shrink procedural-world truth to hide the failure.