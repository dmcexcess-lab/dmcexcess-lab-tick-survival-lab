# Tick Survival Lab — Current Repository Handoff

Read this file first, then README_SOPS.md. Fetch current main once at prompt start.

## Current checkpoint — STREETLIGHT FIX PUBLISHED AND VERIFIED — 2026-09-08

User explicitly requested another attempt to fix the pole issue and make streetlights active only at night. This supersedes the prior revert's prohibition on retrying without a new request.

Functional published head: `feee318732890aebd12a0b868bdc0578f91bb4a1`.
Its tree `d5b9794552cb6677c793e9a17f0e015a56363b26` exactly matches locally tested commit `4669b743992104a15d1672847e368499e677f776`.
User explicitly confirmed direct-to-main publication in the next turn. Shell push lacked HTTPS credentials; publication succeeded through the connected GitHub API as a non-forced fast-forward.

Completed:
- Shared coordinate cadence replaces independently offset periodic pole samples from each substation. Seed 20001 now has 935 streetlights rather than 1048. Customer taps/bends/junctions remain, and every other roadside support is still a streetlight. This reduces redundant periodic placement; it does not impose a minimum gap on required customer supports.
- Existing UtilityPoweredLightingSourceAdapter consumes the production OutdoorAmbientLightService. Streetlights emit only during its night phase, 20:30 to 05:30. Power availability still applies. Other fixtures retain their behavior. No wrappers, new clocks, or renderer/streaming changes.
- Removed prior revert verifier pair; created `game/scripts/ci/PromptStreetlightCycleSmoke.gd` and `.github/workflows/prompt-streetlight-cycle.yml`.
- Local Godot 4.7.1 production test PASS: boot, day/night boundaries including midnight, source outage/restoration, reduced streetlight count, valid endpoints, maximum 16-cell spans, no duplicate spans and no unsupported X crossings. Supported T junctions are permitted.
- Changelog updated. Screenshot location and Safari visual acceptance were not reproduced; original missing-new-cells rendering issue remains open.

Verification / closure:
- Local Godot 4.7.1 focused production verifier passed.
- Published owning-head Prompt Streetlight Cycle run `34191841093`: success.
- Published owning-head Pages run `34191841151`: build job `101951330999` and deployment job `101951514119` both success.
- No publication blocker remains. This handoff is the FINAL repository write. After publishing its containing documentation commit, verify that exact main head, current focused workflow and Pages read-only to terminal success. Do not mutate again to insert final run IDs.
- Keep the active verifier during this publication closure. At the next distinct code operation delete `game/scripts/ci/PromptStreetlightCycleSmoke.gd` and `.github/workflows/prompt-streetlight-cycle.yml`, then create one fresh pair restricted to the module being changed.

## NEXT OPERATION — DIAGNOSE ORIGINAL NEW-CELL RENDER FAILURE

After streetlight publication, the separately recorded next task remains diagnosis of the original new-cell render failure: establish the first failed streaming/materialization/render boundary from current truth. Preserve 3072×3072 world, 128×128 regions, active radius 1 and 80×96 render window unless concrete evidence proves a defect. Do not revive reverted viewport-margin experiments speculatively.

This handoff is the FINAL repository write for this publication turn. Perform only read-only exact-head verification afterward.
