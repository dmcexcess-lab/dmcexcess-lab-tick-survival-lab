# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = existing-building fortification
ROADMAP_CHANGE = false
```

## Completed / closed for current release

- Phase 1: live survivor/society dependencies retired.
- Phase 2 engineering foundation: shared-tick combat, commitment/interruption, simultaneous melee consequences, causal movement/shove, mob force, canonical fear, bounded eight-infected perception/callback path, coherent consequence presentation and crowded-fight technical acceptance.
- Phase 3 durable continuation: truthful New Game/Continue, explicit Save/Save & Menu, saved-seed reconstruction, versioned checksum-verified primary/backup storage, safe autosave/background checkpoints and in-place restore of existing authoritative WHAT/WHEN/mechanic state.
- Vision observer-pose invalidation regression repaired.
- Lighting presentation simplified to direct tile tint while preserving physical-light gameplay truth.
- Contextual sustainment: inventory EAT/DRINK; furniture REST/SLEEP; powered-fixture DRINK.
- Phase 4 powered cooking route: generated stove -> contextual crafting UI -> real carried input/tool -> WHEN craft -> cooked inventory output; live power loss blocks cooking and restored power re-enables it; cooked food exposes EAT and persists through Continue without resurrecting consumed input.
- Phase 4 contextual deconstruction route: dining chair -> DECONSTRUCT -> hammer/crowbar + Mechanical requirement -> cancelable WHEN action -> authoritative removal + one existing wood plank; interruption is consequence-free and Continue preserves removal/salvage identity without duplication.
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Phase 4 deconstruction invariant

- Deconstruction remains part of the established world-interaction owner, not a construction/crafting subsystem.
- Actions originate from the target object through the contextual world-cell interaction panel.
- Existing tool semantics, Mechanical skill state, WHEN action scheduling and WHAT/inventory mutation own requirements and consequences.
- Pre-commit cancellation leaves the target intact and creates no salvage.
- Successful completion removes the target through authoritative WHAT, preserves the tool and creates salvage through existing item/inventory/world truth exactly once.
- Durable Continue preserves the removal and salvage identity; persistence itself remains closed Phase 3 infrastructure.

Focused production verifier `36275247010`: **SUCCESS**, marker `PHASE4_DECONSTRUCTION_ROUTE_OK target=dining_chair contextual=true timed=true interrupted_safe=true removed=true salvage=wood_plank salvage_once=true tool_preserved=true continue=true`.

## Active roadmap phase — expedition + fortified-house loop

Continue through natural contextual controls using systems already present. First aid, rest/sleep, repair, powered cooking and first deconstruction are production-routed. Repository search found no existing boarding/barricade/fortification route, making existing-building fortification the next missing player-facing link.

A base is an existing place the player has fortified and supplied. This phase is not permission for freeform construction, settlement management, new society simulation or a new crafting architecture.

## Current interaction invariants

- Survival actions originate from the thing being acted on.
- Food/drink: selected carried item -> EAT/DRINK.
- Bed -> REST/SLEEP; chair/armchair/sofa -> REST.
- Powered potable fixture -> DRINK.
- Stove -> contextual crafting; cooking availability follows live utility power.
- Deconstructable object -> contextual DECONSTRUCT with existing tool/skill requirements.
- No generic survival/crafting action strip.
- Existing WHAT/WHEN/combat/perception/lighting/open-world persistence contracts remain fixed unless a concrete defect requires a targeted repair.

## Verification lifecycle

Current prompt-local verifier/workflow:

- `game/scripts/ci/Phase4DeconstructionRouteSmoke.gd`
- `.github/workflows/phase4-deconstruction-route.yml`

The **next code-changing prompt** must delete that pair before production edits and create one fresh prompt-local verifier/workflow scoped to the chosen fortification route.

## NEXT

**Phase 4 — implement the first real existing-building fortification route, starting with boarding an existing window unless targeted current-source inspection identifies an earlier missing fortification link.**

Use the existing window/opening world truth, contextual interaction model, carried tools/materials, skills, WHEN actions, WHAT/inventory consequences and persistence owners. The player should stand beside an existing window/opening, have the ordinary required tool/materials, choose a contextual fortification action, spend real action time, and leave that existing opening materially harder for zombies to cross. Consume materials exactly once, preserve ordinary tools, make the changed opening affect the existing opening/pressure/traversal mechanics rather than only presentation, and prove save -> reopen -> Continue preserves the fortification without restoring materials or duplicating the modification. Do not create freeform construction, wall placement, a base-building grid or a parallel structure-state architecture.
