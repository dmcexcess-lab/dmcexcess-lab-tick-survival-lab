# System 13 Implementation Changelog — 2026-08-16

## Actor Stats / Status Domains

Implemented the complete approved System 13 actor-status architecture as six independent canonical domains.

### 13A Health / Injury
- Added real integer current/max HP with recovered 100 HP baseline.
- Added persistent broad injuries with semantic type, six body regions, MINOR/SERIOUS/CRITICAL severity, stabilized and treated state.
- HP zero remains Health truth only; death/corpse transition stays separate.
- Added deterministic snapshots, revision/version behavior and `ActorHealthSmoke.gd`.

### 13B Needs / Rest
- Added independent 0..100 fatigue, hunger, thirst and sleep-pressure values.
- Added explicit mutation only; no frame-time or guessed calendar progression.
- Added a 03 mobility provider recovering golden Tick fatigue timing pressure: fatigue 100 = +65% duration.
- Added deterministic snapshots and `ActorNeedsSmoke.gd`.

### 13C Skills
- Added catalog-driven Combat, Scavenging, Survival, Medical, Technical and Social skills.
- Added level 0..10 plus persistent XP with recovered threshold `20 + level * 15` and deterministic multi-level awards.
- Level 10 stores zero XP.
- Added deterministic snapshots and `ActorSkillsSmoke.gd`.

### 13D Item Physical Properties
- Added explicit semantic item physical profiles with positive integer gram weight.
- Added read-only stable WHAT item -> semantic weight query.
- Missing weight is UNKNOWN/fail-closed; no guessed default weights were added.
- Added `ItemPhysicalPropertiesSmoke.gd`.

### 13E Carry / Encumbrance
- Added persistent base capacity with recovered 18,000 g default.
- Current carried weight is derived, never serialized.
- Carry traverses real 09 hands + 11 actor-root/nested/held-container contents + 13D weights and deduplicates stable item IDs.
- One missing item weight makes the total UNKNOWN.
- Over-capacity remains representable; 12 transfer legality was not changed.
- Added a 03 provider recovering golden Tick encumbrance timing: exactly capacity = +75% duration, with continued scaling above capacity.
- Added deterministic capacity snapshots and `ActorCarrySmoke.gd`.

### 13F Moodlets
- Added derived-only readable moodlets over real Health, Needs and Carry truth.
- Added POSITIVE/NOTICE/WARNING/CRITICAL severity and deterministic priority ordering.
- Added Well Rested, fatigue, hunger, thirst, sleep, health and encumbrance threshold statuses.
- Missing source truth fails explicitly; ordinary moodlets are not persisted.
- Added `ActorMoodletsSmoke.gd`.

## Protected contracts
No production changes were made to WHAT, WHEN, Collision, Movement, Actor Locomotion, 09 Hand Equipment, 11 Inventory / Containment, 12 Item Transfer, rendering, art, input, Main, generation, or frozen `game/scripts/reboot/`.

13B and 13E use 03's already-approved `ActorMobilityModifierProvider` seam rather than importing or editing Movement.

## Verification
Added `.github/workflows/actor-stats.yml` — **Actor Stats Domains contract**.

Initial complete implementation candidate:
`78ed167678257749b093acd54e53e9f065cd8ce5`

Dedicated run:
`31992365565` — **SUCCESS**.

The run passed:
- source-boundary checks;
- Godot 4.7.1 import/parse;
- Persistent WHAT regression;
- Actor Locomotion regression;
- 09 Hand Equipment regression;
- 11 Inventory / Containment regression;
- 13A Health smoke;
- 13B Needs smoke;
- 13C Skills smoke;
- 13D Item Physical Properties smoke;
- 13E Carry smoke;
- 13F Moodlets smoke.

No production repair was required after the initial complete candidate.

## Demo consequence
The requested canonical Stats/HUD inspector no longer needs fake HP, stamina, carry weight or skill values. The remaining path is presentation/composition: authored canonical test area -> tactical renderer orchestration -> camera -> Safari/keyboard input -> controls -> real Stats/Inventory/HUD/Pause UI.
