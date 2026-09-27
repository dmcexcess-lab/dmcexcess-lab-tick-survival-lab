# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = independent shelter utilities
ROADMAP_CHANGE = false
```

## Completed / closed for current release

- Phase 1: live survivor/society dependencies retired.
- Phase 2 engineering foundation: shared-tick combat, commitment/interruption, simultaneous melee consequences, causal movement/shove, mob force, canonical fear, bounded eight-infected perception/callback path, coherent consequence presentation and crowded-fight technical acceptance.
- Phase 3 durable continuation: truthful New Game/Continue, explicit Save/Save & Menu, saved-seed reconstruction, versioned checksum-verified primary/backup storage, safe autosave/background checkpoints and in-place restore of existing authoritative WHAT/WHEN/mechanic state.
- Vision observer-pose invalidation regression repaired.
- Lighting presentation simplified to direct tile tint while preserving physical-light gameplay truth.
- Contextual sustainment: inventory EAT/DRINK; furniture REST/SLEEP; powered-fixture DRINK.
- Phase 4 powered cooking: contextual stove -> real carried input/tool -> WHEN craft -> cooked food; live power gates cooking and Continue preserves consequence.
- Phase 4 deconstruction: contextual dining-chair DECONSTRUCT -> tool/Mechanical -> cancelable WHEN -> authoritative removal + existing wood-plank salvage; safe interruption and durable Continue verified.
- Phase 4 existing-building fortification: contextual window/door BOARD layers to the authoritative three-board maximum and materially reduces infected opening-pressure damage.
- Mobile new-game bootstrap repair: removed the disposable full initial-streaming materialization that immediately preceded authoritative materialization and doubled peak world-bootstrap work/memory. Production new-game bootstrap now materializes the selected initial neighborhood once.
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Mobile/Safari bootstrap checkpoint

A real iPhone/Safari playtest reported: menu loads -> NEW GAME starts generation -> WebKit/Godot restarts before the playable map appears.

Targeted source inspection found a concrete peak-memory defect: `_resolve_playable_boot()` fully materialized the initial streaming neighborhood into a disposable probe world, discarded it, and `build()` immediately materialized the same neighborhood again into authoritative WHAT. That probe has been removed. Seed selection still validates generated global truth, the central area and player start before one authoritative initial materialization.

No world size, streaming radius, procedural content or gameplay truth was reduced.

Focused verifier `36281756339`: **SUCCESS**, marker `MOBILE_NEW_GAME_BOOTSTRAP_OK production_boot=true single_initial_materialization=true player=true streaming=true`.

The automated production bootstrap is green. Because the original symptom is a WebKit process restart, the repaired deployed build still requires real iPhone/Safari acceptance. If Safari still restarts, keep this as the active concrete defect and profile the next bootstrap peak rather than advancing gameplay work.

## Active roadmap phase — expedition + fortified-house loop

Once real iPhone/Safari confirms NEW GAME reaches the playable map, continue the next release requirement: practical independent shelter utilities / real utility failure recovery.

Existing production source already contains portable-generator and utility power repair owners. Start there rather than inventing another utility architecture. Inspect only enough current source to identify the first incomplete player-facing power/water route.

A base remains an existing place the player has fortified and supplied. This phase is not permission for freeform construction, settlement management, new society simulation or a new crafting architecture.

## Current interaction invariants

- Survival actions originate from the thing being acted on.
- Food/drink: selected carried item -> EAT/DRINK.
- Bed -> REST/SLEEP; chair/armchair/sofa -> REST.
- Powered potable fixture -> DRINK.
- Stove -> contextual crafting; cooking availability follows live utility power.
- Deconstructable object -> contextual DECONSTRUCT with existing tool/skill requirements.
- Existing door/window -> contextual BOARD/REMOVE BOARD/BREAK/opening actions; BOARD remains available until three layers.
- No generic survival/crafting/construction action strip.
- Existing WHAT/WHEN/combat/perception/lighting/open-world persistence contracts remain fixed unless a concrete defect requires a targeted repair.

## Verification lifecycle

Current prompt-local verifier/workflow:

- `game/scripts/ci/MobileNewGameBootstrapSmoke.gd`
- `.github/workflows/mobile-new-game-bootstrap.yml`

The **next code-changing prompt** must delete that pair before production edits and create one fresh prompt-local verifier/workflow scoped to the actual next operation.

## NEXT

**First acceptance gate: retry NEW GAME on real iPhone/Safari.**

If it reaches the playable map without WebKit/Godot restarting, the concrete regression is closed and the next code operation is Phase 4 independent shelter utilities, starting from the existing portable-generator owners unless targeted inspection finds an earlier missing power/water link.

If Safari still restarts during generation/bootstrap, do not move on to utilities. Continue targeted bootstrap performance diagnosis from the deployed repaired head and remove the next proven peak while preserving procedural world/gameplay truth.
