# Tick Survival Lab — 13C Actor Skills

Status: **DRAFT — recovery-backed child design awaiting explicit approval before implementation**

Parent architecture: `SYSTEM_DESIGNS/13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## 1. Goal

Own persistent survivor skill identity, level/rank, and progression state as a standalone typed domain keyed by stable WHAT actor ID.

The requested player-facing result is simple:

> **Skill Name — Level**

The detailed Stats inspector may also show current XP / next-level XP.

## 2. Recovery-backed initial vocabulary

Same-owner First Fire already used six persistent skills:

- `combat`
- `scavenging`
- `survival`
- `medical`
- `technical`
- `social`

First Fire displayed them as Combat, Scavenging, Survival, Medical, Technical, Social.

Proposed canonical Tick v1 adopts those six as the initial skill catalog because they are broad, readable, already proven in this project family, and fit the North-Star player-story/background model.

The catalog must remain extensible; adding a later skill must not require schema fields or UI rewrites.

## 3. Proposed level/progression model

Recovery reference from First Fire:

- levels/ranks: 0 through 10;
- persistent XP per skill;
- next-level threshold: `20 + current_level * 15` XP;
- XP carries only the remainder after level-up;
- multiple levels may be gained if a sufficiently large XP award crosses multiple thresholds.

Proposed Tick v1 reuses this exact progression unless the user changes it before approval.

Interpretation:

- 0 = no meaningful training;
- 1–3 = novice/basic competence;
- 4–6 = experienced;
- 7–9 = expert;
- 10 = exceptional/mastery ceiling for v1.

Those descriptive bands are presentation guidance only; level integer is canonical truth.

## 4. Ownership

Planned production under:

`game/scripts/simulation/actors/skills/`

Expected focused modules:

- `ActorSkillCatalog.gd` — semantic skill IDs, display names, level cap, progression threshold policy;
- `ActorSkillRecord.gd` — one actor's skill level/XP map + version;
- `ActorSkillState.gd` — stable actor-ID records, revision, copy-safe reads, snapshot/restore;
- `ActorSkillMutationService.gd` — enrollment, explicit set/award XP mutations and semantic signals.

Testing:

- `game/scripts/ci/ActorSkillsSmoke.gd`
- `.github/workflows/actor-skills.yml`

Names may tighten during implementation without changing responsibility boundaries.

## 5. Stable identity / enrollment

Skills are keyed by stable WHAT actor ID.

V1 normal enrollment accepts existing `actor.survivor` entities.

Missing skill state is distinct from an enrolled survivor whose skills are all level 0.

This allows:

- pre-collapse/person-generation code to assign background-derived skills deliberately;
- stale/missing state to fail clearly;
- future NPC survivors to use the same skill system as the controlled survivor.

## 6. Data model

Proposed record concept:

- `actor_id: String`
- `levels: Dictionary[StringName, int]`
- `xp: Dictionary[StringName, int]`
- `version: int`

Only registered catalog skill IDs are allowed through normal mutations.

All absent registered skills read as level 0 / XP 0 after enrollment; snapshots may store only non-zero entries or all entries as long as serialization is deterministic and round-trips identically by contract.

No generic actor metadata is added to WHAT.

## 7. Public read contract

Expected reads:

- `has_actor(actor_id) -> bool`
- `actor_version(actor_id) -> int`
- `level(actor_id, skill_id) -> int`
- `xp(actor_id, skill_id) -> int`
- `next_level_xp(actor_id, skill_id) -> int`
- `skill_ids() -> Array[StringName]`
- `snapshot_actor(actor_id)` or equivalent copy-safe record read
- `revision() -> int`
- `snapshot() / load_snapshot()`

Unknown actor or unknown skill must fail clearly rather than silently invent a rank.

## 8. Mutation contract

Expected normal writes:

- `enroll_actor(actor_id)`
- `remove_actor(actor_id)` for explicit lifecycle cleanup where legal;
- `set_level(actor_id, skill_id, level, xp = 0)` for character generation/admin/setup paths;
- `award_xp(actor_id, skill_id, amount)` for gameplay progression.

`award_xp`:

- requires positive XP;
- applies deterministic threshold progression;
- respects level cap;
- emits level-up information when one or more levels are crossed;
- does not itself decide **why** XP was earned.

Combat, medical treatment, scavenging, crafting, social actions, etc. later decide XP awards through their own action/outcome systems.

## 9. Signals

Proposed semantic signals:

- `skill_changed(actor_id, skill_id, level, xp, actor_version)`
- `skill_level_gained(actor_id, skill_id, previous_level, new_level)`
- `actor_skills_reset` / domain reset after snapshot restore

Exact signal names may tighten before implementation, but Skills owns progression notifications rather than UI polling dictionaries.

## 10. Background / character-story seam

The North Star says skills should derive partly from background rather than RPG class abstraction.

13C does not own occupation/background generation.

Future Population / Player Story code may:

1. generate/select a person's background;
2. derive initial skill levels through its own policy;
3. call 13C setup mutations.

Recovery reference: First Fire backgrounds added bonuses to the same six skills. The exact background-to-skill table is **not** imported into 13C.

## 11. Modifier/effective-skill seam

Persistent level is not necessarily the final skill value used by every action.

Future conditions may temporarily affect capability:

- fatigue;
- injury;
- equipment/tool bonuses;
- mood/panic;
- traits;
- environmental conditions.

13C owns **base persistent skill progression** only.

A later action/capability policy composes base level with relevant modifiers for the mechanic asking the question. 13C does not import Needs, Health, Equipment, Combat, or Carry to calculate one universal `effective_skill`.

This avoids circular dependencies and lets different mechanics interpret a skill appropriately.

## 12. UI seam

13C exposes semantic IDs, display names, level, XP, and threshold.

It does not create Labels/Buttons or know the Stats screen.

The future Stats read model can enumerate the catalog dynamically, so adding a seventh skill later does not require six hardcoded UI rows to be rewritten.

## 13. Persistence / determinism

Required:

- deterministic actor-ID ordering;
- deterministic catalog/skill ordering;
- schema-versioned snapshot;
- atomic malformed-snapshot rejection;
- duplicate actor rejection;
- unknown skill ID rejection unless a future explicit migration policy says otherwise;
- level/XP range validation;
- monotonic domain revision / per-actor version suitable for future stale-action checks.

No RNG is used inside Skills progression.

## 14. Dependencies

Allowed:

- WHAT read validation for stable `actor.survivor` identity;
- its own catalog/state/mutation modules.

Forbidden:

- WHEN ownership;
- Health / Needs / Moodlets;
- Inventory / Hands / Carry;
- Combat / AI;
- character creator UI;
- renderer/art;
- reboot runtime;
- generation internals.

## 15. Performance / mobile

- O(1)-style actor/skill lookup;
- no `_process()`;
- no full-world scanning;
- no Node per skill;
- skill catalog is tiny and deterministic;
- UI may refresh from signals or on inspector open.

## 16. Failure cases

Normal mutations reject:

- missing actor;
- non-survivor actor;
- unenrolled actor;
- unknown skill ID;
- negative/zero XP award;
- invalid level/XP values;
- malformed snapshot.

At max level, XP award may be a successful capped no-op or explicitly discard excess XP; proposed v1 behavior is **successful capped no-op with XP held at 0 at level 10**, avoiding meaningless overflow accumulation. This detail requires approval.

## 17. Tests / acceptance criteria

Dedicated smoke should prove:

1. survivor enrollment;
2. missing vs enrolled-zero distinction;
3. non-survivor rejection;
4. all six recovery-backed skill IDs and deterministic display order;
5. level 0–10 validation;
6. exact `20 + level * 15` threshold progression;
7. one-level XP gain;
8. multi-level XP gain;
9. level-10 cap behavior;
10. copy-safe reads;
11. revision/per-actor version changes only on real mutations;
12. same-value setup no-op behavior;
13. deterministic atomic snapshot/restore;
14. malformed/unknown-skill snapshot rejection;
15. WHAT regression remains green;
16. source guards prove no Needs/Health/Inventory/Combat/UI/Render/Reboot imports.

## 18. North-star fit

Six broad skills + ten readable levels create meaningful survivor differentiation without a sprawling RPG skill tree. Background-derived setup supports the generated-person story, while progression remains simple and systemic.

The module can later gain new skills without changing Health, Needs, Inventory, rendering, or the Stats screen architecture.

## 19. Proposed decisions for approval

1. Initial canonical skills are Combat, Scavenging, Survival, Medical, Technical, Social.
2. Skills are semantic catalog entries, not fixed fields in an actor dictionary.
3. Levels run 0–10.
4. Each skill tracks persistent XP.
5. Reuse First Fire's exact next-rank threshold `20 + current_level * 15`.
6. Large XP awards may cross multiple levels deterministically.
7. Level 10 is capped and stores 0 progression XP in v1.
8. 13C owns base skill progression only; temporary effective-skill modifiers belong to mechanic-specific capability policies.
9. Background/player-story generation sets starting levels through public setup mutations but is not owned by 13C.
10. UI enumerates the skill catalog dynamically rather than hardcoding six fields.
