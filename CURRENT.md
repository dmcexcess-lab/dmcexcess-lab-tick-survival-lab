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
- Phase 4 existing-building fortification: contextual window/door BOARD can now be layered to the authoritative three-board maximum; each layer uses existing hammer + plank + nails + Mechanical/WHEN semantics, materially reduces infected opening-pressure damage, renders from authoritative interaction state and persists through Continue.
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Phase 4 fortification invariant

- Fortification is an interaction on an existing opening, not construction or base placement.
- `WorldInteractableState` remains the board/damage truth and caps openings at three board layers.
- The existing contextual `WorldInteractionOfferProvider` exposes BOARD while an opening has fewer than three boards; REMOVE BOARD/BREAK remain ordinary contextual alternatives.
- Each BOARD is the existing timed WHEN action requiring hammer, one wood plank, one nails box and Mechanical semantics. Materials are consumed exactly once; the hammer is preserved.
- `ActorOpeningPressureActionService` reads authoritative board count. The active infected behavior uses that same pressure service when blocked by a door/window.
- Verified opening-pressure damage: 55 unboarded -> 40 at three boards. Fortification therefore changes breach resistance, not only presentation.
- `WorldInteractionStateRenderer` derives board visuals from authoritative interaction state.
- Durable Continue preserves board count, opening damage, tool state and consumed-material consequences.

Focused production verifier `36276349197`: **SUCCESS**, marker `PHASE4_FORTIFICATION_ROUTE_OK contextual=true timed=true boards=3 materials_once=true tool_preserved=true baseline_damage=55 fortified_damage=40 infected_pressure_owner=true continue=true`.

## Active roadmap phase — expedition + fortified-house loop

The ordinary shelter loop now has contextual food/drink, first aid, rest/sleep, repair owners, powered cooking, deconstruction and meaningful opening fortification. The next release requirement not yet closed vertically is practical independent shelter utilities / real utility failure recovery.

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

- `game/scripts/ci/Phase4FortificationRouteSmoke.gd`
- `.github/workflows/phase4-fortification-route.yml`

The **next code-changing prompt** must delete that pair before production edits and create one fresh prompt-local verifier/workflow scoped to the chosen independent-utility/failure-recovery route.

## NEXT

**Phase 4 — finish the first missing independent-shelter utility route, starting from the existing portable-generator owners unless targeted production inspection identifies an earlier missing power/water failure/repair link.**

The player-facing outcome should close one real survival dependency end to end: an existing shelter loses or lacks ordinary utility service; the player uses the already-established tool/item/utility owners to provide or restore useful service; the service actually powers/feeds existing gameplay such as lighting, cooking, refrigeration or potable water; resource/fuel/tool consequences are real; and save -> reopen -> Continue preserves the result. Use the simplest existing power/water architecture. Do not create a utility-building or base-management system.
