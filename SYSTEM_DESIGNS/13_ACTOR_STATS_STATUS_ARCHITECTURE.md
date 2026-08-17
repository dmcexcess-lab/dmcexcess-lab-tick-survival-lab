# Tick Survival Lab — 13 Actor Stats / Status Architecture

Status: **APPROVED UMBRELLA — architecture approved; child systems still require bounded design/approval before implementation**

Approval basis: on 2026-08-16 the user explicitly approved a modular character-state approach after specifying the desired player-visible set: **moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, and skills with levels**. The user also explicitly required that the system remain modular so more stats can be added later.

This document is an architecture umbrella. It does **not** authorize implementing every child domain in one slice.

## 1. Goal

Define a small, extensible set of independently owned actor-state domains that can later feed the requested HUD and detailed Stats inspector without creating a universal character dictionary or making UI own simulation truth.

The player-visible target is intentionally simple:

- HP;
- Fatigue;
- Hunger;
- Thirst;
- Sleep;
- Carry Weight;
- Skills + Level;
- Moodlets derived from real state.

The underlying modules remain independently replaceable and may grow later without rewriting the actor record or inspector.

## 2. Core architecture rule

> **Actor condition is composed from typed peer domains keyed by stable WHAT actor ID. There is no universal ActorStats dictionary.**

Each domain owns only its own persistent truth and exposes mutation-safe reads plus explicit mutation paths.

The future Stats/HUD layer is a **reader/composer**. It never becomes the owner of HP, needs, skills, item weight, carry capacity, or moodlet rules.

## 3. Child domains

### 13A — Actor Health / Injury

Owns physical health truth, including the requested HP display and the North-Star injury model.

Expected long-term responsibilities:

- current/max HP or equivalent coarse survivability value;
- injury records using type + body region + severity;
- stabilization/treatment/healing state;
- health-version/revision for stale action checks;
- future capability/timing modifier seam.

Health does not own hunger, fatigue, inventory weight, moodlet presentation, combat resolution, or first-aid action timing.

### 13B — Actor Needs / Rest

Owns the requested:

- fatigue;
- hunger;
- thirst;
- sleep pressure/rest need.

Important distinction:

- **Fatigue** = relatively short-term exertion/physical tiredness affected strongly by actions and immediate rest;
- **Sleep** = longer-horizon sleep pressure/debt affected mainly by time awake and actual sleep.

They may influence each other later, but remain separate values because the user explicitly wants both and they create different decisions.

Needs does not own food/water item identity, eating/drinking actions, beds, weather/temperature, moodlet strings, or movement implementation.

### 13C — Actor Skills

Owns persistent skill IDs, levels/ranks, and progression state.

Recovery reference from same-owner First Fire:

- Combat;
- Scavenging;
- Survival;
- Medical;
- Technical;
- Social;
- persistent skill XP;
- rank display;
- historical rank ceiling 10;
- historical next-rank XP rule `20 + rank * 15`.

Those exact vocabulary/progression details belong to the 13C child design before implementation; this umbrella records them only as proven recovery material.

Skills does not own occupations/background generation, item bonuses, action timing, combat resolution, or UI.

### 13D — Item Physical Properties

Owns physical properties of stable `item.*` identities required by multiple systems, beginning with **weight**.

Weight belongs to the item/property definition, not Inventory, Hands, Carry, or UI.

Future properties may include bulk, durability-related base facts, category tags or other genuinely shared physical data, but they are not added merely because the module exists.

13D does not own where an item is. WHAT/09/11/12 retain physical disposition/transition ownership.

### 13E — Carry / Encumbrance

Owns the derived question:

> how much is this survivor carrying, what is their current carrying capacity, and what consequence does that load create?

Current carried weight must be **derived** from:

- stable physical items personally possessed through 09 Hands + 11 Containment / 12 disposition semantics;
- 13D item weight;
- later capacity modifiers from Health, Skills, traits/equipment where explicitly designed.

Do not persist a second `carry_weight` total that can drift from physical inventory truth.

Carry/Encumbrance may expose current weight, capacity, ratio/state and future movement/action capability modifiers. It does not own item containment, item weights, locomotion state, or UI.

### 13F — Moodlets / Status Derivation

Moodlets are primarily **derived readable conditions**, not another independent bag of duplicated stats.

Examples of future derived moodlets:

- Hungry / Very Hungry;
- Thirsty / Dehydrated;
- Tired / Exhausted;
- Sleep Deprived / Well Rested;
- Injured / Badly Injured;
- Overburdened.

A moodlet reads owning modules and emits semantic status records suitable for HUD/UI. Thresholds/severity names belong to the 13F child design.

If a future effect genuinely has its own duration/history/source — for example a drug effect, panic episode, illness, morale event, or temporary buff/debuff — that effect should have an owning mechanic domain. Moodlets may present it; they do not become a generic effect-state dumping ground.

## 4. Stable actor identity

All persistent actor-state child modules key records by stable WHAT actor ID.

They do not key state by:

- Godot Node identity;
- array index;
- UI row;
- controlled-player role;
- renderer variant.

The same domains may later support NPC survivors and other appropriate living actors where their child contracts allow it.

## 5. Inspector / HUD composition seam

The future Stats inspector must not hardcode one monolithic actor record.

Preferred pattern:

- state domains expose narrow read APIs;
- a later dedicated **Actor Stat Read Model / Inspector Data** owner composes display facts through registered/read-only provider adapters;
- HUD requests a concise summary;
- detailed Stats requests the fuller provider output;
- adding a new stat domain later adds a provider/adapter rather than requiring Health/Needs/Skills rewrites.

No state module imports UI merely to display itself.

The exact UI/read-model contract belongs to the later Stats Inspector design.

## 6. Numeric representation rule

Use simple bounded numeric state where it creates clear gameplay meaning, but do not force every domain onto the same scale merely for UI convenience.

Likely examples:

- Needs values may use 0–100 internally/display-wise if their child design confirms it;
- HP may use current/max integer or fixed-point health values;
- skills use discrete levels + XP;
- carry uses physical weight units + capacity and derived ratio;
- moodlets use semantic IDs/severity rather than storing another 0–100 copy.

Child designs choose their own canonical representation and conversion rules.

## 7. Mutation / time rule

Persistent values change only through their owning modules.

WHEN owns time/order, but not meanings such as hunger, damage, sleep or skill gain.

Examples of later coordinators:

- an eating action spends ticks, then asks Needs to reduce hunger;
- taking damage asks Health to apply the health/injury consequence;
- sleeping advances through WHEN and asks Needs to alter fatigue/sleep pressure at explicit phases/events;
- a completed action awards skill XP through Skills;
- inventory transfer changes physical possession, after which Carry derives a new weight.

No child state module runs an implicit frame-time `_process()` simulation clock.

## 8. Persistence / versioning pattern

Where persistent child state exists, prefer the already-proven modular pattern:

- explicit enrollment where missing-state vs default-state matters;
- stable actor-ID key;
- mutation-safe copied reads;
- mutation service;
- per-actor version where stale timed actions need it;
- domain revision;
- deterministic atomic snapshot/restore;
- bounded semantic signals;
- no universal metadata bag.

A child may omit machinery it genuinely does not need, but should not bypass ownership boundaries for convenience.

## 9. Dependencies and forbidden coupling

### Allowed general dependencies

Child state modules may use:

- stable WHAT identity validation where appropriate;
- WHEN only through explicit gameplay coordinators/actions, not as hidden domain clocks;
- typed provider/modifier seams where a child design explicitly requires them.

### Forbidden umbrella-level coupling

Do not create:

- one `ActorStats.gd` storing all domains;
- Health importing Needs internals;
- Needs importing Inventory internals;
- Skills importing combat/UI internals;
- Item Properties owning containment;
- Carry mutating Inventory/Hands;
- Moodlets mutating Health/Needs/Carry;
- UI directly changing canonical values;
- renderer-owned stat truth;
- reboot-runtime adapters as the canonical implementation.

## 10. Recovery / archaeology

### Golden Tick `PlayerActor.gd`

Golden commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`, blob `2f839f1a50041c8bd00e144c1a9389d0a33d1401`, proves the old prototype used:

- `health = 100.0`;
- `carry_weight = 0.0`;
- `carry_capacity = 18.0`;
- `encumbrance_ratio`;
- `fatigue_ratio`;
- movement-cost modification from encumbrance/fatigue.

Those values were all stored in one PlayerActor object. The modular rebuild recovers useful semantics but explicitly rejects that ownership shape.

### First Fire

Current same-owner First Fire survivor state proves:

- 0–100 fatigue existed as real simulation state;
- six persistent skills existed: Combat, Scavenging, Survival, Medical, Technical, Social;
- skill XP existed;
- ranks advanced up to 10;
- the historical XP threshold was `20 + rank * 15`;
- the survivor inspector already presented fatigue and skill rank/XP.

These are recovery references, not permission to copy First Fire's monolithic survivor dictionaries.

## 11. Child dependency order toward the requested demo

The children are independent enough to implement in bounded slices. Recommended order:

1. **13C Skills** — most self-contained and strongest exact same-owner recovery;
2. **13B Needs** — fatigue/hunger/thirst/sleep persistent state;
3. **13A Health** — HP plus injury-capable state contract;
4. **13D Item Physical Properties** — real item weight;
5. **13E Carry / Encumbrance** — derived from 09/11/13D and later modifier seams;
6. **13F Moodlets** — derive readable statuses once source domains exist;
7. later Stats/HUD read model and UI.

This order is a development recommendation, not a gameplay dependency claim that Skills causes Health/Needs.

## 12. Performance / mobile

These domains are lightweight state/services:

- no per-frame full-actor scans;
- no Node per stat/moodlet;
- no UI polling requirement;
- signal/event-driven read-model refresh;
- deterministic direct stable-ID lookups;
- suitable for many persistent distant actors without materializing presentation Nodes.

Safari/mobile concerns belong primarily to the later inspector/control UI; state modules must remain UI-independent.

## 13. Tests / acceptance architecture

Each child system gets its own deterministic smoke/contract test and dedicated CI workflow or appropriately isolated contract job.

The umbrella is satisfied only if future children remain separately testable and no universal character-state store is introduced.

Later integration tests should prove the UI/read model composes through public reads rather than inspecting private dictionaries.

## 14. Future extension examples

Possible later modules without rewriting the approved peers:

- temperature;
- stress/panic;
- sickness/infection;
- pain;
- morale;
- traits/perks;
- medication/drug effects;
- radiation/toxin exposure if the game ever needs it.

Their existence is not pre-approved gameplay scope. The architecture simply leaves clean seams for them.

## 15. North-star fit

This structure supports **mini Zomboid** directly:

- simple player-readable stats;
- real systemic consequences;
- no unnecessary physiology simulation;
- persistent actor truth;
- no monolithic character bag;
- later systems can modify capability through explicit seams;
- the HUD stays simple while mechanics remain replaceable underneath.

## 16. Approved umbrella decisions — 2026-08-16

1. The requested visible character set is moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, and skills with levels.
2. Actor stats/status must remain modular so more domains can be added later without rewriting existing owners.
3. Health, Needs, Skills, Item Physical Properties, Carry/Encumbrance, and Moodlets are separate peer responsibilities.
4. Moodlets are primarily derived from real state rather than duplicated persistent values.
5. Carry weight is derived from real physical item possession + item weight, not maintained as a second drifting inventory total.
6. The future Stats inspector is a reader/composer and never the simulation owner.
7. Child systems still require bounded detailed designs/approvals before implementation; this umbrella approval does not authorize implementing all children together.
