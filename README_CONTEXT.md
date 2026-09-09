# Tick Survival Lab — Current Repository Handoff

Read this file first, then README_SOPS.md. Fetch current main once at prompt start.

## Current checkpoint — OCCUPIED INVENTORY ACTION FEEDBACK FIXED — 2026-09-09

User approved continuation of one small inventory usability piece. Continue the cadence: complete and publish one piece, then ask approval before another so usage can be reviewed. Direct main publication remains authorized within the piece.

Functional published head: `54223ba38a2e1a762d3bed501a2ba76a1f1af6b6`.
Tree `b43c83b84f41a8ab3c6c617df20524a6f90276f2` exactly matches local tested commit `2704e7a`.

## Completed this piece

- Found equipment buttons disabled by occupied slots without explaining the cause or recovery, especially opaque for touch users.
- CanonicalPlayerShell now labels disabled slot actions “(occupied)” and adds visible wrapped guidance to select the equipped item and STOW or DROP it first. Buttons retain 44-pixel minimum targets and wrap text.
- Existing authoritative equipment projection determines availability. Available labels, intent wiring and gameplay rules are unchanged.
- Focused test instantiates the production EquipmentPlayerShell: occupied hat slot explains the block; selecting current hat offers STOW/DROP; a freed slot restores enabled WEAR HEAD with original equip intent/item and no stale guidance.
- Changelog updated. Previous vehicle-layout verifier pair retired.

## Verification / publication

Fresh disposable pair:
- `game/scripts/ci/PromptInventoryFeedbackSmoke.gd`
- `.github/workflows/prompt-inventory-feedback.yml`

Local Godot 4.7.1: `PROMPT_INVENTORY_FEEDBACK_SMOKE: PASS`; no script errors. Git diff whitespace check passed.
Owning functional-head focused run `34398434013`: success.
Owning functional-head Pages run `34398434006`: success.
Publication uses connected GitHub API because shell git has no credentials.

This handoff is the FINAL repository write. Publish its containing commit, then verify exact final main and final-head focused CI/Pages read-only through terminal success. Do not write again to insert final run IDs.

## Visual acceptance limitation

Earlier cloud Chrome opened the public game but reported missing WebGL2. This environment therefore cannot perform a live game visual acceptance pass. This is not evidence the user's phone cannot run the game. This piece is verified by instantiated headless UI behavior and deployment, not a new Safari screenshot test.

## NEXT OPERATION — WAIT FOR USER APPROVAL

Stop after this piece and ask whether to continue with a small food/drink inventory feedback pass: inspect unavailable consumption offers and completion feedback, then repair one concrete issue if found. Do not begin before approval. The whole game is not declared finished.

After approval, at the next distinct code operation delete PromptInventoryFeedbackSmoke.gd / prompt-inventory-feedback.yml and create one fresh module-local pair. Do not run historical suites or routine seed matrices.

## Preserve established behavior and remaining scope

- Preserve vehicle status rows at y520/544 above camera row y574, and plain STORE/TAKE labels.
- Exploration rendering uses actual generated bounds (-408,592,3072,3072), not legacy request bounds. The previous focused production test passed at (2023,1552) and (2025,1552). Keep the 80×96 render window, 128×128 streaming regions and active radius 1.
- Preserve current world generation; streetlights night-only 20:30–05:30 and bounded/shared spacing; exclusive dedicated vehicle rendering without purple diagnostic; existing eight-member infected cohort; authoritative item/action/state ownership.
- Same-tick actor consequences currently resolve sequentially by priority/owner/serial. Simultaneous movement was discussed but is not implemented.
- Future closure should reconcile roadmap with newer owning documents before rebuilding cooking, first aid, vehicle components or repair. Real generated-house environmental-pressure acceptance remains to prove. Survivors/followers/raiders/conversation/outbreak expansion remains roadmap work, not completed content.
