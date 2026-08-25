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

The canonical DEV/playable composition is now the **complete streamed island**, not the former standalone Rural Crossroads critique world.

- Global bounds: 1792×1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` v1 adds deterministic LAND / SHORE / OCEAN surface truth over the proven rural-v6 settlement/road/hydrology skeleton.
- The first island deliberately keeps the five proven globally connected settlement sites: one `rural.crossroads`, one `smalltown.center`, and three `rural.scattered` hamlets.
- The broader System-20 suburban/urban/commercial/industrial/civic profiles remain implemented content but are not forced into unsuitable island sites merely to demonstrate them.
- System 00F materializes the island through three non-overlapping logical source families: settlement area sites, the exact physical river/watercourse corridor, and island-surface sources covering everything else inside world bounds.
- Current technical streaming uses 128×128 regions with active radius 1 and follows the controlled survivor's real placement. Those technical regions are performance configuration, never world identity.
- Ocean and ordinary river water are real non-traversable terrain. A river crossing becomes traversable only where System 00D contains matching explicit bridge intent.

The complete-island playable composition was first proven on executable head `3f1a98c3daea879cf7ffdbea717d88461e39438f`; current `main` may contain later documentation/contract refreshes.

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
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE and playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing/localization, yellow onomatopoeia cues and Weather masking seam.
- **27 Physical Lighting / Illumination / Shadows** — headless physical illumination, rich presentation, illumination-aware observer acquisition, bounded-query optimization, Weather optics and transient lightning input.
- **28 Weather / Atmosphere** — **IMPLEMENTED, Slices A+B+C**: deterministic WHEN-driven Weather, analytic wetness, screen-space low-res atmosphere, real lighting/visibility/hearing consequences and deterministic physical lightning.
- **29 World Interaction Affordance / Reach** — **APPROVED — Candidate 001**, Roadmap Phase 1A; implementation authorized 2026-08-24.

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

---

## Active roadmap work — Phase 1

Phase 1 is decomposed in `ROADMAP.md`:

1A. **Interaction affordance + reach** — **System 29 APPROVED, implementation authorized**. Generalize current System-24 contact-forward reach and highlight only real currently perceived usable targets.

1B. **Item freshness/spoilage** — typed per-instance freshness, analytic authoritative-time aging, future refrigeration-rate seam, no per-item tick loop.

1C. **Semantic inventory/menu icons** — low-resolution UI icon catalog with deterministic coverage of current loot/menu semantics.

1D. **Large/multi-cell object visual geometry** — presentation-owned large draw span/pivot/overhang so multi-cell trees/traffic furniture actually look large without changing collision from art pixels.

1E. **Content expansion/integration** — more perishables, mundane items and world props/fixtures/vegetation using the new foundations.

**Current implementation target: Phase 1A / System 29 Candidate 001.**

---

## Current System 23 perception truth

Visual states remain `UNSEEN`, `REMEMBERED`, and `VISIBLE`. Candidate geometry is a 12-cell, 120-degree forward cone plus radius-1 near awareness. System 23 exposes neutral `VisualAcquisitionProvider`; the live composition injects System 27's illumination/atmosphere-aware provider.

Only acquired cells refresh environment/actor memory. A target may be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark or too strongly extinguished by atmosphere. Opaque geometry still blocks first.

System 29 player highlights must require current VISIBLE target knowledge and may not expose a technically reachable hidden object.

Exact-head owner: `verify/system23-perception`.

---

## Current System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Before System 29 implementation, `LootInteractionReach` is shared by search and external-container access: actor footprint plus one-cell-forward fringe. Approved System 29 moves this exact behavior into a neutral owner with **zero reach rebalance**.

Roadmap Phase 1B adds spoilage on the real stable item identities already created here; Phase 2 crafting consumes those same items.

Exact-head owner: `verify/system24-loot`.

---

## Current System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically.

Roadmap Phase 1B spoilage should derive freshness analytically from authoritative tick position rather than introduce a second clock/per-item scheduler.

Exact-head owner: `verify/system25-world-time-light`.

---

## Current System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing stats/status; localization uncertainty cannot flip true actor-relative front/rear/left/right signs; observation age uses WHEN ticks only.

Recognized player-facing sounds prefer onomatopoeia (`*step step*`, `*thump thump*`, `*creak*`, `*SLAM*`). Weather rain/wind masks hearing as competing background noise without creating fake rain emissions.

Current lightning intentionally creates no thunder because the implemented event has no honest strike cell.

Exact-head owner: `verify/system26-spatial-sound`.

---

## Current System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

Implemented physical facts include semantic DEV flashlight/lamp/streetlight/neon emitters; per-cell sky/direct/portal/local luminance; enclosure/portal treatment; structure transmission/shadows; weather optics/wetness; target-condition useful-range policy; and transient physical lightning.

Verified lightning fixture: storm-night exterior 0.025 -> 0.845 during flash; roofed interior through a real window portal 0.356.

The bounded 80×96 / four-light regression remains 7,680 field cells, 1,676 emitter candidates and 688 optical-ray candidates.

Exact-head owner: `verify/system27-physical-lighting`.

---

## Current System 28 Weather / Atmosphere truth

> **Weather is simulation truth; weather animation is presentation.**

Slices A+B+C are implemented. Physical Weather is deterministic/event-driven through WHEN with clear/overcast/rain/storm/fog state, analytic wetness, quantized environment revisions, snapshot schema v2 and deterministic lightning.

Rain/fog/debris are a low-resolution screen-space overlay. Camera movement does not redraw/clear/reseed/phase-shift Weather. Focused regression reports zero Weather redraws after repeated camera updates.

Weather drives System 27 optics/wetness/visibility and System 26 hearing masking. Lightning supplies a one-tick real physical sky flash plus a short stable-seeded cosmetic bolt.

First fully green executable Weather C head: `21014fe5915e47344b4b8d5f48e52fa69c386254`; all 13 then-required contexts green including Pages.

Exact-head owner: `verify/system28-weather`.

---

## Approved System 29 Candidate 001

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

- Neutral `CONTACT_FORWARD` reach preserves System 24's actor-footprint + one-cell-forward behavior exactly.
- Real mechanic owners publish read-only interaction offers; appearance alone never invents a USE action.
- First provider is System 24 searchable containers and first real offer is `SEARCH`.
- Player-facing highlights require System-23 current `VISIBLE` knowledge; REMEMBERED/UNSEEN cannot reveal usability.
- Partial multi-cell visibility exposes only currently visible footprint cells.
- Discovery queries only the actor-local reachable cells through WHAT occupancy; no full-world scan and no per-object Nodes.
- Highlight presentation is a restrained pixel marker/outline, not System-27 physical light.
- Candidate 001 adds no universal Interact button and does not execute actions.

Canonical design: `SYSTEM_DESIGNS/29_WORLD_INTERACTION_AFFORDANCE_REACH.md`.

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

1. **Items/readability** — Phase 1A–1E above.
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

- System 29 / Phase 1A implementation is the active authorized change until verified;
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

## Required executable-head contexts before System 29 lands

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
- `verify/pages-deploy`

System 29 implementation must add its own focused exact-head context before being marked IMPLEMENTED.