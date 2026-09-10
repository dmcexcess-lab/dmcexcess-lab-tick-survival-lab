# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — SAME-TIMESTAMP MOVEMENT SIMULTANEITY CLOSED — 2026-09-09

The core feature roadmap remains closed and the game remains a beta candidate. This operation repaired simulation ordering so actor movement due at the same authoritative WHEN timestamp no longer mutates WHAT occupancy one actor at a time.

Scope was deliberately limited to **simulation simultaneity**. Visual interpolation/rendering was not changed.

Starting ref for this operation, reused exactly without another `main` fetch:

`1fee3f3c320fdc15e32f0a341dbb1f0678ef4da5`

Owning functional head:

`2734666fe75b747b097dfead5c30ad5e6db6691b`

Documentation head immediately before this final context write:

`62876211ffacbb51554d91c4fede33d98658d222`

## Production mutation point located

The authoritative occupancy mutation seam was confirmed in production movement: movement phases ultimately wrote actor placement through `WorldMutationService.set_placement()` during each individual `action_phase` callback.

That meant actors with movement consequences due at the same world tick were physically committed in scheduler order. Later actors therefore observed occupancy already changed by earlier same-timestamp actors, even though WHEN correctly treated the timestamp as one drained consequence batch.

The fix was made at that production simulation seam rather than in rendering, input, AI presentation or a second scheduler.

## Implemented same-WHEN movement batching

Same-timestamp successful movement phases now resolve through one deterministic occupancy batch.

Key rules:

- movement intents due at the same authoritative world tick are gathered before terminal action completion;
- non-overlapping successful moves are installed together;
- all winning placement records are installed before placement-change or movement-commit observers are notified, so observers see complete final occupancy for that timestamp;
- overlapping otherwise-valid destination claims are resolved deterministically by stable actor identity;
- the deterministic loser remains at its origin and receives ordinary blocked movement truth;
- already-occupied request/commit snapshot cells remain blocked — this pass does **not** introduce swaps, movement chains or phasing through occupied actors;
- Run keeps authoritative impact semantics: a same-timestamp conflict loser reports the deterministic winning actor as the impact blocker;
- passage-aware movement now uses the same base batching path instead of bypassing it with direct placement mutation;
- expected-origin/intermediate placement validation, terrain rules, collision ownership and existing movement policy remain authoritative;
- `TickKernel` remains the only scheduler.

`ScheduledEvent` ordering was narrowly adjusted so same-timestamp action completion runs after other consequences due at that timestamp, allowing mechanic owners to collect/resolve their same-WHEN work before actions become terminal.

`WorldMutationService` gained an atomic validated placement-set path that installs all records before emitting the resulting WHAT change notifications.

## Explicit non-goals / preserve boundaries

This operation did **not**:

- add visual interpolation;
- change renderer or sprite movement;
- change player input buffering;
- add another turn/tick scheduler;
- make actors swap through each other;
- change AI decision logic;
- change vehicle presentation;
- change combat balance;
- reopen world generation, streaming or utilities.

Keep visual interpolation as a separate presentation concern if it is ever requested.

## Focused verifier

Fresh prompt-local verifier pair for this operation:

- `game/scripts/ci/PromptSimulationSimultaneitySmoke.gd`
- `.github/workflows/prompt-simulation-simultaneity.yml`

The verifier covers:

- deterministic contested-destination winner independent of request order;
- one blocked loser with stable result;
- two independent same-WHEN moves publishing atomically so the first WHAT/movement observer already sees both final placements;
- one two-change world batch for independent simultaneous moves;
- conservative blocking when a destination was occupied in the pre-batch snapshot;
- same-WHEN Run conflict preserving authoritative impact blocker truth.

An initial verifier run exposed two implementation/test defects: passage-aware movement still depended on inherited movement hooks that had been removed, and GDScript closure rebinding did not persist two observer-capture dictionaries. Those were repaired without changing the simultaneity design: passage-aware movement was restored onto the base batching hook surface, and verifier captures were changed to shared mutable containers.

## Verification

Focused exact-functional-head workflow:

- run `34424284356` — **SUCCESS**
- job `simulation-simultaneity` — **SUCCESS**
- Godot 4.7.1 full class registration completed, including `MovementActionService` and `PassageAwareMovementActionService`;
- focused smoke printed `PROMPT_SIMULATION_SIMULTANEITY_SMOKE: PASS`;
- focused log contained no `SCRIPT ERROR`, parse error or failed script load.

The smoke exits with the existing test-harness ObjectDB/resource cleanup warnings; these are not script failures and were not introduced as production gameplay behavior.

Exact functional-head Pages workflow:

- run `34424284342` — **SUCCESS**
- Web export — **SUCCESS**
- Pages artifact upload — **SUCCESS**
- GitHub Pages deployment — **SUCCESS**

The final repository head after this context-only commit must be verified read-only. No repository writes are permitted after this file is committed in this operation.

## Documentation

Operation-specific closure ledger:

- `CHANGELOG_SIMULATION_SIMULTANEITY.md`

The documentation commit immediately preceding this final context write is:

`62876211ffacbb51554d91c4fede33d98658d222`

## Behaviors that remain established

Preserve unless concrete new evidence requires a bounded repair:

- single authoritative WHEN clock and same-tick drain semantics;
- same-WHEN actor movement batching described above;
- observer-scoped infected/survivor perception and ordinary WHEN-driven NPC actions;
- existing eight-member resident-backed infected baseline plus four resident-backed survivor exemplars unless an explicit balancing decision changes counts;
- same-identity survivor -> infected conversion;
- System-39 generic opening pressure and ordinary collision ownership;
- authoritative item/action/state ownership;
- current world generation, roads/towns/rural density, coastline, utilities, night-only streetlights, generated weather, bounded streaming and render-window architecture;
- dedicated vehicle rendering without the retired purple diagnostic artifact;
- existing native human-play acceptance findings;
- no generated rivers/wastewater/sewer/septic resurrection;
- no historical broad gameplay suites or routine seed matrices for ordinary prompt closure.

## Known beta / human-play observations still available for later bounded polish

These were previously observed in native human play and were not part of this simultaneity operation:

- some delegated/world interactions can still surface `Unknown` as the top-HUD action label;
- foraged inventory labels can expose their internal deterministic generated ID;
- mounted control buttons looked vertically shorter than walking controls and deserve a real mobile/touch check before calling it a touch defect;
- utility pole generation remains somewhat imperfect but was explicitly judged good enough for beta;
- the `ZOMBIES` overlay is intentional diagnostic output used to correlate zombie presence with slowdown; do not mistake the label itself for a gameplay defect. If performance is promoted later, profile the underlying infected workload rather than deleting the diagnostic first.

## NEXT OPERATION — wait for the next explicit bounded target

The simultaneity pass is closed. Do not broaden it into interpolation, AI architecture or unrelated polish automatically.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptSimulationSimultaneitySmoke.gd`
- `.github/workflows/prompt-simulation-simultaneity.yml`

Then create a fresh prompt-local verifier for only the newly requested behavior and follow the normal direct-to-main closure SOP.

Good existing bounded beta-polish candidates, only if the user selects/promotes one, remain:

- replace `Unknown` delegated/world-interaction HUD labels with truthful action labels;
- hide deterministic forage IDs from human-facing inventory names while retaining canonical identity;
- mobile/touch acceptance for mounted controls;
- infected/zombie performance profiling using the existing diagnostic context;
- additional pole-generation polish if the user later chooses to promote it beyond beta-acceptable status.

This `README_CONTEXT.md` commit is the **FINAL repository write for the same-timestamp movement simultaneity operation**. After it lands, perform read-only final-head verification only.