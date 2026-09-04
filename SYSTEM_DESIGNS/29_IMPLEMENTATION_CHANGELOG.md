# System 29 — Implementation Changelog

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

### Next closure seam

Use the same unified target/action route for real Mechanical repair of broken existing objects and player-facing utility repair. Those actions must consume exact carried tools/material entities, use Mechanical and real WHEN, and commit into existing object/utility owners. Do not add freeform construction or abstract UI-only repair counters.
