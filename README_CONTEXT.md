# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `ROADMAP.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**
>
> **The low-resolution 2D presentation and turn-based simulation are deliberate performance advantages. Spend that budget on simulation depth, persistence, world scale and responsiveness — not avoidable work.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

---

## Current playable world

The canonical DEV/playable composition is the **complete streamed island**.

- Global bounds: 1792×1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` v1 overlays deterministic LAND / SHORE / OCEAN on the proven rural-v6 settlement/road/hydrology skeleton.
- Five globally connected sites remain proven: one `rural.crossroads`, one `smalltown.center`, three `rural.scattered` hamlets.
- System 00F materializes non-overlapping settlement, river/watercourse and island-surface logical sources.
- Technical streaming is 128×128 with active radius 1 and follows the survivor. Technical regions are performance configuration, never world identity.
- Ocean/ordinary river water is non-traversable except explicit planned bridge deck.

---

## Current implemented stack

Foundation and gameplay through **System 29** are implemented, including persistent WHAT, deterministic WHEN, complete-island generation/streaming, inventory/transfer/carry, 24 building archetypes, ten local-area profiles, perception, persistent loot/search, world time/daylight, spatial sound, physical lighting, Weather and interaction affordance/reach.

Important current rules:

1. Generation creates virgin truth once; WHAT + typed mechanic stores own current reality afterward.
2. Technical streaming activation is not world existence.
3. Art/rendering is presentation, never physics/simulation authority.
4. Phone/Safari is first-class.
5. Sound is physical; hearing is an estimate.
6. Light is physical; vision is observer-specific.
7. Weather is simulation truth; weather animation is presentation.
8. Fatigue is the stamina/endurance concept; there is no parallel stamina meter.
9. Interaction highlights explain already-valid actions; they never create action truth.
10. Expensive consumers wake only for the domains/completed batches they actually depend on.

---

## Performance architecture / Weather gate — HUMAN ACCEPTED

The P0/P1/P2 performance architecture plus Weather P3/P3B/P3C/P3D is now accepted by human playtest.

First P0/P1/P2 fully green executable: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Human-accepted Weather P3D executable:

`6016fe5098804e3e6aba6c9f5f9658282036a697`

P3/P3D result:

- continuous rain/fog is one persistent GPU atmosphere surface;
- no CPU continuous-rain/fog redraw loop;
- camera movement does zero Weather redraws and does not restart animation;
- shelter is a cached low-resolution texture;
- base Weather art scale is 2 screen pixels;
- rain falls explicitly toward increasing screen Y;
- P3B de-tiles density, P3C varies local motifs, P3D breaks shared vertical macro-row cadence;
- physical Weather/wetness/light/hearing/vision truth is unchanged;
- P3D exact head completed 42/42 associated workflows and all 15 required exact-head contexts successfully.

**The pre-1B human performance gate is CLOSED.** Predictive/amortized streaming remains measured follow-up only if future evidence justifies it.

---

## Active work — Roadmap Phase 1B

### System 30 Item Freshness / Spoilage — DRAFT

Canonical draft:

`SYSTEM_DESIGNS/30_ITEM_FRESHNESS_SPOILAGE.md`

Lifecycle:

**DESCRIBE COMPLETE -> awaiting APPROVE -> then IMPLEMENT -> VERIFY**

Core proposed rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Candidate architecture:

- explicit semantic perishable profiles only;
- typed per-instance freshness records only for perishables;
- FRESH / AGING / STALE / SPOILED derived analytically;
- no per-item `_process`, timer or WHEN spoilage event;
- integer fixed-point cumulative spoilage-exposure clocks;
- ambient Candidate 001 exposure now; future real refrigeration plugs in through a neutral context clock rather than waking every item;
- virgin world perishables use logical scenario origin tick 0, so late technical materialization never creates magically fresh food;
- bounded deterministic initial-age variation prevents every identical food item from aging in lockstep;
- refrigerators do **not** fake cooling until Phase 3 provides real power/appliance truth;
- inventory/container inspection shows coarse freshness state;
- Phase 4 later owns eating/drinking/health consequences.

**System 30 code is not yet authorized. User approval of the draft is the next gate.**

---

## Phase 1 remaining order

1A. Interaction affordance + reach — **COMPLETE**.

1B. Item freshness/spoilage — **DESCRIBE COMPLETE; awaiting approval**.

1C. Semantic inventory/menu icons.

1D. Large/multi-cell object visual geometry.

1E. Content expansion/integration.

Then: Crafting -> Power + Water -> physical survival/health -> Moodlets -> Skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.

---

## Relevant 1B ownership boundaries

- System 11 owns containment.
- System 12 owns timed physical item transitions.
- System 13D owns semantic physical weight.
- System 24 owns what virgin loot exists and keeps the rule **loot exists before you search for it**.
- System 25 interprets authoritative WHEN ticks as simulation time.
- System 30 may consume those seams but must not replace them.
- Phase 3 Power/Refrigeration later provides real cold-storage exposure; System 30 must not import/fake Power.
- Phase 4 later interprets freshness for nutrition/sickness/health consequences.

---

## Required executable-head contexts currently

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/system25-world-time-light`
- `verify/system26-spatial-sound`
- `verify/system27-physical-lighting`
- `verify/system28-weather`
- `verify/system29-interaction-affordance`
- `verify/performance-architecture`
- `verify/pages-deploy`

If System 30 is approved/implemented, proposed new permanent context: `verify/system30-item-freshness`.
