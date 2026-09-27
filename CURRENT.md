# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = production world bootstrap repaired; real iPhone/Safari acceptance pending
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

Root cause confirmed: canonical gameplay was still booting the real procedural world through old demo/critique ownership (`GeneratedIslandCritiqueFixture`, demo player/site constants and `_boot_canonical_demo`). The earlier seed-retry behavior was symptom treatment, not the architectural fix.

Canonical runtime is now:

`GameMain -> ProductionWorldBootstrap -> IslandWorldPlanner / System 20 / materialization / streaming`

Production app/UI no longer imports or executes `scripts/demo` to create the playable world.

Production bootstrap now:

- generates the real island from the production planner;
- selects a spawn from actual generated area sites and generated road cells rather than requiring the retired rural-crossroads/diner fixture;
- uses canonical player identity `actor.player`;
- materializes only the bounded single focus region initially;
- initializes renderer/camera/perception from the actual generated player/world position;
- keeps normal adjacent-region streaming;
- supplies the same production world seed/identity to durable save/Continue.

Utility startup now binds initial power/water service truth to the actual production player location instead of the old demo central-settlement constant. `PlayerMapBootstrap` reads the production plan directly.

NEW GAME retries only failures classified as genuine procedural generation/spawn invalidity. Deterministic bootstrap/materialization/configuration failures are surfaced by their production failure reason rather than burned through as supposedly bad seeds. Continue remains single-attempt and fail-safe.

Focused verifier/workflow:

- `game/scripts/ci/ProductionWorldBootstrapSmoke.gd`
- `.github/workflows/production-world-bootstrap.yml`

Run `36348729521`: **SUCCESS**. It proves canonical app scripts are demo-free, production seed `20001` boots the real gameplay composition, generated spawn/player/render bounds are valid, initial active region count is one, adjacent streaming transitions, durable session records the production seed, and Continue restores the same production world/player identity.

The old prompt-local rejected-seed and first mobile-bootstrap verifier/workflows were retired. Demo/critique fixtures may remain for tests/dev work but are not production owners.

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

**Real iPhone/Safari acceptance: NEW GAME must reach the visible playable procedural map through the new production bootstrap.**

If it succeeds, close the mobile/bootstrap release defect and proceed to Phase 4 independent shelter utilities, starting from the existing portable-generator owners unless targeted inspection finds an earlier missing power/water link.

If Safari still fails, keep this defect active and diagnose the exact new visible failure from the production path. Do not restore demo ownership, add a fallback island, hard-code a known-good seed, or shrink procedural-world truth to hide the failure.
