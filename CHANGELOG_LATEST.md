# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. CHANGELOG.md remains the historical archive.

## Turn-based rewrite Slice 6 — contextual interaction — 2026-09-27

- Canonical pointer/touch interaction now uses the existing InteractionAffordanceQuery + WorldInteractionPanel for action-from-thing discovery/presentation, but disconnects WorldInteractionPlayerController's scheduled execution path.
- Real generated edible/drink items use exact authoritative item identity and existing SurvivorSustainmentProfileCatalog values. EAT/DRINK release and consume the exact item, update canonical conditions and enter the same bounded SimpleTurnController completion seam.
- TurnBasedPlayerShell preserves EquipmentPlayerShell inventory/equipment presentation while delegating EAT/DRINK execution to the migrated route; no generic survival toolbar was introduced.
- Existing potable fixtures expose DRINK. Beds/furniture expose REST/SLEEP. REST advances one explicit hour and SLEEP eight explicit hours through the Slice 5 manual survival clock; neither schedules a long action or advances TickKernel.
- Door OPEN/CLOSE uses existing DoorPhysicalTransitionService and authoritative collision/door state. Window OPEN/CLOSE uses existing WorldInteractableState. Contextual browsing and rejected actions cost zero turns/time.
- Loot SEARCH/pickup contextual offers delegate to the already-migrated Slice 4 route. Crafting workstations retain their contextual discovery/UI entry point for Slice 7; crafting/cooking/healing/repair/deconstruction/vehicle execution was not prematurely migrated.
- Focused production run 36366512080: SUCCESS. Contextual marker: SLICE6_CONTEXTUAL_OK seed=20001 turns=7 survival_tick=162047 eat=true drink=true rest=true sleep=true door=true save=true. Protected combat step also passed, including lethal canonical combat, zero TickKernel advancement and distant-infected inactivity.
- Static guards reject TickKernel/TimedAction/ScheduledEvent dependencies from SimpleTurnController and reject run_until_stop/begin_action underneath the canonical contextual dispatcher.

## Save/menu repair + turn-based rewrite Slice 5 — survival — 2026-09-27

- Root cause of the phone UI regression was twofold: the legacy SessionControls CanvasLayer sat at layer 90 over the canonical shell's layer-40 MENU hitbox, and TurnBasedGameMain had bypassed EnvironmentalPressureGameMain, leaving those visible save controls without their established durable-session signal owner.
- Removed the duplicate SessionControls node from gameplay.tscn. The canonical MENU button is now the only top-right session control; SAVE and SAVE & MENU live inside the existing MENU modal, so they no longer cover or intercept MENU on the 640x844 phone layout.
- TurnBasedGameMain temporarily inherits the established durable-session/condition owner chain as a compatibility bridge. Migrated player actions still execute through SimpleTurnController; the bridge restores the existing DurableSessionStore, Continue validation/restore and canonical condition owners without creating a second save or survival state.
- SAVE uses the existing durable save path. SAVE & MENU performs the real save_and_menu checkpoint, releases the menu/input block, then returns to res://main.tscn. Continue accepts the resulting save through the existing production session validator.
- ActorConditionState / ActorConditionService / ActorConditionModifierQuery remain authoritative. The canonical simple-turn completion seam advances an explicit survival clock by one in-game second (five existing timing units) exactly once per accepted turn without advancing TickKernel.
- Existing satiety, hydration, rest, engagement, comfort, calm, fatigue, condition modifiers, Health pressure and moodlet presentation are reused. Running applies the existing run fatigue rule. Bounded perceived-infected danger and actual injury update the existing Calm/fear state.
- Pure MENU/inventory/loot inspection and rejected actions advance no survival time; render frames advance none. Combat and scavenging each advance survival once regardless of how many local infected act afterward.
- Focused production run 36365188143: SUCCESS, marker SLICE5_SURVIVAL_UI_OK seed=20001 turns=6 survival_tick=30 calm=45 hp=98 save=true menu=true.

## Turn-based rewrite Slice 4 — scavenging and inventory — 2026-09-27

- Canonical SimpleTurnController owns ordinary search, take, store, equip, stow, drop and narrow loose-item pickup actions in addition to movement/combat.
- Real generated LootState / InventoryContainmentState contents remain authoritative; inspection is read-only and never rerolls or respawns removed loot.
- Exact item identity survives real-container take, player containment, equipment, protected melee use, stow, loose-world drop, re-pickup and store back into the original generated container.
- Focused production run 36362797618: SUCCESS, marker SLICE4_SCAVENGE_INVENTORY_OK.

## Turn-based rewrite Slice 3 — simple turn-based combat — 2026-09-27

- Canonical SimpleTurnController accepts player.combat_forward alongside movement; a valid player combat action consumes exactly one ordinary turn before bounded sequential infected actions.
- Forward melee reuses existing physical item impact profiles; firearm state preserves exact firearm/magazine/live-round identities; canonical Health/injury/corpse state remains authoritative.
- Focused production run 36361532785: SUCCESS, marker SLICE3_SIMPLE_COMBAT_OK.

## Turn-based rewrite Slice 2 — plain movement state/query path — 2026-09-27

- Canonical SimpleTurnController no longer depends on SpatialQueryService or WorldMutationService for player/zombie movement.
- Movement legality reads authoritative WorldState terrain/occupancy plus existing collision facts; WorldState.move_entity() is the narrow migrated placement write.
- Production seed 20001 completed consecutive simple turns with zero TickKernel advancement.

## Turn-based rewrite Slice 1 — simple production turn spine — 2026-09-27

- Project direction changed deliberately: preserve the open procedural zombie-survival game while retiring the experimental tick/WHERE/WHAT/WHEN execution architecture route by route.
- Canonical gameplay.tscn boots through TurnBasedGameMain; one movement input performs one ordinary placement mutation and only infected within the bounded active radius receive individual actions.
- Focused run 36352629634: SUCCESS.

## Production infrastructure reservation repair — 2026-09-27

- Real iPhone/Safari NEW GAME exposed an infrastructure reservation edge case. InfrastructureReservationPlanner now keeps the global node as semantic source truth but searches deterministically along its same inherited road for the nearest legal roadside facility footprint.
- Focused run 36350128246: SUCCESS.

## Production world bootstrap separation — 2026-09-27

- Added generation/integration/ProductionWorldBootstrap.gd and removed demo fixture ownership from canonical production startup.
- Production spawn comes from actual generated area sites/roads; durable Continue preserves the same seed/player/world identity.
- Focused run 36348729521: SUCCESS.

## Mobile/Safari rejected-seed recovery — 2026-09-26 (superseded)

- The bounded retry exposed that the canonical runtime still depended on demo bootstrap ownership. Its prompt-local verifier/workflow has been retired.

## Mobile/Safari bootstrap footprint repair — 2026-09-26

- Initial streaming was bounded from a 3x3 128x128 neighborhood to the single 128x128 focus region while preserving the procedural world and streaming identity.
- Focused run 36286982875: SUCCESS.

## Mobile/Safari new-game bootstrap repair — 2026-09-26

- Removed duplicate disposable initial-neighborhood materialization before authoritative world materialization.
- Focused production run 36281756339: SUCCESS.
