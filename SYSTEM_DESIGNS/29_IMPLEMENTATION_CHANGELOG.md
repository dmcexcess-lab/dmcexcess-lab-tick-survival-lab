# System 29 — Implementation Changelog

## 2026-09-08 — System 39 environmental pressure / forced-entry closure

Verified functional runtime head before final documentation: `a4126f97ddd26711c768edd92a0cf98b519e3978`

- Closed the first emergent environmental-pressure slice without adding horde AI, group target sharing, a zombie-only timer, pathfinder, crowd multiplier, teleport movement, or a second combat/health stack.
- Added production root layering `game/main.tscn -> EnvironmentalPressureGameMain.gd -> CombatGameMain.gd -> VehicleGameMain.gd`.
- Added one shared actor-generic `ActorOpeningPressureActionService`; it depends on existing placement, opening state, collision, WHEN and System-26 owners rather than `InfectedState`.
- Ordinary infected pursuit still attempts normal movement first. Only after a rejected forward step does the existing collision query identify the exact blocking WHAT entity; if that blocker is a lawful door/window opening, behavior may request generic opening pressure against that exact entity.
- Added timed `opening.try_open` behavior that does not inspect hidden lock truth before physical resolution. Resistance becomes actor/target-local knowledge only after the committed try resolves.
- Added persistent generic opening-condition damage to `WorldInteractableState` rather than zombie-specific building HP. The first slice uses 25 damage per wooden-door body contact and 55 per window contact, with breach at 100; boards reduce each contact rather than creating a crowd-strength abstraction.
- Door breach updates existing canonical truth: broken, unlocked/unboarded, physically opened through `DoorPhysicalTransitionService`, then ordinary collision/movement sees a passable opening.
- Window breach updates existing broken/open truth and delegates subsequent traversal to the already-existing generic `WINDOW_CLIMB` action.
- Opening impacts and breaks emit through System 26 at the exact opening cell. There is no zombie-attraction radius. A second infected can join because its own heard observation causes the existing `investigate_sound` intention.
- Physical congestion remains ordinary ACTOR collision. Only actors that physically reach the opening can contribute their own impact; no synthetic horde-force total exists.
- Fresh prompt-local verifier `PromptEnvironmentalPressureSmoke.gd` + `prompt-environmental-pressure.yml` boots real production `main.tscn` and proves the door pressure chain plus an actor-generic window pressure/climb chain.
- Run `34175706820` exposed a production parser defect from redeclaring inherited `Facing`; only that duplicate declaration was removed.
- Run `34175793072` proved the mechanics but exposed a prompt-fixture LOS setup defect: the prompt-only static blocking semantic occluded System 23 even while its door collision override was open. The verifier was corrected to establish legitimate last-seen knowledge before introducing the barrier; no gameplay assertion was weakened.
- Run `34175935673` succeeded on `a4126f97ddd26711c768edd92a0cf98b519e3978`. It proved: legitimate System-23 pursuit memory; exact locked-door blocker discovery; timed TRY OPEN and learned resistance; repeated 25-point physical impacts; real System-26 propagation; a second no-visual infected independently choosing `investigate_sound`; four-contact door breach; ordinary post-breach movement; preserved actor congestion; generic non-infected window damage; shatter; and existing climb-through traversal.
- Added `SYSTEM_DESIGNS/39_ENVIRONMENTAL_PRESSURE_FORCED_ENTRY.md` at documentation commit `8f3397d99a0fc5f233060251b8a14fa07bb9e7ba`.

### Ownership boundary

System 39 adds only a generic actor/opening pressure action seam and persistent opening-condition consequences. System 23 still owns observer-scoped knowledge; System 26 owns heard observations; WHEN owns time; movement/collision own locomotion and blocker truth; existing door/window owners control passability; System 37 owns actor combat; Health/death own mortality. Infected behavior remains a small intention policy over those owners.

### Next major phase

Do **not** add navigation architecture yet. Use the existing eight-member resident-backed cohort and the exact System-39 production chain against **naturally generated seed-20001 houses and their existing generated doors/windows**. Prove that legitimate visual/last-seen/heard knowledge can lead an infected to a real generated opening, that ordinary collision discovers that exact opening, that System 39 can try/pressure/breach it, that System-26 sound can attract another infected independently, and that ordinary movement/climb traverses the changed opening. Only if this real generated-building scenario exposes a concrete navigation failure should the smallest generic route-planning seam be considered.

---

## 2026-09-08 — Infected 4 → 8 → 16 count ladder; production held at eight

Final functional runtime candidate before documentation: `d3f4a0544be6abec32b084ed77a57880330836be`

- Followed the explicit project rule **complex behavior, simple systems**. No horde brain, AI scheduler, crowd manager, perception queue, new activation radius, group target sharing or zombie-only optimization layer was added.
- Added fresh prompt-local `PromptInfectedCountLadderSmoke.gd` + `prompt-infected-count-ladder.yml`, booting real `main.tscn` and measuring the existing production cohort at controlled counts 4 → 8 → 16.
- The smoke keeps every infected as an exact resident-backed physical ACTOR in the existing technical active stream envelope, proves distinct collision occupancy, proves render frames do not schedule AI, runs an explicit all-observer System-23 perception sweep, then opens ordinary shared WHEN and proves the existing event-driven behavior reacts.
- Count 4 passed on `4d32bd3b848c18731aca96b619a334e905bdb077`, run `34173867420`: perception sweep 60,955 µs; worst behavior evaluation 17,835 µs; worst activation sync 98,580 µs.
- Count 8 passed on `afc5a175f3f0c07827a090cec3f7aa7376b0f74d`, run `34173978788`: perception sweep 113,309 µs; worst behavior evaluation 14,732 µs; worst activation sync 161,719 µs.
- Count 16 passed functionally on `0c0b3e7026afff623e3b2f5cd1129056a05c9eea`, run `34174095120`: perception sweep 233,611 µs; worst behavior evaluation 15,224 µs; worst activation sync 308,325 µs; eight ordinary infected action submissions occurred in the scenario.
- The 16-member result showed no pathological growth in the simple intention/WHEN behavior itself. The expensive seam is the expected roughly linear cost of doing full real System-23 work for more simultaneous observers.
- Targeted inspection confirmed `ActiveInfectedCohortService` already avoids a needless whole-roster rescan on ordinary placement/Health changes: only the changed infected is resynchronized. There was no justified tiny optimization to make before inventing larger machinery.
- Rather than over-engineer around a count that is not yet needed, production was intentionally returned to `ACTIVE_INFECTED_COHORT_SIZE = 8`.
- Final 8-member functional rerun `34174173692` succeeded on `d3f4a0544be6abec32b084ed77a57880330836be`: perception sweep 118,140 µs; worst behavior evaluation 17,430 µs; worst activation sync 165,307 µs; all exact resident/collision/System-23/shared-WHEN assertions remained green.
- The microsecond values are CI-machine observations, not universal budgets. The durable decision is that eight is a useful real production increase from four using the existing simple systems, while sixteen is proven functional but deliberately not adopted yet.

### Ownership boundary

Nothing moved. Population/resident projection owns identity; technical streaming owns active area; System 23 owns observer knowledge; System 26 owns heard observations; WHEN owns time; movement/collision own locomotion and congestion; System 37 owns combat; Health/death own mortality. Scaling remains composition of those systems, not a new zombie simulation.

### Next major phase

Stop scaling counts for now. Use the eight-member cohort to prove **emergent environmental pressure**: sight and sound should drive ordinary pursuit into real doors/windows/barriers, collision should create bunching, and infected should traverse/open/break only through real physical timed actions. If an opening interaction seam is missing for non-player actors, add the minimum generic actor/opening seam rather than horde AI or group coordination.

---

## 2026-09-08 — Small resident-backed infected cohort scaling proof

Verified functional runtime head: `dd178a7c445ea382ea11e27400d3c1c22ec65e79`

- Expanded production from one autonomous infected to a deliberately bounded four-member cohort projected from the existing infected household resident slots. No extra zombie population is created.
- Added deterministic `PopulationResidentProjection.infected_near()` ordering and `FirstInfectedHydrationService.hydrate_cohort()` while preserving exact resident identity, ordinary actor enrollment and collision truth.
- Added `ActiveInfectedCohortService`, which uses the existing `WorldStreamingCoordinator.is_cell_active()` / `active_regions_changed` contract as the sole behavior-activation envelope. There is no second zombie radius.
- A stream-dormant infected keeps exact ACTOR placement, Health, inventory/equipment, condition/skills/carry state and population/infection provenance. Only expensive participation sleeps: System-26 listener registration is removed, System-23 recomputation is gated, and the reused behavior adapter is stopped.
- Stream re-entry reactivates the same resident identity and the same perception/behavior objects; it does not substitute a fresh zombie.
- `StreamingObserverPerceptionService` only gates the ordinary System-23 observer. `CohortInfectedBehaviorService` only adds lifecycle/performance measurement around the already-proven `FirstInfectedBehaviorService` policy.
- Preserved shared WHEN scheduling. A single ordinary player commitment opened the same simulation timeline and two active infected independently submitted ordinary movement/combat actions.
- Preserved physical congestion. Four hydrated ACTORs occupy distinct cells, concurrent actors remain distinct, and ordinary collision sees another infected body as blocking occupancy rather than horde pass-through.
- Generic Health/death remains authoritative: killing one cohort member removes only that actor from active scheduling while another living cohort member continues; population provenance survives.
- Added real production instrumentation for roster/active/dormant counts, activations/deactivations, activation-sync cost, behavior-evaluation cost and ordinary action submissions.
- Fresh prompt-local verifier `PromptSmallInfectedCohortSmoke.gd` + `prompt-small-infected-cohort.yml` boots real `main.tscn` and proves deterministic hydration, streaming exit/re-entry, dormant work suppression, shared-WHEN multi-actor scheduling, congestion, one-member death isolation and measured runtime work.
- Initial run `34172671153` failed before gameplay only because two verifier locals required explicit `Vector2i` typing. Production parsed cleanly; only the smoke typing was corrected and no scaling assertion was weakened.
- Focused run `34172818895` succeeded on `dd178a7c445ea382ea11e27400d3c1c22ec65e79`.
- Measured successful-run values: 4-member roster; 24 behavior evaluations totaling 124,569 µs with 16,672 µs maximum; 7 activation-sync passes totaling 182,013 µs with 95,595 µs maximum; 8 activations, 5 deactivations and 2 ordinary action submissions in the forced scaling scenario.
- The architecture is therefore proven at four active/hydrated residents, but the measured 16.67 ms worst behavior evaluation and 95.60 ms worst activation sync explicitly do **not** justify jumping directly to hordes.

### Ownership boundary

System 38 owns deterministic resident projection/hydration, infection provenance and active/dormant behavior enrollment only. `WorldStreamingCoordinator` owns the technical active envelope; System 23 owns visual knowledge; System 26 owns heard observations; WHEN owns time; ordinary movement/world/collision own locomotion and congestion; System 37 owns attacks; Health/generic corpse transition owns death. No parallel zombie simulation layer was added for scaling.

### Next major phase

Build an **active-cohort scheduling/perception budget + controlled count ladder**. Preserve the exact architecture, profile dormant shared-signal fan-out and activation-time perception work, then test controlled active counts such as 4 → 8 → 16. Stop increasing count when interaction-latency cost crosses the chosen budget. Do not start island-wide hordes or trade observer-scoped knowledge/physical congestion away for scale.

---

## 2026-09-07 — First resident-backed infected autonomous behavior closure

Verified functional runtime head: `90f1c0c974afebcee71403bdd39c8ce4d7a52451`

- Kept the already-hydrated production infected and added `FirstInfectedBehaviorService` as an intention-only adapter over existing simulation owners rather than a zombie-specific AI clock.
- Production gives the exact infected resident its own `ObserverPerceptionService` over shared System-23 memory and the same visual-acquisition/lighting provider used by the player.
- Visible player knowledge is observer-scoped. The infected pursues a currently visible player cell, can continue toward the last seen cell after LOS loss, and never reads exact hidden player placement for visual pursuit.
- Registered the same resident actor as a normal System-26 listener. Unseen sound investigation consumes only `HeardSoundObservation.perceived_cell`/certainty/tick truth and carries no hidden exact source actor identity.
- Added the deliberately small intention vocabulary `idle`, `pursue_visible`, `pursue_last_seen`, `investigate_sound`, and `attack_visible`.
- There is no frame-time zombie loop. While player decision-paused, render frames do not advance the infected. When the player commits an action and the shared WHEN clock opens, the ready infected submits ordinary movement/combat actions; infected action completion can continue the chain while world time is running.
- Pursuit/investigation uses the existing movement owner for physical turns/steps, collision and traversal. Only a bounded deterministic local left/right detour exists; no teleport correction or bespoke path movement was added.
- Contact attack asks System 37 for the currently lawful exact strike and submits that ordinary combat action. The first empty-handed infected therefore reaches the player through movement and lands canonical `combat.strike_unarmed` Health consequences.
- Generic Health/death remains authoritative. HP <= 0 stops behavior because living ACTOR truth disappears; the resident-backed infected submits no more actions while `InfectedState` continues to retain population provenance.
- Fresh prompt-local verifier `PromptFirstInfectedBehaviorSmoke.gd` + `prompt-first-infected-behavior.yml` boots real `main.tscn` and proves pause inactivity, System-23 visual acquisition, visible pursuit, ordinary WHEN movement, System-37 attack/Health damage, System-26 hearing-only investigation toward the perceived cell, no hidden auditory source identity, provenance preservation, and death shutdown.
- Initial run `34171408724` found only parser issues in new composition/test typing; those were corrected without changing behavior semantics.
- Run `34171525608` exposed a verifier fixture defect: its two-step `unplace_entity()` + `set_placement()` relocation truthfully made the production behavior fail-stop during the transient missing-ACTOR state. The fixture was corrected to use `WorldMutationService.set_placement()` as an atomic placement replacement; no gameplay assertion was weakened.
- Focused run `34171663807` then succeeded on `90f1c0c974afebcee71403bdd39c8ce4d7a52451` with the full one-infected perception -> intention -> ordinary WHEN action chain green.

### Ownership boundary

System 38 owns resident projection/infection state and the small intention adapter only. System 23 owns visual knowledge; System 26 owns uncertain heard observations; WHEN owns time/readiness; movement/world/collision own locomotion; System 37 owns physical attack; Health/generic corpse transition owns death. No parallel zombie truth layer exists.

### Next major phase

The one-infected loop is proven. Scale it first to a **small active resident-backed infected cohort**, with explicit activation/streaming and bounded event-driven scheduling/performance rules. Measure before increasing counts; do not introduce per-frame AI loops, magical shared targeting, global aggro radii, or a separate combat clock to make hordes easier.

---

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
- Exact executable `6aab0596cb46d70d4739cbc045d149a25597193d` is green for `verify/world-interaction-closure` run `33915077349`, `verify/system29-interaction-affordance`, protected neighboring statuses and `verify/pages-deploy` run `33915077391`.

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