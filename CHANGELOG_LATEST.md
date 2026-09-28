# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. CHANGELOG.md remains the historical archive.

## Turn-based rewrite Slice 7 — craft/cook/heal/repair/deconstruct — 2026-09-27

- Existing crafting recipes now execute through direct canonical commits: current recipe/tool/workstation/skill facts are validated, exact ingredient entities are removed, exact recipe outputs are created into authoritative player containment, and the existing action duration feeds the shared survival-time seam.
- Cooking uses the same recipe route and still obeys PoweredCraftingWorkstationAdapter. Focused seed 20001 correctly leaves the representative stove blocked by its real utility availability instead of faking power; utility migration remains Slice 9.
- Existing first-aid offers now commit through the canonical route. The selected medical resources are consumed by exact identity and the existing ActorHealthState injury record is stabilized/treated according to the existing skill result.
- Existing repair profiles now drive direct broken-object repair with existing tools, materials, Mechanical skill and broken-state ownership. Existing deconstruction profiles remove the actual world object and create their existing salvage semantics in lawful containment/placement.
- TurnBasedPlayerShell preserves the existing phone inventory/equipment UI and adds only first-aid delegation. Contextual workstation/repair/deconstruction presentation remains action-from-thing.
- No canonical Slice 7 action runs TickKernel, TimedAction, ScheduledEvent, run_until_stop or generalized WHEN execution.
- `Slice7GameMain` is a narrow temporary migration composition containing these explicit commits while the older superclass chain still owns persistence/unmigrated systems; it is not a generalized action framework.
- Fresh focused production run 36368972219: SUCCESS. Marker: `SLICE7_OK seed=20001 turns=5 survival_tick=1849 craft=true heal=true repair=true deconstruct=true cook=blocked_by_real_power save=true`.

## Turn-based rewrite Slice 6 — contextual interaction — 2026-09-27

- Canonical pointer/touch interaction uses the existing InteractionAffordanceQuery + WorldInteractionPanel for action-from-thing discovery/presentation while bypassing scheduled WorldInteractionPlayerController execution.
- EAT/DRINK, potable DRINK, REST/SLEEP and door/window OPEN/CLOSE use existing authoritative state and the shared simple-turn/survival seam.
- Focused production run 36366512080: SUCCESS, with protected combat passing.

## Save/menu repair + turn-based rewrite Slice 5 — survival — 2026-09-27

- Removed the duplicate SessionControls layer that covered MENU; SAVE and SAVE & MENU now live inside the canonical phone MENU and use the existing DurableSessionStore/Continue lifecycle.
- Existing authoritative conditions advance once from explicit canonical elapsed time without TickKernel.
- Focused production run 36365188143: SUCCESS.

## Turn-based rewrite Slice 4 — scavenging and inventory — 2026-09-27

- Real generated loot and exact item containment/equipment identity use ordinary search/take/store/equip/stow/drop/pickup actions.
- Focused production run 36362797618: SUCCESS.

## Turn-based rewrite Slice 3 — simple turn-based combat — 2026-09-27

- Canonical melee/firearm combat uses existing Health/injury/equipment/firearm/corpse state and bounded sequential infected actions.
- Focused production run 36361532785: SUCCESS.

## Turn-based rewrite Slice 2 — plain movement state/query path — 2026-09-27

- Canonical movement reads authoritative WorldState terrain/occupancy and writes placement directly without generalized movement execution.

## Turn-based rewrite Slice 1 — simple production turn spine — 2026-09-27

- Project direction changed deliberately to preserve the open procedural zombie-survival game while retiring experimental universal execution architecture route by route.

## Production infrastructure reservation repair — 2026-09-27

- InfrastructureReservationPlanner now searches deterministically along the inherited road for the nearest legal roadside facility footprint.

## Production world bootstrap separation — 2026-09-27

- ProductionWorldBootstrap owns canonical procedural startup; production no longer depends on demo fixtures.

## Mobile/Safari bootstrap repairs — 2026-09-26

- Initial streaming was bounded to the focus region and duplicate disposable neighborhood materialization was removed.
