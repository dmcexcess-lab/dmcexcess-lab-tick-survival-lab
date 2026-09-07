# System 29 — Implementation Changelog

## 2026-09-07 — System 37 combat foundation + first population-backed infected

Integrated functional runtime head: `e997ac13b74a1955fb5fe152f1b0753886009acc`

- Closed the remaining System-37 lethal-combat foundation without adding combat-owned shadow state.
- Added exact firearm/magazine/live-round truth. Firearm and magazine are real containment owners; chamber and inserted magazine store exact WHAT identities; magazine quantity is derived from exact contained round entities rather than an ammo counter.
- Added COMMITTED snap/aimed fire on the shared WHEN clock. Discharge revalidates the exact equipped firearm and chambered round, follows a physical forward grid ray through real terrain/collision, consumes the exact live-round WHAT entity and cycles the next exact magazine round when present.
- Added RESUMABLE reload with explicit eject/insert/chamber phases. Real damage can interrupt reload after an already-completed phase; the physical intermediate state remains authoritative and resume continues the same exact selected magazine/action rather than resetting.
- Routed firearm discharge through System 26 instead of creating a zombie-attraction radius or combat-only hearing layer.
- Added generic Health-driven death/corpse transition. HP <= 0 force-fails the actor's active WHEN action, removes living ACTOR occupancy, creates persistent non-blocking corpse truth and moves the actor's exact carried/equipped WHAT identities into corpse containment without loot copying.
- The first firearm/death run exposed only a Health signal-arity mismatch in the new death listener; production was corrected to the canonical five-argument `hp_changed` contract.
- Reused the existing aggregate island population plan rather than spawning a disconnected production zombie. `PopulationResidentProjection` deterministically names already-counted household resident slots and assigns exactly each settlement's existing infected count from stable world-seed/building/ordinal scores.
- Added `InfectedState` as a state overlay on the shared human `actor.survivor` semantic and `FirstInfectedHydrationService` to materialize one real resident-backed infected near its source household, enrolled in canonical locomotion, hands, containment, Health, skills, carry and condition owners.
- Production boot now hydrates the first infected from the already-generated global population/local-area manifest; it does not rerun all population/local-area generation to create one actor.
- The first infected boot exposed a narrow owner-interface mismatch because Skill/Carry states do not expose `is_ready()` methods. The hydrator was corrected to their actual state/enrollment API.
- Fresh prompt-local verifier `PromptCombatFirearmDeathSmoke.gd` + `prompt-combat-firearm-death.yml` boots real `main.tscn`, proves resident provenance, exact firearm/ammunition containment, interrupted/resumed reload, physical firing, System-26 sound and generic corpse transition on that exact production-hydrated infected.
- Integrated focused run `34170545140` succeeded on `e997ac13b74a1955fb5fe152f1b0753886009acc` with all firearm/reload/death/first-infected assertions green.

### Ownership boundary

System 37 owns combat action semantics and firearm state only. WHEN remains the clock/interruption owner; Inventory/hand equipment own containment and assignment; Health owns HP/injury; System 26 owns hearing; world/collision own physical placement. System 38 projects/materializes identities already counted by population planning and records infection state; it does not create a second population or bespoke zombie health/combat stack.

### Next major phase

Keep exactly the first resident-backed infected and give it the first autonomous **perception -> intention -> ordinary WHEN action** loop. It must consume existing System-23 vision / System-26 heard observations and submit ordinary movement/System-37 combat actions. Do not create a zombie-specific tick, teleport movement, attack cooldown or magic attraction radius; prove one actor before scaling hydration.

---

## 2026-09-07 — Human/mobile interaction practicality closure

Verified functional runtime head: `69bd99983dc07865caa37a570ec352f760db864a`

- Audited the production pointer, chooser, movement-control and inventory/modal seams from the player's perspective rather than adding new gameplay.
- Found a systemic overlap defect in `WorldInteractionPlayerController`: when several actionable physical entities occupied the clicked cell, presentation priority silently chose only one target and made the others unreachable. The controller now preserves every routed exact target on the clicked cell, orders them deterministically, and passes all truthful target/action groups into one chooser.
- Exact target identity remains authoritative through dispatch. Choosing an action for one overlapping object cannot silently operate a different nearer/higher-priority object.
- Reworked `WorldInteractionPanel` presentation for touch practicality: action and cancel controls are 52 px tall, the action list scrolls, width responds to the viewport, and the panel is clamped inside the visible viewport.
- The first prompt-local production-scene verifier caught a real post-container-layout overflow even after the initial responsive sizing change. The panel now performs a deferred post-layout clamp so its settled minimum size cannot push the chooser off-screen.
- Existing modal blocking remains authoritative: while the chooser is open the production pointer/movement/camera route is blocked, and pointer input is restored after close/selection.
- Existing `DoorPointerInputAdapter` remains the single mouse/touch world-cell input owner, including drag rejection and synthetic-mouse suppression after touch. No duplicate touch listener was introduced.
- Existing inventory EAT/DRINK, exact flashlight item actions, movement controls and other mechanic-owned surfaces were audited in place; this pass did not duplicate their owners or reopen their mechanics.
- Added prompt-local `PromptHumanMobileInteractionSmoke.gd` + `prompt-human-mobile-interaction.yml`. It boots the real `main.tscn`, creates two prompt-only overlapping actionable entities, verifies both remain reachable, checks >=48 px action surfaces and viewport containment, selects the lower-priority exact target, and verifies pointer blocking/restoration.
- Focused run `34106166284` succeeded on `69bd99983dc07865caa37a570ec352f760db864a`; Pages run `34106166327` also succeeded on that exact functional head.
- The previous prompt-owned vehicle-maintenance verifier/workflow were retired at prompt start as required. Vehicle gameplay itself was not changed.

### Ownership boundary

This closure changes only player routing/presentation. Affordance providers, WHAT identity/placement, item transfer/equipment, opening state, Loot, Crafting, utilities, vehicles and WHEN consequences remain with their existing owners. Presentation priority orders choices; it never replaces exact physical identity.

### Next major phase

Human/mobile interaction is practical through the available production-scene verification and source audit. No combat, NPC or infected work was added here. The next major phase is combat; after combat is practical, hydrate the first real infected from the existing population records.

---

## 2026-09-04 — Quiet-entry opening behavior

Executable lineage is protected in verified flashlight executable `e4e5ccfadd087186e6addf937ad8c4ace5e5a818`.

- Removed player-facing **LOCK / UNLOCK** actions from ordinary door/window interaction. Lock state is world/opening truth, not a routine player toggle system.
- There is no house-key inventory and no house-wide authoritative `locked` boolean. Exterior doors and windows independently derive deterministic generated lock state from stable opening identity, with explicit state retained for mutations/snapshots.
- A closed unlocked opening truthfully offers **OPEN**. A closed locked opening suppresses OPEN, leaving the player to check another exterior opening or choose noisy forced entry with **BREAK**.
- This establishes the intended survival tradeoff: spend time/exposure walking the perimeter looking for quiet access versus make noise and force entry. Future zombie/perception work must consume the real sound consequence rather than a special-case entry flag.
- Broken/open windows continue to use real collision/spatial **CLIMB THROUGH** behavior. Boarding remains the survival closure for a shattered opening; there is intentionally no replacement-glass repair item or fake broken-window REPAIR action.
- Boarding/removing boards and broken-door repair continue through their existing exact tools/materials + Mechanical + WHEN owners.
- `PlayerWorldUiRouteSmoke.gd` now proves quiet OPEN availability for an unlocked fixture, absence of player LOCK/UNLOCK controls, suppression of OPEN for a locked fixture, and continued BREAK availability, while retaining board/break/climb coverage.

### Ownership boundary

The unified chooser only reflects the exact opening's current owner state. It does not infer a house-level access state, invent keys, or store UI-only lock truth.

### Next closure seam

The flashlight item/switch route that followed this change is now complete at executable `e4e5ccfadd087186e6addf937ad8c4ace5e5a818`. Continue player/world closure with generator operation/fuel/start-stop.

---

## 2026-09-04 — Mechanical repair + physical utility repair closure

Verified executable runtime head: `6aab0596cb46d70d4739cbc045d149a25597193d`

- Added real Mechanical repair of supported broken existing doors through the unified exact-target chooser.
- Door repair requires the persistent target to still be broken, retains a real carried hammer, consumes one real wood plank plus one real nails box, spends real WHEN, and restores the existing canonical broken/door/collision state.
- Intentionally did **not** add shattered-window repair because the current item catalog has no truthful replacement-glass resource entity. Windows remain break/board/climb capable until glass replacement exists as real inventory/world truth.
- Added real player-facing repair of failed persistent wooden distribution supports. The clicked WHAT pole maps directly to its existing System-33B `distribution_support` asset; System 29 does not copy utility condition.
- Utility support repair retains a real carried hammer, consumes two real wood planks plus one real nails box, checks the player-facing Mechanical requirement, spends real WHEN and commits through `UtilityPowerNetworkRuntime`.
- Reused the utility runtime snapshot/restore contract transactionally so partial repair cannot leave inventory, asset condition and service outage out of sync.
- A successful pole repair restores only outage state causally owned by that failed asset; healthy poles no longer offer REPAIR.
- Distribution spans remain real System-33B condition assets but still lack an independent clickable WHAT identity, so ordinary player-facing wire repair is deliberately not faked.
- Tightened native timed-action result reporting in `WorldInteractionPlayerController`: success now requires the exact accepted WHEN serial to terminate as `COMPLETED`. A failed commit can no longer be misreported simply because the survivor stopped being busy.
- Added `WorldObjectRepairUiSmoke.gd` and `UtilityPowerRepairUiSmoke.gd` to the dedicated `verify/world-interaction-closure` owner.
- The first utility UI smoke exposed a real chooser lifecycle defect after a successful repair: `WorldInteractionPanel.close_panel()` hid the panel but retained obsolete action-button nodes. The provider and canonical utility state were already correct. Production close/open lifecycle now clears stale controls rather than weakening the test.
- Exact executable `6aab0596cb46d70d4739cbc045d149a25597193d` is green for `verify/world-interaction-closure` run `33915077349`, `verify/system29-interaction-affordance`, `verify/system33-power-water`, protected neighboring statuses and `verify/pages-deploy` run `33915077391`.

### Protected ownership

System 29 remains presentation/routing only. Door/world broken state stays with the existing world-interaction/door owner; physical network condition and outage truth stay with System 33B/System 33; inventory remains real carried-entity truth; action timing remains WHEN.

### Next closure seam

Use the same exact-target route for **fixed light/switch interaction and persistent flashlight on/off state**, reusing existing System-27/System-33 lighting and equipped-item truth. Do not add UI-owned light state. After that, close generator operation/fuel/start-stop through real utility/item owners.

---

## 2026-09-04 — Unified player world interaction routing

Executable runtime head: `942b461a8be9c2646f0fd61d7cefbdd04bbe1e7e`

CI-only corrected verification head: `3cb2092c93f170811c6be343f701874f3a565bdb`

- Replaced competing production world-pointer listeners with one `WorldInteractionPlayerController` chooser fed by the shared System-29 affordance set.
- Added an explicit delegated-handler seam so exact-target Crafting and Loot actions return to their existing canonical owners without fake action serials or UI-owned consequences.
- Removed the prior category suppression that hid native world actions whenever a target also had a Crafting or Loot offer.
- A powered stove can now truthfully expose both **CRAFT** and **DECONSTRUCT** from one world click; CRAFT delegates the exact stove to the existing cooking panel.
- Searchable containers now route through the same chooser, then invoke the real timed System-24 search and open the existing Loot panel only after success.
- Native door/window/sustainment/deconstruction actions now receive normal HUD completion feedback while delegated Crafting/Loot keep their own result presentation.
- Added stable exact-target/action metadata to chooser buttons for live-scene verification.
- Added `PlayerWorldUiRouteSmoke.gd`, which drives the real world-pointer signal and real buttons for sink DRINK, bed SLEEP/REST, door OPEN/CLOSE/LOCK/UNLOCK, window OPEN/CLIMB/CLOSE/BOARD/BREAK/CLIMB, stove CRAFT + DECONSTRUCT coexistence, searchable-container SEARCH and furniture DECONSTRUCT.
- The first new route-smoke run exposed a test-fixture placement error on the second broken-window climb. Production parsing and the existing world-interaction smoke were already green. The fixture was tightened to preserve a clear far-side destination; no runtime rollback was required.
- Corrected head `3cb2092c93f170811c6be343f701874f3a565bdb` completed the owning `verify/world-interaction-closure` gate successfully. `verify/system29-interaction-affordance` and `verify/pages-deploy` were also green on the exact head.

### Protected ownership

This change did not move simulation truth into UI. Loot, Crafting, door/window state, sustainment, WHAT mutation, Mechanical checks and WHEN timing remain with their existing owners. The chooser only presents and routes current legal offers.

### Historical next closure seam

At this checkpoint the next target was real Mechanical repair of broken existing objects and player-facing utility repair using exact carried entities. That seam is now completed by the verified Mechanical-repair closure above.