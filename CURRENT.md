# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 4 / expedition + fortified-house loop
ACTIVE_SLICE = ordinary survival-loop completion
ROADMAP_CHANGE = false
```

## Completed / closed for current release

- Phase 1: live survivor/society dependencies retired.
- Phase 2 engineering foundation: shared-tick combat, commitment/interruption, simultaneous melee consequences, causal movement/shove, mob force, canonical fear, bounded eight-infected perception/callback path, coherent consequence presentation and crowded-fight technical acceptance.
- Phase 3 durable continuation: truthful New Game/Continue, explicit Save/Save & Menu, saved-seed reconstruction, versioned checksum-verified primary/backup storage, safe autosave/background checkpoints and in-place restore of existing authoritative WHAT/WHEN/mechanic state.
- Vision observer-pose invalidation regression repaired.
- Lighting presentation simplified to direct tile tint while preserving physical-light gameplay truth.
- Contextual sustainment: inventory EAT/DRINK; furniture REST/SLEEP; powered-fixture DRINK.
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Durable continuation invariant

Persistence is ordinary infrastructure, not a Tick Lab gameplay mechanic.

- `DurableSessionStore` owns only version/checksum/file/backup/storage-capability concerns.
- The production gameplay root assembles/restores existing authoritative owner snapshots; there is no duplicate saved-game truth model.
- Continue reconstructs the same procedural seed through the established generation path, then restores WHAT, streaming/materialization, WHEN and mechanic owners in place.
- Pending committed actions/events survive Continue. Background/focus loss hard-pauses WHEN before checkpointing; reopening clears only lifecycle hard pause, not committed consequences.
- Invalid/corrupt/incompatible primary data never silently destroys the last valid backup.
- Browser/device storage limitations are surfaced honestly.

Phase 3 production verification is closed:
- protected/focused run `36271614098`: **SUCCESS**;
- durable route marker: `DURABLE_CONTINUATION_OK`;
- protected regressions passed WHEN, WHAT, streaming/materialization, inventory, survivor conditions, power, vehicles, live world interaction, weather and canonical boot;
- code-head Pages run `36271614056`: **SUCCESS** build + deploy.

## Active roadmap phase — expedition + fortified-house loop

Finish the ordinary player loop through natural contextual controls using the systems already present:

- scavenging, carrying and direct item use;
- coherent crafting/cooking and first aid;
- sleep/rest and recovery;
- repairs and deconstruction;
- doors/windows and existing-building fortification;
- readable power/water failure, repair and independent generator/well survival use.

A base is an existing place the player has fortified and supplied. This phase is not permission for freeform construction, settlement management, new society simulation or a new crafting architecture.

Use current production owners/catalogs/actions. Ordinary implementation details use conventional engineering and do not become design discussions.

## Current interaction invariants

- Survival actions originate from the thing being acted on.
- Food/drink: selected carried item -> EAT/DRINK.
- Bed -> REST/SLEEP; chair/armchair/sofa -> REST.
- Powered potable fixture -> DRINK.
- No generic ground REST/SLEEP command and no permanent survival strip.
- Existing WHAT/WHEN/combat/perception/lighting/open-world persistence contracts remain fixed unless a concrete defect requires a targeted repair.

## Verification lifecycle

Current prompt-local verifier/workflow:

- `game/scripts/ci/DurableContinuationSmoke.gd`
- `.github/workflows/durable-continuation.yml`

The **next code-changing prompt** must delete that pair before production edits and create one fresh prompt-local verifier/workflow scoped to the next Phase 4 operation.

## NEXT

**Phase 4 — finish the ordinary expedition + fortified-house survival loop.**

Start from current production source/tests, not architecture rediscovery. Identify the first incomplete player-facing route in the existing scavenging/carrying/item-use/crafting/repair/deconstruction/fortification path and carry that one coherent vertical outcome through production, focused verification and Pages closure. Do not add a new system when an established owner already exists.
