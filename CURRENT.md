# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = deconstruction
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
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Phase 4 cooking invariant

- System 32 remains the recipe/workstation/plan/action authority.
- System 33 remains the only power truth. `PoweredCraftingWorkstationAdapter` only feeds live power availability into the existing System 32 workstation-provider seam.
- Cooking creates no appliance state owner and no second crafting architecture.
- Stove interaction continues to originate from the stove through the established contextual crafting offer/panel.
- Unpowered stove -> cooking blocked. Powered stove + real carried ingredients/tool -> existing timed crafting action.
- Inputs are consumed through WHAT/inventory exactly once; tools are preserved; output returns to carried inventory and immediately participates in established item-use actions.
- Durable Continue persists the resulting WHAT/inventory consequence; persistence itself remains closed Phase 3 infrastructure.

Focused production verifier `36273690260`: **SUCCESS**, marker `PHASE4_COOKING_ROUTE_OK`.

## Active roadmap phase — expedition + fortified-house loop

Continue through natural contextual controls using systems already present. First aid and rest/sleep already have production player routes. Repair owners/routes already exist. The next absent link found in current production source is deconstruction; repository search contains no production deconstruction route.

A base is an existing place the player has fortified and supplied. This phase is not permission for freeform construction, settlement management, new society simulation or a new crafting architecture.

## Current interaction invariants

- Survival actions originate from the thing being acted on.
- Food/drink: selected carried item -> EAT/DRINK.
- Bed -> REST/SLEEP; chair/armchair/sofa -> REST.
- Powered potable fixture -> DRINK.
- Stove -> contextual crafting; cooking availability follows live utility power.
- No generic survival/crafting action strip.
- Existing WHAT/WHEN/combat/perception/lighting/open-world persistence contracts remain fixed unless a concrete defect requires a targeted repair.

## Verification lifecycle

Current prompt-local verifier/workflow:

- `game/scripts/ci/Phase4CookingRouteSmoke.gd`
- `.github/workflows/phase4-cooking-route.yml`

The **next code-changing prompt** must delete that pair before production edits and create one fresh prompt-local verifier/workflow scoped to deconstruction.

## NEXT

**Phase 4 — implement the first real player-facing deconstruction route.**

Start from the existing contextual world-interaction, tool/resource, WHEN, WHAT/inventory and repair/crafting owners. Choose one ordinary existing-world object for which deconstruction is useful to the fortified-house loop, require the appropriate existing tool/skill/material semantics, resolve it as a real timed action, remove/change the target through authoritative WHAT, return plausible salvage through existing inventory/world item truth, and prove save -> reopen -> Continue preserves the result without duplicating salvage or resurrecting the object. Do not build a generic construction engine or a parallel crafting/deconstruction architecture.
