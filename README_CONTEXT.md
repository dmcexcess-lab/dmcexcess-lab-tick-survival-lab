# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — HUMAN PLAYTEST REPAIR CANDIDATE VERIFIED LOCALLY, PUBLICATION BLOCKED — 2026-09-10

The user authorized action on the concrete problems found during the genuine production-browser playtest. A bounded repair candidate is complete and locally verified on branch `fix/human-playtest`, but this workspace has no GitHub push credentials, so it has not reached `main`, GitHub Actions, or Pages.

Remote starting head fetched exactly once: `cf03ec1`

Functional repair head: `8477de7`

The final context commit is the commit containing this file after `8477de7`.

## Completed repair scope

- `LEAVE GAME` and the death return action now change to the in-game `main.tscn` title scene; the web-only Google redirect and native process quit are removed.
- Player death now opens a hard-paused `YOU DIED` modal with `RETURN TO TITLE`.
- Open/broken windows expose `CLIMB THROUGH` only when the authoritative action service currently finds a clear far-side destination.
- Unknown dotted action IDs receive readable fallback labels, including `window.open -> Open` and `survival.forage_nearby -> Forage Nearby`.
- Forage completion, failure, cancellation, and immediate rejection now report through the canonical HUD.
- Valid inventory rows no longer expose internal instance IDs.
- Consumable inventory actions explicitly warn that using the item advances time and nearby threats may act. Authoritative WHEN and hostile action opportunities were intentionally preserved.
- The persistent resolution message is now a compact `ZOMBIES NEARBY` indicator instead of a large central `ZOMBIES` banner. It remains presentation-only and mouse-ignoring.
- Previous prompt-owned verifier pairs were retired as required by SOP.

## Focused verification

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptHumanPlaytestRepairsSmoke.gd`
- `.github/workflows/prompt-human-playtest-repairs.yml`

Local Godot 4.7.1 production-path result on `8477de7`:

- full asset import completed;
- production `NEW GAME` boot printed `CANONICAL_DEMO_BOOT_OK`;
- terminal marker `PROMPT_HUMAN_PLAYTEST_REPAIRS_OK`;
- process exit code `0`.

The verifier covers only this repair path: readable fallback labels, compact threat indicator, production startup, clear/blocked window offer behavior, inventory ID presentation, death hard-pause/modal, and return to the actual title scene.

## Publication status and concrete blocker

- Direct `HEAD:main` push was not performed because the managed approval reviewer required more explicit approval for publishing production changes together with deletion of the two superseded verifier pairs.
- A safer push to remote branch `fix/human-playtest` then failed because the HTTPS remote requested a username and no GitHub credential helper/token is available.
- `gh` is not installed in this workspace.
- Therefore there is no remote workflow run and no exact-head Pages run for this candidate. Do not describe it as deployed.

## Known playtest findings not changed in this bounded repair

- Region-boundary and ordinary action latency remain open. The hands-on run observed typical control round trips around 0.7–0.9 seconds, spikes around 1.0–1.3 seconds, one control stall near tick 738, and about 4.7 seconds near tick 988; browser-control overhead prevents clean phase attribution.
- The earlier production verifier measured roughly 472 ms p50, 633 ms p95, and one 14.07-second action on a route crossing a 128-cell streaming boundary, also without enough instrumentation to attribute the spike.
- A second-world startup after leaving/reloading emitted three Godot signal-lifetime errors involving objects freed while a signal was being emitted. This needs its own lifecycle-focused repair.
- Combat escape/damage cadence and RUN discoverability remain balance/UX follow-ups rather than changes in this repair.

## Established behavior to preserve

- the single authoritative WHEN/TickKernel clock and decision-pause semantics;
- no synthetic/direct tick advancement in human playtests;
- timed eating, drinking, forage, movement, combat, and interaction consequences;
- input intent ownership, simulation consequence ownership, and presentation-only UI;
- technical streaming boundaries never becoming gameplay geography or identity;
- existing generation, population, perception, inventory, crafting, utilities, vehicles, doors/windows, and combat ownership unless focused evidence identifies a defect.

## NEXT OPERATION

Restore GitHub write authentication, then publish the existing local candidate without changing it, obtain terminal success for `Prompt human playtest repairs`, and verify exact-head Pages deployment. If publication requires explicit confirmation, state clearly that the push changes production and deletes these superseded prompt-local verifier pairs:

- `game/scripts/ci/PromptTick1000Playtest.gd`
- `.github/workflows/prompt-tick-1000-playtest.yml`
- `game/scripts/ci/PromptLoadingUiSinglePressSmoke.gd`
- `.github/workflows/prompt-loading-ui-single-press.yml`

If a code change is required after inspecting a concrete failure, this becomes a new repository operation: first delete `PromptHumanPlaytestRepairsSmoke.gd` and `prompt-human-playtest-repairs.yml`, then create a new focused verifier pair for that repair. Otherwise do not replace the successful local verifier before publication.
