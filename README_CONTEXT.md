# Tick Survival Lab — Current Repository Handoff

Read this file first, then README_SOPS.md. Fetch current main once at prompt start.

## Current checkpoint — VEHICLE PURPLE SQUARE REMOVED — 2026-09-08

User requested removal of the purple square beneath vehicles, with a screenshot showing a mounted skateboard.

Functional published head: `efc50cf4200b1a6ee3da7ec26da8a172c3e9f3d8`.
Source tree: `c9fed4f16dd7c10e0cabc36660f0a2a2b40b02da`, identical to locally tested commit `74d376db9bba47aadb6846181d325f2a959a8eac`.

Completed:
- Diagnosed duplicate presentation: PropLayerRenderer interpreted OBJECT vehicles as ordinary props and drew its magenta missing-art diagnostic beneath VehicleRenderer's dedicated sprite.
- TacticalRendererStack now supplies the configured VehicleRenderer to PropLayerRenderer. Generic prop planning skips identities owned by the dedicated renderer, checking registered state, sprite availability and supported placement channel.
- All five vehicle types retain their dedicated sprites; mounted and loose skateboard transitions retain the same identity. Unrelated unknown props still produce diagnostics. Vehicle mechanics and sprites were not modified.
- Replaced the previous streetlight verifier pair with `game/scripts/ci/PromptVehicleVisualSmoke.gd` and `.github/workflows/prompt-vehicle-visual.yml`.
- Local Godot 4.7.1 focused test PASS: production stack composition, all five types, mounted/loose/remounted skateboard, no duplicate generic commands, and diagnostics retained without the dedicated renderer. This was a render-planning test; no Safari screenshot acceptance was performed.
- Changelog updated. Publication used connected GitHub API because shell Git has no HTTPS credentials; direct-to-main remains user-authorized.

Verification:
- Owning-head Prompt Vehicle Visual run `34194820726`: success.
- Owning-head Pages run `34194820735`: success.
- This is the FINAL repository write. After publishing this handoff's containing commit, verify exact main head and final-head focused CI/Pages read-only to terminal success; do not mutate afterward to insert run IDs.
- No unresolved blocker for this vehicle visual repair.

## NEXT OPERATION — DIAGNOSE ORIGINAL NEW-CELL RENDER FAILURE

The separate new-cell render failure remains open. Establish the first failed streaming/materialization/render boundary from current truth. Preserve 3072×3072 world, 128×128 regions, active radius 1 and 80×96 render window unless concrete evidence proves a defect. Do not revive reverted viewport-margin experiments speculatively.

User also observed sequential actor resolution. Read-only inspection confirmed TickKernel processes same-tick events by priority, actor/owner key and serial; movement commits immediately, and the player controller presents one due-tick batch per frame. No scheduler changes were requested or implemented in the vehicle visual operation. Do not silently introduce simultaneous movement as part of a rendering repair.

Preserve the published streetlight repair: shared coordinate sampling cadence, 935 seed-20001 streetlights, alternating roadside supports, real powered emission only during night (20:30–05:30). Customer taps and required supports remain.

At the start of the next distinct code operation, delete `game/scripts/ci/PromptVehicleVisualSmoke.gd` and `.github/workflows/prompt-vehicle-visual.yml`, then create one fresh pair for the exact module being changed. Do not restore historical standing gameplay gates.
