# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once at prompt start.

## Current checkpoint — CORE FEATURE ROADMAP CLOSED / BETA CANDIDATE — 2026-09-09

The user explicitly asked to finish the game from the approximately 90% state. The stale roadmap was reconciled against the executable rather than reimplementing systems that already existed. The remaining real core gap was the human-survivor/social/local-outbreak half of Phase 8. That gap is now implemented and verified.

The game is now **core-feature complete as a beta candidate**. Remaining work is human-play acceptance, concrete defect repair, balance/art/content/accessibility polish, and explicitly optional fidelity expansion. Do not invent another missing architecture phase merely because older roadmap text said one existed.

Owning functional/executable head: `52c6ef02c8f78b05c6761e73be4c525d1d975efe`.

Documentation closure before this final handoff: `339ce20d6e0cb25a6ef658afd1d90ea15e310dba`.

## Completed in this core-finish operation

### Roadmap reconciliation

The old roadmap materially lagged the production tree. Targeted owner inspection confirmed these are already real and connected rather than missing placeholders:

- procedural island, streaming and rendering;
- day/night, generated weather, physical lighting, streetlights and spatial sound;
- inventory/equipment, loot/search, freshness, food/drink/medicine and carry;
- Health/injury, hunger/thirst, Fatigue, rest/sleep and first aid;
- crafting/cooking, foraging, primitive resources, repair and deconstruction/reclamation;
- Awareness, Stealth, Mechanical and Survival consumers;
- doors/windows including open/break/board/reinforce/climb and environmental opening pressure;
- generators, switches/lights, sinks/water sources, beds/chairs and utilities;
- skateboards, bicycles, motorcycles, cars and trucks with keys/locks/hot-wire, fuel, cargo, repair, rack install, crash consequence and headlights;
- melee/firearms, actor Health/death and the existing resident-backed infected AI/cohort.

`ROADMAP.md` now records the core feature roadmap as closed and routes future work to defect-driven beta acceptance rather than stale subsystem invention.

### System 40 — resident survivors / social roles / causal local outbreak

Implemented the real missing Phase-8 core without adding duplicate truth owners:

- `PopulationResidentProjection` deterministically partitions the existing generated household residents into infected and survivors. The two projections exactly cover aggregate residents and cannot duplicate one identity.
- Production still starts with the established **8 resident-backed infected**.
- Production now hydrates **4 resident-backed human NPCs** from exact survivor identities: 2 neutral survivors and 2 raiders.
- Human NPCs use ordinary `actor.survivor` entities and the existing locomotion, inventory, hand equipment, Health, four-skill, carry, condition/Fatigue, perception, sound, movement, combat, streaming and WHEN owners.
- Neutral survivors expose contextual `TALK` and `ASK TO FOLLOW`; followers expose `TALK` and `TELL TO STAY` through the normal world interaction/HUD path. Raiders do not expose friendly social actions while hostile.
- Followers use the existing movement owner and trail the player with a small spacing buffer.
- Raiders use their own observer-scoped sight, last-seen memory and heard observations, then submit ordinary movement/combat actions. They receive no hidden world truth.
- Survivor NPCs receive at most one ordinary action opportunity per player commitment. Boot, stream activation, sound and perception changes may refresh intention but may not grant free world-tick actions.
- `SurvivorInfectionService` consumes real infected combat impacts. Repeated damaging infected melee exposure can cross the local infection threshold.
- Conversion preserves the **same resident/actor identity**: the actor leaves survivor role/cohort ownership and enters the existing infected cohort. No replacement zombie or duplicate population count is created.
- Newly converted active infected inherit the existing perception/behavior/System-39 environmental-opening-pressure path.

Canonical design: `SYSTEM_DESIGNS/40_SURVIVOR_SOCIAL_OUTBREAK.md`.

### Verification defect found and repaired

The first diagnostic run was not a true runtime hang. Godot rejected `ActiveSurvivorCohortService.gd` because it redundantly redeclared inherited constants already owned by `ActiveInfectedCohortService` (`StreamingPerceptionClass`, `VisionProfileClass`, `Layers`). The half-booted production scene then caused the smoke to continue until timeout.

Repair on functional head `52c6ef02c8f78b05c6761e73be4c525d1d975efe` removed only those duplicate declarations and reused the inherited constants. No gameplay ownership or survivor/infected behavior was weakened.

The disposable workflow was also bounded with an Actions job timeout plus shell timeout/line-buffered diagnostics so a future prompt-local failure cannot sit indefinitely without preserving its last phase marker.

## Verification / publication

Fresh prompt-local pair for this operation:

- `game/scripts/ci/PromptSurvivorOutbreakClosureSmoke.gd`
- `.github/workflows/prompt-survivor-outbreak-closure.yml`

Owning functional-head verification:

- Functional head: `52c6ef02c8f78b05c6761e73be4c525d1d975efe`.
- Focused workflow run `34406705296`, job `102651283682`: **SUCCESS**.
- Godot class-cache/load preparation completed successfully with no parser/load errors.
- Real production seed-20001 scene booted successfully (`PLAYABLE_ISLAND_WORLD_READY`, `CANONICAL_DEMO_BOOT_OK`).
- The smoke reached all production phases: population partition, cohort composition, social roles, infection conversion and converted-cohort verification.
- Terminal marker: `PROMPT_SURVIVOR_OUTBREAK_CLOSURE_SMOKE: PASS`.
- Exact functional-head Pages run `34406705275`: **SUCCESS**; Web export/deploy completed.

Per `README_SOPS.md`, no unrelated historical gameplay/regression suite was run. Prompt-local module verification is the gameplay gate; Pages is deployment only.

This `README_CONTEXT.md` update is the **FINAL repository write** for the prompt. After its commit, perform read-only exact-final-head verification only. Do not write again merely to insert final-head run IDs.

## Core status at close

There is no known missing core gameplay architecture phase remaining in the reconciled roadmap. The deployed game now has the intended persistent procedural zombie-survival loop and the major player/world/NPC systems are connected.

This does **not** mean every possible fidelity feature exists or that human browser/game-feel acceptance is complete. The following remain optional expansion or acceptance/polish, not fake-completed core features:

- detachable/replacement vehicle battery and wheel consumers;
- arbitrary-angle rotated vehicle collision polygons beyond the deterministic typed-heading raster model;
- partial-liquid fuel simulation instead of whole transfer units;
- island-wide streamed parked-vehicle population beyond the bounded playable-area seeding;
- broader vehicle modification/salvage detail;
- deep persistent relationships, factions, diplomacy, long-form dialogue and authored quests;
- large survivor settlements and richer follower command UI;
- island-wide aggregate offscreen epidemic propagation between distant households;
- more sophisticated route planning only if a concrete generated-world navigation failure proves the bounded local policy insufficient;
- additional art/content variety, balance tuning and accessibility/UI polish.

Do not present those optional fidelity items as already implemented. Also do not treat them as blockers to the current core beta candidate unless the user explicitly promotes one into required scope.

## Preserve established behavior

- Preserve the existing eight-member resident-backed infected baseline plus the four resident-backed survivor exemplars unless a future explicit balancing decision changes counts.
- Preserve same-identity survivor -> infected conversion; never spawn a replacement identity for this path.
- Preserve observer-scoped NPC sight/hearing and shared WHEN. No render-frame AI waking, hidden-world knowledge, second AI timer or free boot turns.
- Preserve System-39 generic door/window opening pressure and ordinary collision/movement ownership.
- Preserve authoritative item/action/state ownership; UI/rendering never owns gameplay truth.
- Preserve current world generation, roads/towns/rural density, coastline, utility topology, night-only streetlights, generated weather, bounded streaming and render-window architecture.
- Preserve dedicated vehicle rendering without the retired purple diagnostic artifact.
- Preserve same-tick actor consequences resolving through the existing WHEN priority/owner/serial ordering; simultaneous movement was discussed but is not implemented.
- Do not resurrect retired generated rivers/wastewater/sewer/septic systems.
- Do not run historical broad gameplay suites or routine seed matrices. Follow the prompt-local verifier rules in `README_SOPS.md`.

## NEXT OPERATION — WAIT FOR USER APPROVAL / HUMAN BETA ACCEPTANCE

The next distinct operation is **human-play beta acceptance and defect-driven polish**, not another architecture build-out.

After approval or a concrete user-reported play defect:

1. delete this prompt's verifier pair first:
   - `game/scripts/ci/PromptSurvivorOutbreakClosureSmoke.gd`
   - `.github/workflows/prompt-survivor-outbreak-closure.yml`
2. create a fresh prompt-local verifier only for the next touched module/play path;
3. repair the concrete desktop/mobile/Safari interaction, rendering, streaming, control, pacing, NPC/combat, balance or presentation defect in its existing owner;
4. publish through focused verification, exact-head Pages and a new final `README_CONTEXT.md` handoff.

If the user simply asks whether the game is finished, answer that the **core feature roadmap is closed and the current build is a beta candidate**; human acceptance/polish and optional fidelity remain. Do not reopen completed systems without concrete evidence.