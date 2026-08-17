extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const InjuryClass = preload("res://scripts/simulation/actors/health/ActorInjuryRecord.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_health_contract()
    _test_snapshot_contract()
    if failures.is_empty():
        print("ACTOR_HEALTH_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_HEALTH_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var health := HealthClass.new(world)
    return {"world": world, "wm": wm, "health": health}

func _test_health_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var health: ActorHealthState = fixture["health"]
    wm.create_entity(&"actor.survivor", "actor.a")
    wm.create_entity(&"actor.infected", "actor.z")
    _check(health.enroll_actor("actor.a"), "survivor enrolls")
    _check(not health.enroll_actor("actor.z"), "infected rejected")
    _check(health.current_hp("actor.a") == 100 and health.max_hp("actor.a") == 100, "recovered 100 HP baseline")
    _check(health.apply_damage("actor.a", 30) and health.current_hp("actor.a") == 70, "damage applies")
    _check(health.heal("actor.a", 10) and health.current_hp("actor.a") == 80, "healing applies")
    _check(health.apply_damage("actor.a", 999) and health.current_hp("actor.a") == 0, "damage clamps at zero")
    _check(health.heal("actor.a", 999) and health.current_hp("actor.a") == 100, "healing clamps at max")
    _check(not health.apply_damage("actor.a", 0) and not health.heal("actor.a", -1), "non-positive health deltas rejected")
    _check(health.set_max_hp("actor.a", 60) and health.current_hp("actor.a") == 60 and health.max_hp("actor.a") == 60, "max HP reduction clamps current")
    var before_revision: int = health.revision()
    var before_version: int = health.version("actor.a")
    _check(health.set_hp("actor.a", 60), "same HP write succeeds")
    _check(health.revision() == before_revision and health.version("actor.a") == before_version, "same HP is no-op")

    var injury_id: String = health.add_injury("actor.a", &"laceration", InjuryClass.LEFT_ARM, InjuryClass.Severity.SERIOUS)
    _check(not injury_id.is_empty(), "valid injury added")
    var second_id: String = health.add_injury("actor.a", &"bruise", InjuryClass.LEFT_ARM, InjuryClass.Severity.MINOR)
    _check(not second_id.is_empty() and second_id != injury_id and health.injuries("actor.a").size() == 2, "multiple same-region injuries coexist")
    _check(health.set_injury_state("actor.a", injury_id, InjuryClass.Severity.CRITICAL, true, true), "injury treatment/severity updates")
    var copy: ActorInjuryRecord = health.injury("actor.a", injury_id)
    _check(copy != null and copy.severity == InjuryClass.Severity.CRITICAL and copy.stabilized and copy.treated, "updated injury readable")
    if copy != null:
        copy.severity = InjuryClass.Severity.MINOR
    _check(health.injury("actor.a", injury_id).severity == InjuryClass.Severity.CRITICAL, "injury read is copy-safe")
    _check(health.remove_injury("actor.a", second_id) and health.injuries("actor.a").size() == 1, "injury removes explicitly")
    _check(health.add_injury("actor.a", &"", InjuryClass.HEAD, InjuryClass.Severity.MINOR).is_empty(), "empty injury type rejected")

func _test_snapshot_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var health: ActorHealthState = fixture["health"]
    for actor_id: String in ["z.actor", "a.actor"]:
        wm.create_entity(&"actor.survivor", actor_id)
        health.enroll_actor(actor_id)
    health.apply_damage("z.actor", 20)
    health.add_injury("a.actor", &"sprain", InjuryClass.RIGHT_LEG, InjuryClass.Severity.MINOR)
    var saved: Dictionary = health.snapshot()
    var records: Array = saved["records"]
    _check(records.size() == 2 and String(records[0]["actor_id"]) == "a.actor", "snapshot actor order deterministic")
    var restored := HealthClass.new()
    _check(restored.load_snapshot(saved), "snapshot restores without live WHAT dependency")
    _check(restored.snapshot() == saved, "snapshot round trip deterministic")
    var before_bad: Dictionary = restored.snapshot()
    var bad: Dictionary = before_bad.duplicate(true)
    bad["records"][0]["current_hp"] = 9999
    _check(not restored.load_snapshot(bad), "malformed HP snapshot rejected")
    _check(restored.snapshot() == before_bad, "malformed restore is atomic")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
