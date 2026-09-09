# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once at prompt start.

## Current checkpoint — NATIVE HUMAN PLAY ACCEPTANCE ESTABLISHED — 2026-09-09

The core feature roadmap remains closed and the game remains a beta candidate. This prompt solved the previous cloud-browser/WebGL acceptance blocker by creating a prompt-local native Linux play harness from the exact repository head, downloading that artifact into the execution sandbox, running it under Xvfb with Mesa software rendering, and driving the actual game with real mouse input while capturing frames.

No production gameplay system was rewritten in this operation. The purpose was human-style play acceptance and concrete defect discovery.

Owning functional / native-play harness head: `8759e03e42c9aff4e0109b0a161f9f083f0802d9`.

## Prompt-local verifier / native play harness

Previous prompt pair was retired first:

- `game/scripts/ci/PromptSurvivorOutbreakClosureSmoke.gd`
- `.github/workflows/prompt-survivor-outbreak-closure.yml`

Fresh prompt-local pair:

- `game/scripts/ci/PromptNativePlayAcceptanceSmoke.gd`
- `.github/workflows/prompt-native-play-acceptance.yml`

The workflow:

- installs Godot 4.7.1 + export templates;
- prepares the project class cache;
- boots the real production scene headlessly and requires `PROMPT_NATIVE_PLAY_ACCEPTANCE_SMOKE: PASS`;
- appends a temporary, CI-only Linux export preset at runtime without modifying committed `game/export_presets.cfg`;
- exports an embedded-PCK Linux x86_64 executable;
- uploads one-day artifact `tick-native-play` for local/native acceptance.

Owning workflow run `34410809441`, job `102664521738`: **SUCCESS**.

Exact-head Pages run `34410809468`: **SUCCESS**.

The native artifact used for play came from workflow run `34410809441`, artifact id `10127178016`, head `8759e03e42c9aff4e0109b0a161f9f083f0802d9`.

## Actual play performed in this prompt

The native client was launched under a virtual X display with software OpenGL rendering. Real mouse input was sent to the Godot window and screenshots were inspected after actions. This was not a headless-state-only test.

The play path covered:

- spawned into the generated island and visually confirmed the live road/utility environment;
- attempted movement into a utility pole and confirmed collision / `Target Blocked` feedback;
- turned and walked along the road for many actions while streaming/rendering continued;
- opened and closed the island map;
- foraged successfully and gained a real carried item;
- opened inventory, selected the foraged item, and equipped it to the right hand;
- used `STRIKE` with the equipped item;
- approached chain-link substation fencing and confirmed movement collision;
- walked far enough to reach the generated vehicle/house area;
- entered a real motorcycle and saw the mounted control replacement UI;
- tried `START` and got the concrete failure `ignition requires hotwire`;
- tried `HOTWIRE` and got the concrete prerequisite failure `hotwire requires screwdriver and wire`;
- exited the motorcycle;
- approached a generated rural house;
- aligned to and clicked the real rural wood door;
- opened the contextual interaction panel and used `OPEN`;
- walked through the opened door into the revealed interior;
- targeted the kitchen sink, opened its contextual action panel, and used `DRINK`;
- hydration increased from 58 to 86, proving the world-object -> sustainment path worked in ordinary play.

## Concrete human-play defects discovered

These are real observations from the native play session and should drive the next bounded fixes.

### 1. Player-facing action label falls back to `Unknown`

Several successful non-movement interactions updated the top HUD as `Unknown` rather than naming the action. Observed examples include:

- entering/exiting a vehicle;
- opening the rural wood door;
- drinking from the kitchen sink.

The detailed reason text below can still be useful (for example `Ignition Requires Hotwire` / `Hotwire Requires Screwdriver And Wire`), but the primary action name should not be `Unknown` for ordinary valid interactions.

This is a concrete UI/action-feedback defect, not a gameplay-ownership defect.

### 2. Foraged item exposes internal generated ID in inventory

After ordinary `FORAGE`, inventory displayed a player-facing label like:

`Outdoors Sturdy Stick [forage.2045245590.2045245590.38.257.000.00]`

The internal deterministic forage identity is useful canonical state but should not be rendered as part of the human-facing item name. The selected-item panel repeats the same internal ID.

This is a concrete presentation defect. Preserve the exact item identity internally; sanitize only the display label.

### 3. Mounted controls are visibly shorter than the walking controls

The motorcycle replacement controls were usable in this desktop native session, but their vertical touch target is visibly smaller than the normal walking buttons. Since phone/Safari is first-class, this should be checked during the next mobile/touch UI acceptance pass. Do not call this a confirmed touch failure until measured/tested on the owning UI path.

## Behaviors that worked and should not be reopened without evidence

- real world rendering under native software GL;
- ordinary walking/turning and collision;
- map open/close;
- forage creating a real item and carry weight;
- inventory selection and hand equip;
- vehicle detection, enter/exit and mounted control swap;
- concrete start/hotwire prerequisite messaging;
- direct world-object click affordance for the generated door;
- door contextual actions and open-state change;
- crossing through the opened doorway;
- interior reveal/rendering;
- kitchen sink contextual interaction;
- sink drink changing canonical hydration;
- previously completed resident survivor/infected architecture and all earlier protected systems.

The Mesa/llvmpipe native acceptance client is intentionally not a performance benchmark; its high CPU use is a software-rendering artifact and should not be treated as evidence of a production browser performance regression.

## Core status

The game remains **core-feature complete as a beta candidate**. Human acceptance is now possible without depending on cloud WebGL support: when browser execution is blocked, export a native prompt-local artifact and drive that build under a virtual display.

Optional fidelity backlog remains optional unless explicitly promoted by the user. Do not reopen completed architecture merely because the beta still has presentation/interaction defects.

## Preserve established behavior

- Preserve the existing eight-member resident-backed infected baseline plus the four resident-backed survivor exemplars unless a future explicit balancing decision changes counts.
- Preserve same-identity survivor -> infected conversion.
- Preserve observer-scoped NPC sight/hearing and shared WHEN; no free boot turns or render-frame AI.
- Preserve System-39 generic door/window opening pressure and ordinary collision/movement ownership.
- Preserve authoritative item/action/state ownership; UI/rendering never owns gameplay truth.
- Preserve current world generation, roads/towns/rural density, coastline, utility topology, night-only streetlights, generated weather, bounded streaming and render-window architecture.
- Preserve dedicated vehicle rendering without the retired purple diagnostic artifact.
- Preserve same-tick actor consequence ordering through WHEN.
- Do not resurrect retired generated rivers/wastewater/sewer/septic systems.
- Do not run historical broad gameplay suites or routine seed matrices.

## NEXT OPERATION — defect-driven polish from observed native play

Continue with one bounded human-observed defect, not a broad audit.

Recommended first fix: **replace `Unknown` top-HUD action feedback for ordinary delegated/world interactions with the actual action label while preserving owning service reason text and timing.**

Alternative next fix if the user prefers: **hide internal deterministic forage IDs from inventory/selected-item display while preserving canonical item identity/state.**

At the start of the next code operation:

1. delete this prompt's verifier pair first:
   - `game/scripts/ci/PromptNativePlayAcceptanceSmoke.gd`
   - `.github/workflows/prompt-native-play-acceptance.yml`
2. create a fresh prompt-local verifier only for the exact chosen defect;
3. repair the smallest owning UI/presentation seam;
4. replay the corrected path when useful using the native-artifact workaround;
5. publish through focused verification, exact-head Pages, and a new final `README_CONTEXT.md` write.

This `README_CONTEXT.md` update is the **FINAL repository write** for this prompt. After this commit, perform read-only exact-final-head verification only.