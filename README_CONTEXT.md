# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once at prompt start. This is the authoritative continuation checkpoint; do not broadly rediscover closed work.

## Current checkpoint — ROADSIDE POLE BUNCHING / NIGHT-ONLY STREETLIGHTS CLOSED — 2026-09-08

The user supplied a live mobile screenshot showing that the previous roadside-power repair still produced visible bunches of nearby supports/streetlights and asked for the real streetlight effect to operate only at night.

Functional implementation head:

- `578cff2ceca9246eb2187256c762af3b31c9de41` — `fix: space roadside poles and gate streetlights to night`

Focused-verifier/workflow head before this final handoff:

- `dce3e4cbf7ed0a64c7c6646ce6ccb81a8d2f509c`

This `README_CONTEXT.md` update is the **FINAL repository write for this prompt**. After its publication perform only read-only exact-head branch, focused-CI and Pages verification.

## What was actually wrong

Two independent live-production causes were confirmed.

### 1. Customer taps could create roadside pole bunches

`NeighborhoodPowerInfrastructureMaterializer` treated every customer's nearest road cell as a mandatory roadside key. Several adjacent buildings could therefore mint separate physical tap supports only one or two road cells apart even though the ordinary roadside trunk cadence is 10 cells.

The repaired live path now:

- coalesces ordinary straight-road customer taps back onto the existing 10-cell roadside trunk cadence;
- allows multiple nearby buildings to share the same real roadside tap support instead of creating a tiny cluster;
- preserves exact junctions and road turns when snapping would otherwise create an invalid diagonal service drop;
- preserves required topology supports, crossings and intermediate supports needed for the 16-cell maximum physical wire span.

This changes placement only. It does not add a runtime route planner, second utility owner, per-frame scan, decorative wire system, or hidden service identity.

### 2. Streetlights were only power-gated, not time-gated

`prop.streetlight` flowed through `UtilityPoweredLightingSourceAdapter` as an ordinary fixed powered emitter. If electricity was available, it illuminated during daylight too.

Streetlight emission now also derives from the already-existing System-25 world-time/daylight truth:

- the shared authoritative `TickKernel` still owns WHEN;
- `WorldTimeService` / `DaylightProfile` provide the existing canonical interpretation;
- canonical **night starts at 20:30**;
- streetlight emitters are absent during day/dawn/dusk and become active only during the canonical `night` phase;
- this is derived state only — there is no private streetlight clock, timer, scheduler, or simulated fake delay;
- other artificial lights are unaffected by the streetlight-only gate;
- electrical outage/restoration still controls the real emitter;
- physical support damage still removes the real emitter through the existing utility network consequences.

## Streetlight cadence after repair

Topology supports remain real utility poles when electrically required, but dense extra supports no longer force dense lamps.

Within each ordered straight roadside/bank run:

- lighting still follows an alternating support cadence where geometry permits;
- a streetlight may not occur within **16 physical road cells** of the preceding streetlight on that run;
- a required support that falls too close remains `prop.utility_pole_wood` and does not consume the next valid light opportunity;
- customer/facility supports that are off the roadside remain outside roadside streetlight cadence.

Seed-20001 production verification after this repair reports:

- **680 real roadside streetlights** across **64 roadside runs**;
- every checked same-run streetlight pair meets the 16-cell minimum;
- nearby straight-road customers in the focused regression share their 10-cell cadence tap instead of spawning adjacent tap poles;
- existing maximum actual wire span remains **<=16 cells**.

## Focused verification

Current prompt-owned disposable verifier pair:

- `game/scripts/ci/PromptStreetlightSpacingNightSmoke.gd`
- `.github/workflows/prompt-streetlight-spacing-night.yml`
- workflow: **Prompt Streetlight Spacing Night**

Successful functional-head focused run:

- run `34188240547`
- job `101940806500`
- result: **SUCCESS**
- marker: `PROMPT_STREETLIGHT_SPACING_NIGHT_SMOKE: PASS`
- production output: `STREETLIGHT_SPACING_NIGHT_COUNTS: lights=680 runs=64`

The focused smoke proves:

1. two adjacent straight-road customers share the same 10-cell roadside tap cadence support;
2. real production `main.tscn` boots on seed 20001;
3. real persistent roadside supports and streetlights exist;
4. same-run streetlights never violate the 16-cell minimum spacing;
5. at canonical 08:00 daytime, powered streetlight emitters are absent;
6. at canonical 20:30 night, powered streetlight emitters are present;
7. a real upstream outage turns those night streetlights off;
8. source restoration turns them back on at night;
9. damaging a real streetlight support removes that emitter;
10. the <=16-cell physical wire-span contract remains intact.

Functional-head Pages run:

- run `34188240546`
- build job `101940849643`: **SUCCESS**
- deploy job `101940978617`: **SUCCESS**

## Implementation layout

The live preloaded paths remain unchanged for callers:

- `game/scripts/simulation/utilities/NeighborhoodPowerInfrastructureMaterializer.gd`
- `game/scripts/simulation/utilities/UtilityPoweredLightingSourceAdapter.gd`

The previous implementation bodies are preserved as their base scripts and the live paths now contain focused derived behavior for this repair:

- `NeighborhoodPowerInfrastructureMaterializerBase.gd`
- `UtilityPoweredLightingSourceAdapterBase.gd`

Do not duplicate these owners or add a second power/light implementation around them.

## Prompt turnover

At the START of the next code operation, delete this prompt-owned verifier pair FIRST:

- `game/scripts/ci/PromptStreetlightSpacingNightSmoke.gd`
- `.github/workflows/prompt-streetlight-spacing-night.yml`

Then create one fresh focused verifier pair only for the next module actually being changed. Do not restore the prior roadside-power smoke or historical broad suites.

## Separate open issue — original new-cell rendering failure

The earlier mobile render-window experiment remains fully reverted. Do **not** reapply the viewport-aware recenter-margin change or treat that previous diagnosis as established.

The user's original symptom — newly approached cells eventually failing to render / exposing black space — remains a separate open live defect. This streetlight/pole repair did not touch:

- `LargeAreaRenderWindowController`;
- camera transforms;
- streaming-region geometry;
- `WorldStreamingCoordinator` ownership;
- materialization ownership;
- render-window dimensions.

When the user returns to that defect, reproduce it fresh and identify the first failing boundary among streaming focus, materialization, world-change delivery, bounded rendering, camera/culling or stale presentation state. Do not assume viewport margin is the cause.

## Protected contracts

Preserve:

- world size 3072×3072;
- technical streaming regions 128×128, active radius 1;
- production bounded render window 80×96 cells unless concrete evidence justifies a separate change;
- technical streaming boundaries never become geography or persistent identity;
- seed 20001 as focused generated-world acceptance target;
- all actual distribution wire spans <=16 cells;
- shared physical roadside trunks and service provenance;
- real powered streetlights, now canonical-night-only;
- source outage/restoration and support-damage consequences;
- gateways four-lane paved; town/crossroads routes paved; rural-rural gravel/dirt remains traversable;
- water one municipal facility + service aliases + deterministic rural wells; wastewater retired;
- no routine 12-seed matrices;
- UI owns no gameplay truth;
- project rule: **Complex behavior, simple systems. Do not over-engineer it.**

## NEXT OPERATION

First obtain live acceptance of this exact roadside spacing/night-light repair. If the user reports another concrete pole bunch, use the supplied location/screenshot to trace that exact support provenance before changing global cadence again.

If the roadside repair is accepted and the user returns to the black/new-cell rendering defect, resume **DIAGNOSE ORIGINAL NEW-CELL RENDER FAILURE** from the separate open-issue section above. Do not revive the failed viewport-margin experiment.

If neither live issue is being pursued, resume the previously deferred **REAL GENERATED-HOUSE ENVIRONMENTAL PRESSURE** acceptance operation using real seed-20001 generated doors/windows and the existing resident-backed infected cohort; do not add route planning preemptively.

## Final closure rule

This file is the final repository mutation for the roadside spacing/night-only streetlight prompt. From this point onward perform only read-only final branch, exact-head focused CI and exact-head Pages verification. Any unexpectedly discovered exact-head failure must be reported as the next repair operation rather than followed by another repository write in this prompt.
