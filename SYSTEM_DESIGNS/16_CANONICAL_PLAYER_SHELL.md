# 16 Canonical Player Shell / Inspectors / Stance Integration

Status: **IMPLEMENTED**

Approved by the user on 2026-08-16 with the explicit instruction **“16 approved for code.”**

## 1. Goal

Complete the first useful player-facing shell around the live canonical demo by exposing already-implemented canonical mechanics/state through phone/Safari-first controls and read-only inspection screens.

Player-visible v1:

- Crouch/Stand using the real System 03 timed stance action;
- `STATS` modal showing only real actor state;
- `INVENTORY` modal showing only real possession/containment/carry state;
- `MENU` using WHEN hard application pause;
- Resume/Close restoring the exact prior hard-pause state;
- Leave Game behavior for Web/native builds;
- System 15 remains the sole tick/action HUD surface.

System 16 is integration/presentation only. It creates no new survival-mechanic truth.

## 2. Non-goals

System 16 does **not** add:

- pickup/drop/equip/move/use controls or new System 12 transfer rules;
- demo items, starter gear, item spawning, loose-item rendering, or held-item composition changes;
- stack/quantity/durability/bulk/capacity-transfer rules;
- new Health/Needs/Skills progression;
- traits, stress, temperature, infection, or other nonexistent stats;
- door interaction;
- perception/LOS;
- camera/zoom;
- save/load;
- browser visibility/focus lifecycle pause automation;
- generation.

Empty inventory, zero-level Skills, no injuries, and other current defaults are valid real state and are displayed honestly.

## 3. Canonical systems reused unchanged

### System 03 Actor Locomotion

System 03 remains the owner of standing/crouched state and `ActorStanceActionService`.

- voluntary crouch/stand base cost remains 4 ticks before existing mobility modifiers;
- crouched walking remains 1.4x ordinary step duration: 14 ticks on the current 10-tick demo terrain;
- stance mutates only at the existing timed commit.

### 09 Hands / 11 Containment / 12 Transfers

- 09 remains anatomical Right/Primary + Left/Secondary hand truth;
- 11 remains direct/nested containment truth;
- 12 remains the owner of timed pickup/drop/equip/container transitions.

System 16 reads 09/11 and never bypasses 12.

### System 13 status domains

Health, Needs, Skills, Item Physical Properties, Carry and Moodlets remain independent canonical owners. System 16 composes reads only.

### WHEN

`TickKernel.set_hard_paused()` / `is_hard_paused()` remain the sole pause truth used by modal/menu UI.

## 4. Implemented owners

### `game/scripts/ui/ActorStatsInspectorQuery.gd`

Read-only detailed actor-status composer over:

- `ActorStatusSummaryQuery`;
- `ActorHealthState` injuries;
- `ActorSkillState`;
- `ActorLocomotionState`.

Public contract:

`query(actor_id: String) -> Dictionary`

Result includes `ok/reason`, stance, status summary, injury entries and dynamic skill entries. No mutations or persistent UI state.

### `game/scripts/ui/ActorInventoryInspectorQuery.gd`

Read-only inventory/loadout query over:

- WHAT item identity;
- 09 Hands;
- 11 Containment;
- 13D `ItemWeightQuery`;
- 13E `ActorCarryQuery`.

Public contract:

`query(actor_id: String) -> Dictionary`

Result includes Right/Primary hand, Left/Secondary hand, recursive actor-root inventory and carry result. Stable item IDs are preserved. Missing/stale items are explicit invalid entries. Unknown item weight remains Unknown, never zero.

Traversal is bounded by depth/item guards in addition to 11’s cycle protections.

### `game/scripts/ui/CanonicalPlayerShell.gd`

CanvasLayer owner for:

- `STATS`, `INVENTORY`, `MENU` header buttons;
- full-screen blocking modal overlay;
- Stats/Inventory/Menu formatting;
- hard-pause acquisition/restoration;
- Resume/Close;
- Leave Game.

Public contract:

- `configure(kernel, stats_query, inventory_query, actor_id) -> bool`
- `interaction_blocked_changed(blocked)` signal
- `open_stats()`
- `open_inventory()`
- `open_menu()`
- `close_modal()`
- `active_modal() -> StringName`
- `presentation_snapshot() -> Dictionary`

It does not mutate actor/world/inventory/stat truth.

### Existing input/control owners

`PlayerActionIntent.gd` adds semantic `STANCE_TOGGLE`.

`KeyboardInputAdapter.gd`:

- `C` -> stance toggle;
- explicit `set_enabled(enabled)` gameplay-input gate.

`DemoMovementControls.gd`:

- native Crouch/Stand button below Turn Left;
- explicit enable gate;
- label follows canonical locomotion state;
- idempotent button initialization keeps its public configure/read/enable methods safe before or after normal `_ready()` delivery.

### Existing `DemoPlayerActionController.gd`

Now coordinates both existing Movement actions and existing System 03 stance actions. It selects the owning service, runs WHEN to the next stop, and reports the result. It owns no destination, collision, stance mutation, or timing rule.

### `CanonicalDemoMain.gd`

Composition only:

- enroll demo survivor in real 13C Skills;
- construct existing `ActorStanceActionService`;
- construct/inject read-only inspector queries;
- configure shell;
- wire shell interaction blocking to keyboard/touch enable gates.

## 5. Stance input behavior

Semantic intent:

`player.stance_toggle`

Controller translation from canonical state:

- standing -> `request_crouch(actor_id)`;
- crouched -> `request_stand(actor_id)`.

Desktop:

- `C` emits exactly one stance-toggle request.

Touch:

- one native Godot Button below Turn Left;
- `CROUCH` when canonical stance is standing;
- `STAND` when canonical stance is crouched;
- one press emits one semantic toggle.

Button text is presentation only and never becomes stance truth.

## 6. Stats modal

Stats is read-only.

### Condition

- stance;
- HP current/max;
- fatigue;
- hunger;
- thirst;
- sleep pressure;
- carry current/capacity;
- derived moodlets.

### Injuries

Each real injury shows type, body region, Minor/Serious/Critical severity, stabilized state and treated state. Empty injury state displays `None`.

### Skills

Enumerates the canonical 13C catalog dynamically:

- Combat;
- Scavenging;
- Survival;
- Medical;
- Technical;
- Social;
- level;
- current XP / next threshold below max;
- MAX at level 10.

The live demo explicitly enrolls the survivor in Skills; level-0/XP-0 values at boot are real canonical records, not placeholders.

No traits, stress, temperature, infection or other unimplemented domains are shown.

## 7. Inventory modal

Inventory is read-only in System 16.

### Hands / Loadout

- Right Hand = Primary / anatomical right;
- Left Hand = Secondary / anatomical left.

### Carried Inventory

- actor-root direct contents;
- nested item-container contents recursively;
- deterministic stable-ID order inherited from 11;
- stable item IDs remain visible in query/presentation truth;
- no grouping that invents stacks or erases physical identity.

### Weight / Carry

- known 13D item weights display normally;
- unclassified profiles display `Weight: Unknown`;
- Carry uses the real 13E result.

Current itemless demo shows Empty hands/root inventory and real `0.0 / 18.0 kg` carry. No starter gear is fabricated.

No Move/Drop/Equip/Use controls exist in this slice.

## 8. Menu / hard-pause behavior

Opening Stats, Inventory, or Menu acquires hard application pause.

On first transition from no modal to any modal:

1. capture whether WHEN was already hard paused;
2. call `set_hard_paused(true)`;
3. show the requested modal;
4. block gameplay input.

Switching directly among Stats/Inventory/Menu retains the same pause lifetime and does not overwrite the captured prior state.

On final Close/Resume:

- hide modal;
- restore exactly the captured previous hard-pause state;
- unblock gameplay input exactly once.

This prevents UI from accidentally unpausing a pause owned elsewhere.

A full-screen modal overlay consumes pointer input, while keyboard/touch adapters are explicitly disabled for the same modal lifetime.

Menu contains:

- `RESUME`;
- `LEAVE GAME`.

Web Leave Game attempts browser history/back when a previous history entry exists, otherwise falls back to Google. It does not claim to invoke Safari’s configured home page. Native fallback uses normal application quit behavior.

## 9. Layout / mobile requirements

- existing 13x13 world view remains unchanged;
- System 15 exclusively owns the 568..632 HUD band;
- existing Forward/Back/Turn buttons remain;
- Crouch/Stand sits below Turn Left;
- Stats/Inventory/Menu use touch-sized native Buttons in the top/header area;
- old decorative title/help/tick overlays do not return;
- modal is full-screen pointer-blocking with scrollable content;
- no hover-only interaction;
- one physical press -> one semantic intent.

## 10. Failure / edge behavior

- Missing Health/Needs/Skills/Carry truth => Stats reports unavailable, never defaults.
- Missing hand/root-container enrollment => Inventory reports unavailable, not assumed empty.
- Missing WHAT item referenced by 09/11 => explicit stale/invalid inventory entry.
- Missing item weight => explicit unknown weight.
- Direct modal switching does not recapture pause state.
- Final close restores prior pause exactly once.
- Gameplay input cannot leak through an active modal.
- Leave Game does not mutate simulation truth.

## 11. Forbidden dependencies

Inspector/query/UI owners do not:

- call World/Health/Needs/Skills/Hands/Inventory mutation services;
- call System 12 transfer actions;
- implement movement/collision/stance timing;
- import renderer/art selection;
- import Reboot;
- invent perception knowledge;
- invent item/stat values;
- use SceneTree pause as a substitute for WHEN hard pause.

## 12. Verification / acceptance

Dedicated `.github/workflows/canonical-player-shell.yml` covers:

1. architecture/source-boundary guards;
2. Godot 4.7.1 project parse;
3. System 03 Locomotion regression;
4. Health/Needs/Skills/Carry/Moodlets regressions;
5. 09 Hands and 11 Inventory regressions;
6. System 14 demo regression;
7. System 15 HUD regression;
8. System 16 integration smoke;
9. actual canonical scene startup.

The System 16 smoke proves:

- C key and touch stance button emit semantic toggle;
- standing -> crouched spends 4 ticks;
- touch label becomes `STAND` from real state;
- crouched forward step spends existing 14 ticks;
- crouched -> standing spends 4 ticks;
- Stats exposes real status/injuries/six Skills and no fake traits/stress;
- Inventory exposes real empty state and 0/18 kg carry;
- synthetic nested containment preserves stable IDs and explicit unknown weights;
- Stats/Inventory/Menu acquire hard pause and restore prior pause correctly;
- direct modal switching does not recapture pause state;
- modal lifetime blocks gameplay keyboard/touch input;
- Resume and Leave Game exist.

Initial candidate run `31996350075` passed all protected regressions, but the smoke inspected dynamically added touch controls synchronously before Godot delivered `_ready()`. Stance simulation itself passed; only button existence/label assertions failed.

`DemoMovementControls` was hardened with idempotent `_ensure_buttons()` so its public configure/read/enable methods are lifecycle-safe. Hardened code head:

`dce48115f35ef6487bcbe8811fe945d2e5012cff`

Dedicated System 16 run:

`31996425080` — **SUCCESS**.

Final completion is validated again on the promoted exact-final SHA through System 16, Systems 14/15 regressions, startup, Web export and Pages deployment.

## 13. Recovery sources

UX evidence only:

- golden Tick `MapPreview.gd` blob `8ef5d900e5f56bb557bba496d10acc47438b38de`: Crouch button, Menu/Resume, exit behavior;
- same-owner First Fire `FFInspector.gd` blob `8eed5e9d6f768c0d23350e99c79ad0c0844b18ff`: full-screen scrolling inspector and previous-pause restoration pattern.

Neither monolithic architecture nor nonexistent state was restored.

## 14. Future seams

After System 16:

- loose-item presentation can make Inventory visibly nonempty without changing inspector ownership;
- System 12 UI can add pickup/drop/equip actions without moving possession truth into UI;
- existing System 10 BACK/body/FRONT held-item composition can be inserted when real equipped demo items exist;
- future stat domains may extend Stats explicitly;
- browser/app lifecycle may acquire WHEN hard pause through a separate lifecycle owner;
- save/load remains independent of modal state.

## 15. North-star fit

System 16 turns the walking/HUD demo into a usable survival-game shell without fake mechanics. It exposes real stance cost, real actor condition, real physical inventory truth and real-life-safe hard pause through replaceable owners, fitting **Ultima-style turn-based mini Zomboid** and the rule that mini means reduced complexity rather than reduced consequence.

## 16. Approved decisions

1. Crouch/Stand + Stats + Inventory + Menu form one bounded integration slice because their simulation owners already exist.
2. One semantic `STANCE_TOGGLE` maps canonical stance to existing System 03 crouch/stand actions.
3. Stats is read-only and shows stance, HP, needs, carry, moodlets, injuries and six Skills only.
4. Inventory is read-only and shows Hands + actor-root/nested Containment + Carry; no pickup/drop/equip/use yet.
5. Any modal acquires WHEN hard pause and final close restores exact prior hard-pause state.
6. Modal UI blocks gameplay keyboard/touch input.
7. Web Leave Game tries browser history first and otherwise falls back to Google; no Safari-homepage claim.
8. System 15 remains the sole tick/action HUD surface; legacy help/action overlays remain removed.
