# Stats / Moodlet Visibility Repair — 2026-09-10

## Player report

After the terrain streaming optimization, live browser play was materially smoother, but the player reported that the stats/status information and moodlets were not appearing. The clarification was specifically a presentation failure: the systems were not being described as unavailable or logically broken; their visible HUD presentation was missing.

## Diagnosis

A production-scene focused verifier established that System 34 condition state, the status summary, the STATS modal projection, and moodlet derivation were all populated and functioning. In particular, the production path could derive an active hunger moodlet and render the corresponding STATS text.

The persistent `CanonicalStatusHud`, however, still used CanvasLayer 21 while newer presentation surfaces had been added at higher ordinary/transient layers. Its moodlet row also sat immediately below the 100-pixel panel background, leaving moodlet text floating over world art. This made persistent status presentation fragile even though its data and controls reported visible in the scene tree.

A diagnostic attempt to use the headless runner's viewport dimensions was rejected after evidence showed that runner exposes a synthetic 64x64 root viewport, while the production design surface is 640x844. The final verifier therefore validates against the canonical design bounds rather than treating the headless window as browser geometry.

## Implementation

`game/scripts/ui/CanonicalStatusHud.gd` now:

- owns persistent HUD layer 36;
- therefore renders above the transient `WorldResolutionIndicator` at layer 35;
- remains below interactive/modal presentation such as `WorldInteractionPanel` and `PlayerShell`;
- extends the status panel background from 100 to 122 pixels so the moodlet row is fully backed by the same HUD panel;
- explicitly draws status text and the moodlet row above that background with local z-index 1;
- adds dark text outlines to both persistent status labels and colored moodlet chips for reliable contrast against world art.

No condition, health, carry, moodlet, WHEN/TickKernel, world, or gameplay semantics changed.

## Verification

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptStatsMoodletsSmoke.gd`
- `.github/workflows/prompt-stats-moodlets.yml`

Functional/owning head: `2edc622852eea7990d750128d93b7b02717c7a8e`

Focused run:

- workflow run `34554733414`: **SUCCESS**

The verifier boots the real production `main.tscn -> NEW GAME -> gameplay.tscn` path and proves:

- System 34 status data is available;
- the persistent HUD is visible at protected layer 36;
- it draws above the transient resolution layer and below PlayerShell;
- all five status lines occupy the canonical 640x844 design surface;
- the moodlet row lies inside the expanded HUD background;
- an authoritative forced hunger pressure produces an active hunger moodlet and visible moodlet chip;
- the STATS modal still opens and visibly contains live System 34 condition and moodlet text.

Functional-head Pages run:

- `34554733439`: build **SUCCESS**, deploy **SUCCESS**.

## Previous verifier cleanup

The preceding terrain optimization prompt-owned verifier pair was removed at the start of this operation:

- `game/scripts/ci/PromptTerrainBulkWriteOptimizationSmoke.gd`
- `.github/workflows/prompt-terrain-bulk-write-optimization.yml`

The next code operation must retire the current stats/moodlet verifier pair before creating its own prompt-local verifier/workflow.
