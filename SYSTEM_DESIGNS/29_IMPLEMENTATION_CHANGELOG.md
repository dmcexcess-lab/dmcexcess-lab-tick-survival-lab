# System 29 — Implementation Changelog

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
