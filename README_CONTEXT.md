# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `ROADMAP.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Canonical roadmap: `ROADMAP.md`.

---

## Current playable world

The canonical DEV/playable composition is the **complete streamed island**, not the former standalone Rural Crossroads critique world.

- Global bounds: 1792×1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` v1 adds deterministic LAND / SHORE / OCEAN surface truth over the proven rural-v6 settlement/road/hydrology skeleton.
- The first island deliberately keeps the five proven globally connected settlement sites: one `rural.crossroads`, one `smalltown.center`, and three `rural.scattered` hamlets.
- The broader System-20 suburban/urban/commercial/industrial/civic profiles remain implemented content but are not forced into unsuitable island sites merely to demonstrate them.
- System 00F materializes the island through three non-overlapping logical source families: settlement area sites, the exact physical river/watercourse corridor, and island-surface sources covering everything else inside world bounds.
- Current technical streaming uses 128×128 regions with active radius 1 and follows the controlled survivor's real placement. Those technical regions are performance configuration, never world identity.
- Ocean and ordinary river water are real non-traversable terrain. A river crossing becomes traversable only where System 00D contains matching explicit bridge intent.

The complete-island playable composition was first proven on executable head `3f1a98c3daea879cf7ffdbea717d88461e39438f`.

---

## Current canonical stack

- **00A WHERE** — global integer-cell spatial truth.
- **00B WHAT** — authoritative persistent current world.
- **00C WHEN** — deterministic variable-duration tick/action/pause kernel.
- **00D Global World Planning** — **IMPLEMENTED: `temperate.rural.region` v6 + `temperate.island.region` v1**.
- **01–18** — collision, movement, locomotion, art/rendering, doors, hands, inventory, timed item transfer, actor status scaffolds, carry, HUD/player shell, run/exertion and door passage.
- **19 Building Generation** — finalized 24-archetype one-story library.
- **20 Local Area Generation** — ten area profiles / seven environment palettes, including live river/bridge physicalization.
- **00F Streaming / Materialization** — **IMPLEMENTED: settlement + rural countryside + complete-island surface + river/watercourse logical sources**; one-way materialization, reversible activation.
- **21 Camera** / **22 Large-Area DEV Critique Runtime** — implemented.
- **23 Perception / LOS / Fog Memory** — geometric facing LOS, physical-light/atmosphere-aware current acquisition, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors and auditory presentation.
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE and playable scavenging UI; neutral interaction geometry now comes from System 29.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing/localization, yellow onomatopoeia cues and Weather masking seam.
- **27 Physical Lighting / Illumination / Shadows** — headless physical illumination, rich presentation, illumination-aware observer acquisition, bounded-query optimization, Weather optics and transient lightning input.
- **28 Weather / Atmosphere** — **IMPLEMENTED, Slices A+B+C**: deterministic WHEN-driven Weather, analytic wetness, screen-space low-res atmosphere, real lighting/visibility/hearing consequences and deterministic physical lightning.
- **29 World Interaction Affordance / Reach** — **IMPLEMENTED — Candidate 001**, Roadmap Phase 1A.
- **Performance Architecture Gate** — **IMPLEMENTED + CI VERIFIED — P0/P1/P2**: domain-specific WHAT revisions, explicit bulk-change summaries, streaming notification batching, dependency-correct lighting/shelter invalidation, coalesced perception/interaction wakeups and live DEV telemetry.

System-29 first fully green playable executable head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

Performance-gate first fully green executable head: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

---

## Core rules

1. System 00D owns global coherence; local/stream partitions do not invent world-spanning truth.
2. System 20 turns global facts into local physical areas; System 19 owns building interiors.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. Art/rendering is presentation, not physics.
7. Phone/Safari remains first-class.
8. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.
9. WHEN owns integer simulation ticks only; System 25 interprets them as scenario-local clock time.
10. **Sound is physical; hearing is an estimate.**
11. **Light is physical; vision is observer-specific.** Gameplay/AI never reads rendered pixels as lighting truth.
12. Geometric LOS is a maximum candidate envelope; physical illumination/atmosphere may reduce current acquisition inside it.
13. Player sound presentation never gains exact hidden source truth.
14. **Weather is simulation truth; weather animation is presentation.**
15. Weather feeds Lighting/Hearing through neutral environment seams; it does not become a second light/perception/sound engine.
16. **Weather graphics are screen-space atmosphere. Camera movement itself is not Weather work.**
17. Lightning is a real WHEN event; its physical flash feeds System 27, while its bolt is presentation tied to the same event.
18. Current lightning has no strike cell, therefore there is no fake spatial thunder/damage/fire yet.
19. **Fatigue is the stamina/endurance concept. There is no separate stamina meter.** Sleep pressure/exhaustion remains the longer-horizon sleep need.
20. **Interaction highlights explain real available actions; they never create use/action truth.**
21. **A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.**

---

## Active roadmap work — Phase 1

Phase 1 is decomposed in `ROADMAP.md`:

1A. **Interaction affordance + reach** — **COMPLETE: System 29 Candidate 001.**

1B. **Item freshness/spoilage** — **NEXT DESIGN TARGET**: typed per-instance freshness, analytic authoritative-time aging, future refrigeration-rate seam, no per-item tick loop.

1C. **Semantic inventory/menu icons** — low-resolution UI icon catalog with deterministic coverage of current loot/menu semantics.

1D. **Large/multi-cell object visual geometry** — presentation-owned large draw span/pivot/overhang so multi-cell trees/traffic furniture actually look large without changing collision from art pixels.

1E. **Content expansion/integration** — more perishables, mundane items and world props/fixtures/vegetation using the new foundations.

**Current gate: human iPhone/Safari acceptance of the performance build. After that acceptance, the next bounded work is DESCRIBE Phase 1B / item freshness-spoilage. 1B implementation is not pre-authorized merely because 1A and the CI performance gate are complete.**

---

## Current System 23 perception truth

Visual states remain `UNSEEN`, `REMEMBERED`, and `VISIBLE`. Candidate geometry is a 12-cell, 120-degree forward cone plus radius-1 near awareness. System 23 exposes neutral `VisualAcquisitionProvider`; the live composition injects System 27's illumination/atmosphere-aware provider.

Only acquired cells refresh environment/actor memory. A target may be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark or too strongly extinguished by atmosphere. Opaque geometry still blocks first.

System 29 player highlights consume this existing truth: only current `VISIBLE` target footprint cells may be presented as usable.

Exact-head owner: `verify/system23-perception`.

---

## Current System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

The old private `LootInteractionReach` owner is removed. System-24 search and external-container access both consume System-29 `WorldInteractionReachQuery.CONTACT_FORWARD`, preserving the historical actor-footprint + one-cell-forward rule with zero reach rebalance. The live composition injects one shared reach-query instance into both paths.

System 24 also owns the first System-29 mechanic provider: real searchable containers publish `SEARCH`; decorative nearby objects do not acquire fake interaction truth.

Roadmap Phase 1B adds spoilage on the real stable item identities already created here; Phase 2 crafting consumes those same items.

Exact-head owner: `verify/system24-loot`.

---

## Current Systems 25–28 truth

**25 World Time:** Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically. Phase 1B freshness should derive age analytically from authoritative ticks. Exact context: `verify/system25-world-time-light`.

**26 Spatial Sound:** **Sound is physical; hearing is an estimate.** Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing stats/status; localization uncertainty remains listener knowledge. Weather masks hearing as competing background noise. Current lightning has no fake thunder. Exact context: `verify/system26-spatial-sound`.

**27 Physical Lighting:** **Light is physical; vision is observer-specific.** Gameplay/AI never read rendered pixels as illumination truth. Weather optics/wetness and physical lightning feed the same backend. Exact context: `verify/system27-physical-lighting`.

**28 Weather:** **Weather is simulation truth; weather animation is presentation.** Physical clear/overcast/rain/storm/fog, analytic wetness and deterministic lightning are WHEN-driven. Rain/fog/debris are a low-resolution screen-space overlay whose animation advances zero simulation ticks. Exact context: `verify/system28-weather`.

---

## Current System 29 interaction truth

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

Implemented Candidate 001:

- neutral `CONTACT_FORWARD` = actor footprint + one-cell-forward fringe;
- System-24 search and external TAKE/STORE share the same reach owner;
- real mechanics publish read-only `InteractionOffer` descriptors;
- first provider is System-24 searchable containers / `SEARCH`;
- candidate discovery reads OBJECT occupancy only in the tiny reachable-cell set and performs no full-world entity scan;
- System-23 `VISIBLE` is required for player highlighting; `REMEMBERED` and `UNSEEN` never reveal current usability;
- partially visible multi-cell objects expose only currently visible footprint cells;
- one event-driven renderer at z=90 draws restrained warm/yellow-white pixel corner markers below the System-23 perception overlay;
- multiple offers deduplicate to one target highlight while preserving action identities;
- query/presentation work spends zero WHEN ticks;
- Candidate 001 adds no universal Interact button or action execution.

Exact-head owner: `verify/system29-interaction-affordance`.

First fully green foundation head: `9ccbb91f167c376b6ea4a4d7ff82ede3427ae122`.

First fully green playable-island head: `5b88d9172df51561ea760913873f62bd2cdc422a`.

Human iPhone/Safari visual-tuning acceptance remains useful, but the executable contract is complete.

---

## Current performance architecture truth

> **A world mutation may update truth many times; expensive consumers wake only for the domains and completed batches they actually depend on.**

The first P0/P1/P2 performance gate is implemented. WHAT retains its global authoritative revision and now also exposes terrain and per-placement-channel revisions plus explicit compact `WorldChangeBatch` summaries. System 00F brackets its existing rollback-safe multi-source materialization transaction with that notification batch.

System 27 physical geometry and Weather sky exposure now key to terrain + STRUCTURE truth rather than every global WHAT mutation. ACTOR and ordinary OBJECT churn therefore cannot invalidate static lighting/shelter geometry. Systems 23 and 29 coalesce explicit streaming batches into one locally relevant refresh decision, and System 24 suppresses intermediate interaction-provider broadcasts during the same batch. Lighting presentation likewise ignores unrelated actor/object mutations.

The canonical DEV renderer exposes low-overhead performance telemetry for streaming, lighting simulation/presentation, perception, interaction, Weather drawing and sky exposure. This instrumentation is observation only and never changes simulation behavior.

First fully green executable head: `0398a2a49d84e6067f7610727aecacf4c05fe41f`. All **42 associated workflow runs** completed successfully and all **15 required exact-head contexts** were green on that SHA. Exact performance context: `verify/performance-architecture`.

The remaining acceptance step is a human iPhone/Safari playtest. GPU Weather and predictive/amortized streaming remain measured follow-ups only if that playtest or telemetry still shows a meaningful bottleneck.

---

## Physical-survival correction

Roadmap Phase 4 final target is:

- hunger;
- thirst;
- sleep pressure / exhaustion;
- health / injury;
- **fatigue**.

**Fatigue is the stamina/endurance concept. Do not add a parallel stamina state.** Current fatigue is the short-horizon exertion/endurance pressure; Phase 4 expands its tuning/consequences while keeping sleep/exhaustion as the separate long-horizon need.

---

## Canonical roadmap through Beta

1. **Items/readability** — Phase 1A complete; 1B–1E ahead.
2. **Crafting** — physical recipes, time, real inputs/outputs/workstations.
3. **Power + Water** — three-tier causal infrastructure; standalone wastewater gameplay removed.
4. **Player physical survival/health** — hunger, thirst, sleep/exhaustion, health, fatigue.
5. **Moodlets** — comfort, fear, boredom and escalating hunger/thirst/sleep states with real capability/speed consequences.
6. **Skills/interactions** — Awareness, Sneak, First Aid, Cooking, Carpentry, Mechanical, Electrical, Fishing, Farming; migrate away from current generic skill scaffold; powered objects such as TVs gain real state/light/sound-word interactions.
7. **Vehicles** — cars, trucks, motorcycles, bicycles, skateboards; later Mad-Max-style car/truck modification.
8. **Actor/NPC AI + combat + outbreak** — infected/survivor/follower/raider behavior, all combat, mood/context idle conversations, causal outbreak/population behavior.
9. **Final graphics/UI overhaul** — final button placement, art/readability, item/prop shadows, mobile/desktop polish. **Completion begins Beta.**

Save/load, schema handling, profiling and persistence-backed streaming eviction remain cross-cutting engineering gates inserted when required.

---

## Major deferred/migration seams

- Phase 1B spoilage/freshness;
- Phase 1C semantic icons;
- Phase 1D large-object visual geometry;
- Phase 1E item/object content expansion;
- crafting;
- three-tier power/water utilities;
- current wastewater global-planning data cleanup/inert status;
- full lethal hunger/thirst/sleep/health/fatigue consequences;
- Phase-5 comfort/fear/boredom and consequential mood modifiers;
- Phase-6 final skill catalog migration;
- first aid treatment/infection;
- cooking/carpentry/mechanical/electrical/fishing/farming actions;
- powered appliance/TV interactions;
- vehicles/cargo/modification;
- NPC/infected/follower/raider AI;
- combat and firearm/ammunition mechanics;
- 00E population/household/causal outbreak/player story;
- corpse loot/decay;
- persistence-backed streaming eviction;
- lightning strike geography -> thunder/damage/fire;
- calendar date/season/latitude beyond System 25;
- final Beta graphics/UI pass.

---

## Required executable-head contexts

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

All **15 required contexts** were green on performance-gate executable head `0398a2a49d84e6067f7610727aecacf4c05fe41f`; all **42 workflow runs** associated with that SHA completed successfully.