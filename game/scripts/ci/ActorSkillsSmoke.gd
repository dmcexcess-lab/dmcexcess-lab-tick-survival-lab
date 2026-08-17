extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const Catalog = preload("res://scripts/simulation/actors/skills/ActorSkillCatalog.gd")
const SkillsClass = preload("res://scripts/simulation/actors/skills/ActorSkillState.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_skill_contract()
    _test_snapshot_contract()
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
    _check(ids == [Catalog.COMBAT, Catalog.SCAVENGING, Catalog.SURVIVAL, Catalog.MEDICAL, Catalog.TECHNICAL, Catalog.SOCIAL], "six recovered skills keep deterministic order")
    _check(skills.level("actor.a", Catalog.COMBAT) == 0 and skills.xp("actor.a", Catalog.COMBAT) == 0, "enrolled skills start at level zero")
    _check(skills.next_level_xp("actor.a", Catalog.COMBAT) == 20, "level zero threshold is 20")
    _check(skills.award_xp("actor.a", Catalog.COMBAT, 20), "threshold XP award accepted")
    _check(skills.level("actor.a", Catalog.COMBAT) == 1 and skills.xp("actor.a", Catalog.COMBAT) == 0, "20 XP advances to level one")
    _check(skills.next_level_xp("actor.a", Catalog.COMBAT) == 35, "level one threshold is 35")
    _check(skills.award_xp("actor.a", Catalog.COMBAT, 35), "second threshold accepted")
    _check(skills.level("actor.a", Catalog.COMBAT) == 2 and skills.xp("actor.a", Catalog.COMBAT) == 0, "35 XP advances level one to two")
    _check(skills.set_skill("actor.a", Catalog.MEDICAL, 0, 19), "setup path accepts normalized XP")
    _check(skills.award_xp("actor.a", Catalog.MEDICAL, 86), "large award accepted")
    _check(skills.level("actor.a", Catalog.MEDICAL) == 3 and skills.xp("actor.a", Catalog.MEDICAL) == 0, "large award crosses 20+35+50 deterministically")
    _check(skills.award_xp("actor.a", Catalog.SURVIVAL, 100000), "huge award accepted")
    _check(skills.level("actor.a", Catalog.SURVIVAL) == 10 and skills.xp("actor.a", Catalog.SURVIVAL) == 0, "level ten cap stores zero XP")
    var before_revision: int = skills.revision()
    var before_version: int = skills.version("actor.a")
    _check(skills.award_xp("actor.a", Catalog.SURVIVAL, 10), "XP at cap succeeds as capped no-op")
    _check(skills.revision() == before_revision and skills.version("actor.a") == before_version, "cap award changes no state")
    _check(not skills.set_skill("actor.a", &"alchemy", 1, 0), "unknown skill rejected")
    _check(not skills.set_skill("actor.a", Catalog.SOCIAL, 11, 0), "level above cap rejected")
    _check(not skills.set_skill("actor.a", Catalog.SOCIAL, 0, 20), "unnormalized XP rejected")
    var copy: Dictionary = skills.record("actor.a")
    copy["levels"][String(Catalog.COMBAT)] = 9
    _check(skills.level("actor.a", Catalog.COMBAT) == 2, "record read is copy-safe")

func _test_snapshot_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var skills: ActorSkillState = fixture["skills"]
    for actor_id: String in ["z.actor", "a.actor"]:
        wm.create_entity(&"actor.survivor", actor_id)
        skills.enroll_actor(actor_id)
    skills.set_skill("a.actor", Catalog.TECHNICAL, 4, 2)
    var saved: Dictionary = skills.snapshot()
    _check(String(saved["records"][0]["actor_id"]) == "a.actor", "snapshot actor order deterministic")
    _check(String(saved["records"][0]["skills"][0]["skill_id"]) == "combat", "snapshot skill order deterministic")
    var restored := SkillsClass.new()
    _check(restored.load_snapshot(saved), "snapshot restores")
    _check(restored.snapshot() == saved, "snapshot round trip deterministic")
    var before_bad: Dictionary = restored.snapshot()
    var bad: Dictionary = before_bad.duplicate(true)
    bad["records"][0]["skills"][0]["skill_id"] = "alchemy"
    _check(not restored.load_snapshot(bad), "unknown skill snapshot rejected")
    _check(restored.snapshot() == before_bad, "bad skill restore atomic")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
