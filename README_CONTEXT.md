# Tick Survival Lab — Current Repository Handoff

Read this file first, then README_SOPS.md. Fetch current main once at prompt start.

## Current checkpoint — VEHICLE UI OVERLAP FIXED — 2026-09-09

User direction: work toward completion, balance, bug fixing and UI/UX in small pieces. Complete and publish ONE bounded piece, then ask for approval before starting another so the user can inspect usage. This cadence is also recorded in README_SOPS.md. Direct-to-main publication within an approved piece remains authorized.

Functional published head: `3a3b4cfb3c6fefdb4afc963ae303c6322a6ffb41`.
Tree `d5acd356136c9b75feebca941311718cc270a6b5` matches local tested commit `086a691ff68016eecd621a55fce652d2d597390e`.

## Completed this piece

- VehiclePlayerControls status and cargo labels previously overlapped the CENTER/FOLLOW and MAP row visible in the supplied phone screenshot.
- Moved them into 24-pixel rows at y520 and y544, ending six pixels before CameraControls.ROW_Y (574). Positions derive from the camera row constant.
- The focused test caught theme minimum sizing overflowing an initial 18-pixel row; full 24-pixel rows now pass actual instantiated Control rectangle checks.
- Replaced cargo arrow glyph labels with plain STORE and TAKE to avoid broken glyphs.
- Gameplay, action wiring and balance are unchanged.
- Changelog updated. Prior world-boundary verifier pair retired.

## Verification / publication

Fresh disposable pair:
- `game/scripts/ci/PromptVehicleControlsSmoke.gd`
- `.github/workflows/prompt-vehicle-controls.yml`

Local Godot 4.7.1: `PROMPT_VEHICLE_CONTROLS_SMOKE: PASS`. Test instantiates the real camera and vehicle UI, checks themed label rectangles against camera buttons and each other, button bounds/overlap, cargo labels and dismount visibility.
Owning functional-head focused run `34396616453`: success.
Owning functional-head Pages run `34396615881`: success.
Publication uses connected GitHub API because shell git has no credentials.

This handoff is the FINAL repository write. Publish its containing commit, then verify exact final main and final-head focused CI/Pages read-only through terminal success. Do not write again to insert final run IDs.

## Visual acceptance limitation

Earlier cloud Chrome opened the public game but reported missing WebGL2. This environment therefore cannot perform a live game visual acceptance pass. This is not evidence the user's phone cannot run the game. This piece is verified by actual headless UI geometry and deployment, not a new Safari screenshot test.

## NEXT OPERATION — WAIT FOR USER APPROVAL

Stop after this piece and ask whether to continue with a small inventory action usability pass: inspect available actions and failure feedback, then repair one concrete issue if found. Do not start that work before approval. The whole game is not declared finished.

After approval, at the next distinct code operation delete PromptVehicleControlsSmoke.gd / prompt-vehicle-controls.yml and create one fresh module-local pair. Do not run historical suites or routine seed matrices.

## Preserve established behavior and remaining scope

- Exploration rendering uses actual generated bounds (-408,592,3072,3072), not legacy request bounds. The previous focused production test passed at (2023,1552) and (2025,1552). Keep the 80×96 render window, 128×128 streaming regions and active radius 1.
- Preserve current world generation; streetlights night-only 20:30–05:30 and bounded/shared spacing; exclusive dedicated vehicle rendering without purple diagnostic; existing eight-member infected cohort; authoritative item/action/state ownership.
- Same-tick actor consequences currently resolve sequentially by priority/owner/serial. Simultaneous movement was discussed but is not implemented.
- Future closure should reconcile roadmap with newer owning documents before rebuilding cooking, first aid, vehicle components or repair. Real generated-house environmental-pressure acceptance remains to prove. Survivors/followers/raiders/conversation/outbreak expansion remains roadmap work, not completed content.
