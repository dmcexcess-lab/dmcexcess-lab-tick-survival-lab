# 16 Canonical Player Shell / Inspectors / Stance Integration

Status: **DRAFT — discussion only; do not implement until explicitly approved**

Drafted after the user playtested System 15, identified the duplicated legacy control/tick text under the HUD, and approved moving next toward crouch/stand plus `STATS`, `INVENTORY`, and `MENU`.

## 1. Goal

Complete the first useful player-facing shell around the live canonical demo by integrating already-implemented mechanics and state into phone/Safari-first controls and inspection screens.

Player-visible target:

- Crouch/Stand control using the real System 03 timed stance action;
- `STATS` button and modal showing only real actor state;
- `INVENTORY` button and modal showing only real 09/11 item disposition/container state;
- `MENU` button and modal using WHEN hard application pause;
- Resume / Close behavior that restores the prior hard-pause state correctly;
- Leave Game behavior suitable for the Web build;
- no duplicate legacy help/tick text underneath the System 15 HUD.

This is an integration/presentation system. It creates no new survival mechanic truth.

## 2. Why this can be one integration slice

Crouch, Health/Needs/Skills/Carry/Moodlets, Hands, Containment, and hard pause already have canonical owners and tests. System 16 does not redesign any of them.

The new work is one coherent application responsibility: expose those existing public contracts through the live player's control/inspection shell. The implementation remains split into focused query/presentation/input helpers so Stats, Inventory, Menu, and stance presentation can still change independently.

If implementation discovers that a requested screen requires a new simulation rule or a stable-contract rewrite, that part returns to design review instead of being patched into System 16.

## 3. Non-goals

System 16 does **not** add:

- new inventory transfer rules;
- pickup/drop/equip controls;
- demo items or item spawning;
- loose-item rendering;
- item use/consumption;
- item capacity/bulk rules;
- new Health/Needs/Skills progression;
- traits, stress, temperature, infection, or other nonexistent stats;
- door interaction;
- perception/LOS;
- camera/zoom;
- save/load;
- browser visibility/focus lifecycle pause automation;
- procedural generation.

An empty inventory, zero-level skills, no injuries, or other current real defaults must be displayed honestly rather than filled with placeholders.

## 4. Existing canonical systems reused unchanged

### 03 Actor Locomotion
Already owns standing/crouched state and `ActorStanceActionService`.

- crouch/stand costs the existing base 4 ticks before existing mobility modifiers;
- crouched walking already resolves through 03 at 1.4x the normal step duration;
- stance changes mutate only at the real timed commit.

System 16 only exposes that existing action through player input.

### 09 Hands + 11 Inventory / Containment
Remain the canonical physical possession state for held and contained items.

System 16 Inventory reads them; it does not mutate them.

### 12 Item Transfer Actions
Remains the future owner for actual pickup/drop/equip/container moves. System 16 does not bypass it.

### 13 Actor Status domains
Health, Needs, Skills, Carry and Moodlets remain separate canonical truths. System 16 composes reads only.

### WHEN hard pause
`TickKernel.set_hard_paused()` remains the only pause truth used by modal/menu UI.

## 5. Proposed owners

### `game/scripts/ui/ActorStatsInspectorQuery.gd`
Read-only composer for the detailed Stats modal.

Dependencies:

- existing `ActorStatusSummaryQuery`;
- `ActorHealthState` for injury list;
- `ActorSkillState` for skills/XP;
- `ActorLocomotionState` for current stance.

It returns presentation-ready typed facts but owns no actor state.

### `game/scripts/ui/ActorInventoryInspectorQuery.gd`
Read-only inventory/loadout query.

Dependencies:

- WHAT for item semantic identity;
- 09 Hand Equipment;
- 11 Inventory / Containment;
- 13D `ItemWeightQuery` where a real weight profile exists;
- 13E Carry Query for total carried weight/capacity.

It reports:

- anatomical right/primary hand;
- anatomical left/secondary hand;
- actor-root contained items;
- nested container contents recursively;
- stable item ID + semantic type + readable label;
- known weight when classified, otherwise explicit unknown weight;
- real carry total/capacity.

No UI grouping may erase stable physical identity. A visual list may group nothing unless a future quantity/stack system explicitly owns that meaning.

### `game/scripts/ui/CanonicalPlayerShell.gd`
CanvasLayer owner for:

- `STATS`, `INVENTORY`, `MENU` buttons;
- modal overlay/panel geometry;
- Stats modal presentation;
- Inventory modal presentation;
- Menu presentation;
- hard-pause acquisition/restoration for modal lifetime;
- Web/native Leave Game presentation behavior.

It does not mutate actor/world/inventory/stat truth.

### Existing `DemoMovementControls.gd`
Remains touch navigation input only.

System 16 may add one Crouch/Stand button beneath Turn Left, matching the existing mobile control area. It continues to emit semantic intent only.

### Existing `KeyboardInputAdapter.gd`
May add the desktop stance key and an explicit enabled/disabled gate. It still maps device input to semantic intent only.

### Existing `DemoPlayerActionController.gd`
May widen from Movement-only coordination to **player navigation/stance action coordination** by accepting the already-implemented `ActorStanceActionService` and locomotion state.

It still owns no destination, collision, stance timing, or locomotion mutation rule; it only chooses the existing canonical action service and runs WHEN to the next stop.

## 6. Stance input contract

V1 player intent adds one semantic UI action:

- `STANCE_TOGGLE`

The controller reads current canonical stance and translates that player request to exactly one existing System 03 call:

- standing -> `request_crouch(actor_id)`;
- crouched -> `request_stand(actor_id)`.

Why toggle at the input layer: one physical mobile button and the C key represent the player's intent to switch stance, while System 03 remains the owner of the actual target stance, timing, validation and commit.

The Crouch/Stand button text is presentation state only and must be refreshed from canonical `ActorLocomotionState` / `stance_changed` observation, not trusted as simulation truth.

Desktop:

- `C` = stance toggle.

Touch:

- one native Godot Button below Turn Left;
- label is `CROUCH` while standing and `STAND` while crouched;
- one press emits one semantic stance-toggle intent.

System 15 HUD receives the resolved action like other player actions and refreshes after the stance commit.

## 7. Stats modal contract

The Stats screen is a **read-only inspector**.

V1 sections:

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
- current real 13A injury records with type, body region, severity, stabilized/treated state;
- `None` when the real injury list is empty.

### Skills
Enumerate the 13C catalog dynamically rather than hardcoding UI fields:

- Combat;
- Scavenging;
- Survival;
- Medical;
- Technical;
- Social;
- current level;
- current XP / next threshold when below max level.

The live demo must explicitly enroll its survivor in 13C before the inspector is enabled. Current default levels/XP are real zero values, not placeholders.

Do not display traits, stress, temperature or other concepts until their owning systems exist.

## 8. Inventory modal contract

The Inventory screen is read-only in System 16.

V1 sections:

### Hands / Loadout
- Right Hand (primary/anatomical right);
- Left Hand (secondary/anatomical left).

### Carried Inventory
- direct actor-root contents;
- nested item-container contents indented beneath their parent;
- deterministic item order by stable ID unless a later presentation sorting rule is explicitly designed.

### Carry
- real derived current weight;
- real persistent capacity.

Empty current demo state must visibly say `Empty` rather than inventing starter gear.

Item labels are presentation humanization of semantic IDs only, e.g. `item.baseball_bat` -> `Baseball Bat`; the semantic type and stable ID remain available in the inspector result.

A missing 13D weight profile displays `Weight: Unknown`, never 0.

The modal exposes no Move/Drop/Equip/Use button in this slice. Those operations belong to a later interaction UI over System 12.

## 9. Menu / hard-pause contract

Opening **Stats, Inventory, or Menu** acquires hard application pause.

On the transition from no modal -> modal:

1. remember whether WHEN was already hard paused;
2. call `set_hard_paused(true)`;
3. show the modal.

Switching directly between Stats/Inventory/Menu keeps the same hard pause and does not overwrite the remembered prior state.

On final modal close / Resume:

- restore the hard-pause state that existed before the shell opened.

This prevents a UI screen from accidentally unpausing an application that was already paused for another reason.

### Touch/input blocking

A full-screen modal overlay consumes pointer input so movement buttons underneath cannot receive touches.

System 16 also adds an explicit enabled gate to the keyboard input adapter (and touch controls if necessary) so gameplay intents are not emitted while an inspector/menu is open.

Main only wires the shell's `interaction_blocked_changed` signal to those adapters; it does not own modal logic.

### Menu contents

- `RESUME`;
- `LEAVE GAME`.

### Leave Game

Web build:

1. use browser history/back when there is a useful prior page;
2. otherwise fall back to Google, preserving the earlier demo behavior rather than pretending a webpage can invoke Safari's configured home page.

Non-Web/native fallback may call the normal Godot quit path.

## 10. Header / layout direction

System 15 owns the 568..632 HUD band exclusively. The old controls help text and second tick/action label are removed.

For System 16 implementation:

- keep the 13x13 world view unchanged;
- keep System 15 HUD unchanged except ordinary refresh after stance actions;
- keep existing Forward/Back/Turn buttons;
- add Crouch/Stand below Turn Left;
- place Stats / Inventory / Menu in the top/header area with touch-sized native Godot Buttons;
- adjust/remove the decorative demo title as needed so buttons do not overlap;
- modal inspector uses a full-screen blocking overlay plus scrollable content where needed;
- no hover-only interaction.

Exact button rectangles belong to the UI owner and may be tuned during implementation as long as the world/HUD/control bands remain non-overlapping and Safari-friendly.

## 11. Public contracts

### Stats query

`query(actor_id: String) -> Dictionary`

Result includes:

- `ok` / `reason`;
- status summary;
- stance;
- injury entries;
- skill entries.

### Inventory query

`query(actor_id: String) -> Dictionary`

Result includes:

- `ok` / `reason`;
- primary/right hand item or empty;
- secondary/left hand item or empty;
- recursive actor-root inventory entries;
- carry result.

### Player shell

- `configure(kernel, stats_query, inventory_query, actor_id) -> bool`
- signal `interaction_blocked_changed(blocked: bool)`
- `open_stats()`
- `open_inventory()`
- `open_menu()`
- `close_modal()` / Resume
- `active_modal() -> StringName`
- `presentation_snapshot() -> Dictionary` for deterministic UI contract tests.

### Input owners

- retain signal `action_intent(intent)`;
- add `set_enabled(enabled: bool)` where required by modal blocking.

## 12. Failure / edge cases

- Missing Health/Needs/Skills/Carry truth => Stats fails visibly instead of supplying defaults.
- Missing hand/container enrollment => Inventory fails visibly instead of assuming empty.
- Missing WHAT item referenced by 09/11 => inventory row is explicit invalid/stale diagnostic; UI does not silently erase it.
- Containment recursion is bounded and cycle-guarded even though 11 already forbids cycles.
- Opening a second modal while one is open does not capture a second pause restore state.
- Closing a modal restores prior hard-pause state exactly once.
- Gameplay input is blocked while modal is active.
- Leave Game failure does not mutate simulation state.

## 13. Forbidden dependencies

New inspector/query/UI owners must not:

- call World/Health/Needs/Skills/Hands/Inventory mutation services;
- call System 12 transfer mutation/action paths;
- implement movement/stance duration or collision rules;
- import renderer/art selection;
- import Reboot;
- invent perception knowledge;
- invent item/stat values;
- advance WHEN directly except the existing player action coordinator running an accepted action and the shell owning hard application pause.

## 14. Acceptance tests

Dedicated System 16 CI should prove:

1. Godot project parses;
2. current System 14 and 15 regressions remain green;
3. legacy help text and duplicate controls tick label are absent from the live scene;
4. C key and touch stance button emit one semantic request each;
5. standing -> crouched spends the existing 4 stance ticks and commits real 03 state;
6. the stance button then presents `STAND` from real stance observation;
7. a crouched forward step uses the already-existing 14-tick movement result;
8. crouched -> standing spends the existing 4 stance ticks;
9. Stats shows real HP/needs/carry/moodlets/stance and all six real Skills records;
10. Stats shows no nonexistent traits/stress/etc.;
11. Inventory shows real empty hands/root inventory in the current itemless demo and real 0/18 kg carry;
12. synthetic nested inventory test renders stable recursive containment and unknown weight explicitly;
13. Stats/Inventory/Menu acquire hard pause and closing restores the previous hard-pause state;
14. switching modals does not incorrectly unpause or overwrite restore state;
15. gameplay keyboard/touch input is blocked while a modal is active;
16. Menu has Resume and Leave Game;
17. no new mutation dependency appears in inspector/query owners;
18. exact-final-SHA startup, Web export, and Pages deploy succeed.

## 15. Recovery sources

Useful UX recovery evidence:

- golden Tick `MapPreview.gd` blob `8ef5d900e5f56bb557bba496d10acc47438b38de`: Crouch button, Menu overlay, hard pause, Resume, Exit-to-Google behavior;
- same-owner First Fire `FFInspector.gd` blob `8eed5e9d6f768c0d23350e99c79ad0c0844b18ff`: full-screen scrolling character inspector and pause-on-inspection UX.

Recover the useful UX behavior only. Do not restore either monolithic architecture or nonexistent stats.

## 16. Future seams

After System 16:

- item/loose-item presentation can make Inventory visibly nonempty without changing inspector ownership;
- System 12 interaction UI can add pickup/drop/equip controls without moving containment/hand truth into the screen;
- future traits/stress/temperature domains can extend Stats through explicit new query dependencies;
- browser visibility/focus lifecycle can acquire the same WHEN hard-pause mechanism through a separate application-lifecycle owner;
- save/load can preserve simulation state independently of modal state.

## 17. North-star fit

System 16 turns the current walking/HUD demo into a usable survival-game shell without creating fake survival mechanics. It exposes real stance cost, real condition, real inventory truth, and safe real-life pause through small read/composition owners, preserving **Ultima-style turn-based mini Zomboid** and the rule that mini means reduced complexity rather than reduced consequence.

## 18. Draft decisions requiring explicit approval

1. Treat Crouch/Stand + Stats + Inventory + Menu as one bounded **integration** system because all owning simulation domains already exist; keep its internals independently replaceable.
2. Use a single semantic `STANCE_TOGGLE` input; controller translates current canonical stance into the existing System 03 crouch/stand action.
3. Stats is read-only and shows stance, HP, needs, carry, moodlets, injuries and all six Skills; no nonexistent traits/stress values.
4. Inventory is read-only in this slice and shows Hands + actor-root/nested Containment + Carry; no pickup/drop/equip/use buttons yet.
5. Any modal acquires WHEN hard pause and restores the exact prior hard-pause state on final close.
6. Modal UI blocks gameplay touch/keyboard input while open.
7. Web Leave Game tries useful browser history first and falls back to Google; it does not claim it can open Safari's configured home page.
8. The System 15 HUD becomes the sole tick/action status surface; legacy control help/action labels are vestigial and removed.
