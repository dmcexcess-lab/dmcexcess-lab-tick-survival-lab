# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — WALK FATIGUE POLICY CLOSED — 2026-09-09

The core feature roadmap remains closed and the game remains a beta candidate. This bounded balance/production repair fixes the ordinary WALK fatigue drain in the live movement-to-condition path.

Owning production commit:

`3660521498aebf45d4986af803ebf9792625a492`

Owning fully gated functional head:

`eef3eb87a03c927361fa94e5121c755e659f2c4b`

Documentation head immediately before this final context write:

`1451d54f55d296471ac11d57b476ff043898a770`

## Root cause

The live `MovementConditionExertionService` adapter explicitly charged at least one fatigue point for every forward/backward WALK stride. Routine healthy walking therefore accumulated fatigue even though WALK is intended to be baseline locomotion.

The older `MovementExertionService` path is not the live System 34 adapter. It was deliberately left alone rather than creating a second competing exertion policy.

## Implemented policy

`game/scripts/simulation/actors/condition/MovementConditionExertionService.gd` now applies these rules:

- healthy forward/backward WALK adds **0 fatigue**;
- orange/mild physical pressure alone leaves WALK fatigue-free;
- one severe physical pressure alone leaves WALK fatigue-free;
- WALK becomes exertion only when at least **two severe physical burdens overlap**;
- severe burden inputs are red-tier satiety, hydration, rest or comfort; fatigue already at 90+; and carry load above 100% capacity;
- overburden alone therefore does not tax ordinary WALK, while overburden plus another severe burden can;
- when WALK is taxing, its cost scales with terrain walk time and is at least 1;
- RUN remains materially fatiguing and keeps its terrain/load scaling.

This operation did **not** change health damage, max health, movement timing, collision, pathing, WHEN scheduling, same-WHEN simultaneity, vehicle movement, NPC/zombie behavior, or UI presentation.

## Verification

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptWalkFatiguePolicySmoke.gd`
- `.github/workflows/prompt-walk-fatigue-policy.yml`

Verifier creation heads:

- `5545258c9dea3b9ab2f81c1953796914d9fb28e9` — smoke
- `eef3eb87a03c927361fa94e5121c755e659f2c4b` — workflow / fully gated functional head

The focused smoke exercises the real `MovementActionService -> movement_exertion_resolved -> MovementConditionExertionService -> ActorConditionService` path and verifies:

- repeated healthy WALK adds zero fatigue and does not alter health;
- orange pressure adds no WALK fatigue;
- one red physical pressure adds no WALK fatigue;
- two red physical pressures make WALK exertion;
- overburden alone adds no WALK fatigue;
- overburden plus one red pressure makes WALK exertion;
- healthy RUN still increases fatigue.

Focused workflow:

- run `34439671502` on `eef3eb87a03c927361fa94e5121c755e659f2c4b` — **SUCCESS**.

Pages/Web publication proof:

- run `34439671427` on functional head `eef3eb87a03c927361fa94e5121c755e659f2c4b` — **SUCCESS**;
- run `34447830031` on documentation head `1451d54f55d296471ac11d57b476ff043898a770` — Web build, artifact upload and deploy **SUCCESS**.

After this final context commit, verify the exact final-head Pages run read-only. No further repository writes are permitted in this operation.

## Documentation

Operation-specific closure ledger:

- `CHANGELOG_WALK_FATIGUE_POLICY.md`

Documentation commit immediately before this final context write:

`1451d54f55d296471ac11d57b476ff043898a770`

## Established systems to preserve

Unless concrete evidence requires a bounded repair, preserve:

- the single authoritative WHEN clock;
- same-WHEN deterministic movement batching and decision-pause semantics;
- ordinary WALK being fatigue-free under normal/single-pressure conditions;
- RUN remaining the routine fatiguing locomotion mode;
- current settlement-first procedural island, building-derived population and streaming architecture;
- current geographic road hierarchy and dirt/gravel/paved contracts;
- observer-scoped infected/survivor perception and existing population ownership;
- day/night, generated weather, physical lighting and night-only streetlights;
- power/water infrastructure and current roadside pole behavior;
- inventory/equipment/sustainment/crafting/skills/doors/windows/utilities/vehicles/combat systems already closed;
- dedicated vehicle rendering without the retired purple diagnostic artifact;
- no generated rivers/wastewater/sewer/septic resurrection;
- no routine broad seed matrices or standing gameplay gates for ordinary bounded prompt closure.

## Known beta observations still available for later bounded polish

Not part of this WALK operation:

- zombie/infected presence can cause significant slowdown; the `ZOMBIES` overlay is intentional diagnostic context, not itself the performance bug;
- some delegated/world interactions can still show `Unknown` as a top-HUD action label;
- foraged inventory labels can expose internal deterministic generated IDs;
- mounted mobile controls deserve a real touch acceptance pass;
- utility pole generation remains imperfect but currently beta-acceptable.

## NEXT OPERATION — wait for the next explicit bounded target

The WALK fatigue policy pass is closed. Do not broaden it automatically into stamina-system redesign, sprint tuning, condition rebalance, NPC fatigue, health changes, or zombie performance work.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptWalkFatiguePolicySmoke.gd`
- `.github/workflows/prompt-walk-fatigue-policy.yml`

Then create a fresh prompt-local verifier for only the newly requested behavior and follow the normal direct-to-main closure SOP.

This `README_CONTEXT.md` commit is the **FINAL repository write for the WALK fatigue policy operation**. After it lands, perform read-only exact-head and CI/Pages verification only.