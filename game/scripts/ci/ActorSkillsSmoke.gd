extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Catalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const SkillsClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")
const ChecksClass = preload("res://scripts/simulation/actors/skills/ActorSkillCheckService.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_skill_contract()
    _test_action_check_contract()
    _test_snapshot_contract()
    _test_legacy_snapshot_migration()
    if failures.is_empty():
        print("ACTOR_SKILLS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_SKILLS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var skills := SkillsClass.new(world)
    return {"wm": wm, "skills": skills}

func _test_skill_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var skills: ActorSkillState = fixture["skills"]
    wm.create_entity(&"actor.survivor", "actor.a")
    wm.create_entity(&"actor.infected", "actor.z")
    _check(skills.enroll_actor("actor.a"), "survivor enrolls")
    _check(not skills.enroll_actor("actor.z"), "infected rejected")
    var ids: Array[StringName] = skills.skill_ids()
    _check(ids == [Catalog.AWARENESS, Catalog.STEALTH, Catalog.MECHANICAL, Catalog.SURVIVAL], "four canonical skills keep deterministic order")
    _check(skills.display_name(Catalog.AWARENESS) == "Awareness" and skills.display_name(Catalog.MECHANICAL) == "Mechanical", "canonical skill labels resolve")
    _check(skills.level("actor.a", Catalog.AWARENESS) == 0 and skills.xp("actor.a", Catalog.AWARENESS) == 0, "enrolled skills start at level zero")
    _check(skills.next_level_xp("actor.a", Catalog.AWARENESS) == 20, "level zero threshold is 20")
    _check(skills.award_xp("actor.a", Catalog.AWARENESS, 20), "threshold XP award accepted")
    _check(skills.level("actor.a", Catalog.AWARENESS) == 1 and skills.xp("actor.a", Catalog.AWARENESS) == 0, "20 XP advances to level one")
    _check(skills.next_level_xp("actor.a", Catalog.AWARENESS) == 35, "level one threshold is 35")
    _check(skills.award_xp("actor.a", Catalog.AWARENESS, 35), "second threshold accepted")
    _check(skills.level("actor.a", Catalog.AWARENESS) == 2 and skills.xp("actor.a", Catalog.AWARENESS) == 0, "35 XP advances level one to two")
    _check(skills.set_skill("actor.a", Catalog.MECHANICAL, 0, 19), "setup path accepts normalized XP")
    _check(skills.award_xp("actor.a", Catalog.MECHANICAL, 86), "large award accepted")
    _check(skills.level("actor.a", Catalog.MECHANICAL) == 3 and skills.xp("actor.a", Catalog.MECHANICAL) == 0, "large award crosses 20+35+50 deterministically")
    _check(skills.award_xp("actor.a", Catalog.SURVIVAL, 100000), "huge award accepted")
    _check(skills.level("actor.a", Catalog.SURVIVAL) == 10 and skills.xp("actor.a", Catalog.SURVIVAL) == 0, "level ten cap stores zero XP")
    var before_revision: int = skills.revision()
    var before_version: int = skills.version("actor.a")
    _check(skills.award_xp("actor.a", Catalog.SURVIVAL, 10), "XP at cap succeeds as capped no-op")
    _check(skills.revision() == before_revision and skills.version("actor.a") == before_version, "cap award changes no state")
    _check(not skills.set_skill("actor.a", &"medical", 1, 0), "retired legacy skill is not live")
    _check(not skills.set_skill("actor.a", Catalog.STEALTH, 11, 0), "level above cap rejected")
    _check(not skills.set_skill("actor.a", Catalog.STEALTH, 0, 20), "unnormalized XP rejected")
    var copy: Dictionary = skills.record("actor.a")
    copy["levels"][String(Catalog.AWARENESS)] = 9
    _check(skills.level("actor.a", Catalog.AWARENESS) == 2, "record read is copy-safe")

func _test_action_check_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var skills: ActorSkillState = fixture["skills"]
    wm.create_entity(&"actor.survivor", "actor.skill")
    _check(skills.enroll_actor("actor.skill"), "skill-check actor enrolls")
    var checks := ChecksClass.new(skills)
    _check(checks.is_ready(), "skill-check service ready")
    var novice: Dictionary = checks.action_profile("actor.skill", Catalog.SURVIVAL, 10, 1)
    _check(bool(novice.get("ok", false)) and int(novice.get("duration_ticks", 0)) > 10, "novice Survival makes the same physical action slower")
    _check(skills.set_skill("actor.skill", Catalog.SURVIVAL, 10, 0), "expert Survival fixture set")
    var expert: Dictionary = checks.action_profile("actor.skill", Catalog.SURVIVAL, 10, 1)
    _check(bool(expert.get("ok", false)) and int(expert.get("duration_ticks", 99)) < int(novice.get("duration_ticks", 0)), "higher skill reduces bounded action time")
    _check(int(expert.get("success_chance_percent", 0)) == 100, "expert easy action reaches guaranteed competence")
    var success_a: Dictionary = checks.resolve_attempt("actor.skill", Catalog.SURVIVAL, 1, 77, &"ci.same", 10)
    var success_b: Dictionary = checks.resolve_attempt("actor.skill", Catalog.SURVIVAL, 1, 77, &"ci.same", 10)
    _check(success_a == success_b and bool(success_a.get("success", false)), "skill attempt is deterministic for the same action identity")

    _check(skills.set_skill("actor.skill", Catalog.MECHANICAL, 0, 0), "novice Mechanical fixture set")
    var found_failure: bool = false
    for serial in range(1, 201):
        var attempt: Dictionary = checks.resolve_attempt("actor.skill", Catalog.MECHANICAL, 10, serial, &"ci.failure", 0)
        if bool(attempt.get("ok", false)) and not bool(attempt.get("success", true)):
            found_failure = true
            break
    _check(found_failure, "low skill has deterministic real failure risk")
    var xp_before: int = skills.xp("actor.skill", Catalog.MECHANICAL)
    _check(checks.award_attempt_xp("actor.skill", Catalog.MECHANICAL, 2, false), "failed attempt still teaches bounded XP")
    _check(skills.xp("actor.skill", Catalog.MECHANICAL) > xp_before, "attempt XP mutates canonical skill state")

func _test_snapshot_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var skills: ActorSkillState = fixture["skills"]
    for actor_id: String in ["z.actor", "a.actor"]:
        wm.create_entity(&"actor.survivor", actor_id)
        skills.enroll_actor(actor_id)
    skills.set_skill("a.actor", Catalog.MECHANICAL, 4, 2)
    var saved: Dictionary = skills.snapshot()
    _check(int(saved.get("schema_version", 0)) == 2, "new skill snapshot is schema v2")
    _check(String(saved["records"][0]["actor_id"]) == "a.actor", "snapshot actor order deterministic")
    _check(String(saved["records"][0]["skills"][0]["skill_id"]) == "awareness", "snapshot skill order starts with Awareness")
    var restored := SkillsClass.new()
    _check(restored.load_snapshot(saved), "snapshot restores")
    _check(restored.snapshot() == saved, "snapshot round trip deterministic")
    var before_bad: Dictionary = restored.snapshot()
    var bad: Dictionary = before_bad.duplicate(true)
    bad["records"][0]["skills"][0]["skill_id"] = "medical"
    _check(not restored.load_snapshot(bad), "retired skill in v2 snapshot rejected")
    _check(restored.snapshot() == before_bad, "bad skill restore atomic")

func _test_legacy_snapshot_migration() -> void:
    var legacy: Dictionary = {
        "schema_version": 1,
        "revision": 1,
        "records": [{
            "actor_id": "actor.legacy",
            "version": 1,
            "skills": [
                {"skill_id": "combat", "level": 8, "xp": 1},
                {"skill_id": "scavenging", "level": 2, "xp": 3},
                {"skill_id": "survival", "level": 1, "xp": 4},
                {"skill_id": "medical", "level": 3, "xp": 5},
                {"skill_id": "technical", "level": 4, "xp": 2},
                {"skill_id": "social", "level": 7, "xp": 6},
            ],
        }],
    }
    var restored := SkillsClass.new()
    _check(restored.load_snapshot(legacy), "schema-v1 six-skill snapshot migrates")
    _check(restored.level("actor.legacy", Catalog.AWARENESS) == 0 and restored.level("actor.legacy", Catalog.STEALTH) == 0, "new Awareness and Stealth start fresh")
    _check(restored.level("actor.legacy", Catalog.MECHANICAL) == 4 and restored.xp("actor.legacy", Catalog.MECHANICAL) == 2, "legacy Technical maps exactly to Mechanical")
    _check(restored.level("actor.legacy", Catalog.SURVIVAL) == 3 and restored.xp("actor.legacy", Catalog.SURVIVAL) == 5, "strongest Scavenging/Survival/Medical progression maps to Survival without triple counting")
    var migrated: Dictionary = restored.snapshot()
    _check(int(migrated.get("schema_version", 0)) == 2 and migrated["records"][0]["skills"].size() == 4, "legacy restore immediately emits canonical four-skill schema")

    var malformed: Dictionary = legacy.duplicate(true)
    malformed["records"][0]["skills"].pop_back()
    var before: Dictionary = restored.snapshot()
    _check(not restored.load_snapshot(malformed), "partial legacy skill record rejected")
    _check(restored.snapshot() == before, "failed legacy migration is atomic")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
