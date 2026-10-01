# Combat Feedback + Unarmed Viability Maintenance — 2026-09-30

## Outcome

Post-release combat now gives immediate player-facing resolution feedback and unarmed combat is a viable last-resort way to kill a zombie.

The canonical simple-turn combat owner remains `SimpleTurnController`. No new combat framework, scheduler or UI subsystem was introduced.

## Feedback

Successful combat outcomes now flow through the existing `action_resolved` -> `CanonicalStatusHud` surface instead of being discarded.

The HUD reports concise combat state such as:

- `FIST 8 DMG · ZOMBIE 92/100 HP · YOU -4 · 96/100 HP`
- `FIST 4 DMG · ZOMBIE DOWN`
- `SHOT ... DMG · ZOMBIE ... HP`
- `SHOT MISSED`
- `MISS`

Damage shown on a killing blow is the actual remaining HP removed rather than nominal overkill damage.

## Melee balance

The old unarmed effective mass produced roughly 2 HP per punch, making a 100-HP zombie take about 50 clean hits.

Canonical player unarmed striking now uses a committed-body effective mass rather than fist anatomy alone. In the focused production verifier:

- first unarmed hit = 8 HP;
- adjacent zombie retaliation = 4 HP;
- full-health zombie dies in 13 unarmed strikes;
- healthy player survives the uninterrupted one-on-one at 52/100 HP;
- killing blow performs the ordinary corpse transition.

An empty hand remains a valid strike even when the other hand holds a weak object. The controller chooses the strongest available current hand strike rather than blindly using the first held item.

Common practical melee items now have explicit existing-impact profiles so useful weapons remain preferable to fists, including kitchen knife, frying pan, hammer, crowbar, screwdriver, garden hoe and sturdy stick. Existing edge/point contact modes receive stronger derived transfer than blunt contact rather than relying on raw mass alone.

## Verification

Prompt-local verifier:

- `game/scripts/ci/verify_combat_feedback.gd`
- `.github/workflows/combat-feedback.yml`

The verifier boots through the real fresh-cache `main.tscn -> StartupMenu -> NEW GAME -> ProductionGameMain` route at a 390x844 host viewport and proves:

- canonical combat control;
- meaningful unarmed damage;
- zombie retaliation;
- hit/damage/HP feedback;
- feedback visibility in the production HUD;
- unarmed lethality within 15 strikes;
- player survival in an isolated one-on-one;
- canonical corpse transition;
- killing-blow feedback;
- miss feedback;
- idle-frame combat stability.
