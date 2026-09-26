# Tick Survival Lab — Current State

Status: **canonical active working state**

This file is intentionally small. It records current truth, not history. Changelogs/Git retain evidence and chronology.

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = sprite-based zombie survival
CORE_LOOP = scavenge -> fight -> craft -> survive
ACTIVE_PHASE = 3 / durable save, leave, continue
ACTIVE_SLICE = durable continuation
ROADMAP_CHANGE = false
```

## Completed / closed for current release

- Phase 1: live survivor/society dependencies retired.
- Phase 2 engineering foundation: shared-tick combat, commitment/interruption, simultaneous melee consequences, causal movement/shove, mob force, canonical fear, bounded eight-infected perception/callback path, coherent consequence presentation and crowded-fight technical acceptance.
- Vision observer-pose invalidation regression repaired.
- Lighting presentation simplified to direct tile tint while preserving physical-light gameplay truth.
- Contextual sustainment restored: inventory EAT/DRINK; furniture REST/SLEEP; powered-fixture DRINK.
- Permanent generic survival-action strip removed.

Do not reopen these merely for improvement. A concrete active-play defect may justify a targeted repair.

## Active slice — durable continuation

### Goal

A player can mutate meaningful player/world state, leave the game, reopen it and continue the same persistent game.

### Required continuity

Use the existing authoritative stores/snapshots as sources for a versioned durable session. The completed path must preserve the release-relevant state described in Roadmap Phase 3, including player position/state, inventory/equipment, world mutations/loot, actors/zombies/corpses, vehicles, structures/fortifications, utilities, day/weather and necessary WHEN/action state.

### Definition of done

- New Game and Continue are truthful and understandable.
- Save -> leave/close -> reopen -> Continue restores the same game.
- Repeated save/load does not duplicate consumption, rewards, loot, actors or vehicles.
- Pending committed actions cannot be canceled/exploited through save/load/backgrounding.
- Invalid/incompatible saves fail safely without silently destroying the last valid save.
- Browser storage failure is surfaced honestly.

### Boundaries

Do not use this slice to add:

- camping/sleeping-bag features;
- a crafting overhaul;
- vehicle parking enrichment;
- environmental stories;
- new combat mechanics;
- society/NPC simulation;
- a new world-generation architecture.

## Deferred established roadmap

After Phase 3:

1. finish the ordinary expedition + fortified-house survival loop, including coherent crafting/repair/deconstruction interactions;
2. contextual vehicle parking/site enrichment;
3. persistent environmental stories;
4. integrated multi-day balance/content tuning;
5. release acceptance, including real mobile/Safari acceptance.

Camping/portable rest is a possible later crafting/survival-content idea, not an active roadmap slice and not approved as a one-off system.

## Current interaction invariants

- Survival actions originate from the thing being acted on.
- Food/drink: selected carried item -> EAT/DRINK.
- Bed -> REST/SLEEP; chair/armchair/sofa -> REST.
- Powered potable fixture -> DRINK.
- No generic ground REST/SLEEP command and no permanent survival strip.

## Verification lifecycle

The previous code prompt left:

- `game/scripts/ci/ContextualSustainmentRoutesSmoke.gd`
- `.github/workflows/contextual-sustainment.yml`

The **next code-changing prompt** must delete that pair before production edits and create one fresh prompt-local verifier/workflow scoped only to durable continuation.

This documentation-only context migration does not create or run a gameplay verifier because it changes no production behavior.

## NEXT

**Resume established Roadmap Phase 3: durable save / leave / reopen / Continue.**

Do not replace this with a recently discussed feature unless the user explicitly changes roadmap priority.
