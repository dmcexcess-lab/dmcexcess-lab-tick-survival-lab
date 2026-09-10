# Walk Fatigue Policy Closure — 2026-09-09

## Scope

This bounded balance/production repair changes only how ordinary on-foot movement feeds System 34 fatigue.

The live movement path previously charged at least one fatigue point for every forward/backward WALK stride, which made routine walking steadily exhaust a healthy survivor. The live adapter now treats WALK as baseline locomotion rather than automatic exertion.

## Production behavior

Owning production file:

- `game/scripts/simulation/actors/condition/MovementConditionExertionService.gd`

Owning production commit:

- `3660521498aebf45d4986af803ebf9792625a492` — `Make ordinary walking fatigue-free`

Current policy:

- healthy forward/backward WALK adds **0 fatigue**;
- orange/mild condition pressure alone still leaves WALK fatigue-free;
- one severe physical pressure alone still leaves WALK fatigue-free;
- WALK begins adding exertion only when at least **two severe physical burdens overlap**;
- qualifying burdens are red-tier satiety, hydration, rest or comfort; fatigue already at 90+; and carry load above 100% capacity;
- overburden alone is therefore not enough to make ordinary WALK drain fatigue, but overburden plus another severe burden is;
- when WALK is taxing, cost scales by terrain walk time and is at least 1;
- RUN remains materially fatiguing and retains its existing terrain/load scaling.

No health damage, max-health mutation, movement timing, collision, pathing, run timing, vehicle movement, NPC timing, or UI behavior was changed by this operation.

The older `MovementExertionService` path was not wired into the current live System 34 movement adapter, so it was deliberately not turned into a second policy owner.

## Focused verification

Fresh prompt-local verifier pair:

- `game/scripts/ci/PromptWalkFatiguePolicySmoke.gd`
- `.github/workflows/prompt-walk-fatigue-policy.yml`

Verifier creation heads:

- `5545258c9dea3b9ab2f81c1953796914d9fb28e9` — prompt smoke
- `eef3eb87a03c927361fa94e5121c755e659f2c4b` — prompt workflow

The smoke exercises the real `MovementActionService -> movement_exertion_resolved -> MovementConditionExertionService -> ActorConditionService` path and verifies:

- repeated healthy WALK adds zero fatigue and does not alter health;
- orange pressure adds no WALK fatigue;
- one red physical pressure adds no WALK fatigue;
- two red physical pressures make WALK exertion;
- overburden alone adds no WALK fatigue;
- overburden plus one red pressure makes WALK exertion;
- healthy RUN still increases fatigue.

Focused workflow result:

- run `34439671502` on `eef3eb87a03c927361fa94e5121c755e659f2c4b` — **SUCCESS**.

Pages/Web publication proof on the same functional head:

- run `34439671427` on `eef3eb87a03c927361fa94e5121c755e659f2c4b` — **SUCCESS**.

## Prompt-local lifecycle

This verifier pair remains in the repository through final context closure. The next distinct code operation must delete it first and create a new prompt-local verifier pair for that next bounded behavior, per `README_SOPS.md`.
