extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const NeedsProviderClass = preload("res://scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd")
const ProviderBase = preload("res://scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_needs_contract()
    _test_snapshot_contract()
    if failures.is_empty():
        print("ACTOR_NEEDS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_NEEDS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var needs := NeedsClass.new(world)
    return {"wm": wm, "needs": needs}

func _test_needs_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var needs: ActorNeedsState = fixture["needs"]
    wm.create_entity(&"actor.survivor", "actor.a")
    wm.create_entity(&"actor.infected", "actor.z")
    _check(needs.enroll_actor("actor.a"), "survivor enrolls")
    _check(not needs.enroll_actor("actor.z"), "infected rejected")
    _check(needs.fatigue("actor.a") == 0 and needs.hunger("actor.a") == 0 and needs.thirst("actor.a") == 0 and needs.sleep_pressure("actor.a") == 0, "all needs default to zero pressure")
    _check(needs.set_need("actor.a", NeedsClass.FATIGUE, 50), "fatigue set")
    _check(needs.sleep_pressure("actor.a") == 0, "fatigue and sleep pressure remain independent")
    _check(needs.set_need("actor.a", NeedsClass.SLEEP_PRESSURE, 70), "sleep pressure set independently")
    _check(needs.change_need("actor.a", NeedsClass.FATIGUE, 80) and needs.fatigue("actor.a") == 100, "positive delta clamps at 100")
    _check(needs.change_need("actor.a", NeedsClass.THIRST, -50) and needs.thirst("actor.a") == 0, "negative delta clamps at zero")
    _check(not needs.set_need("actor.a", NeedsClass.HUNGER, 101), "out-of-range need rejected")
    var before_revision: int = needs.revision()
    var before_version: int = needs.version("actor.a")
    _check(needs.set_need("actor.a", NeedsClass.FATIGUE, 100), "same need succeeds")
    _check(needs.revision() == before_revision and needs.version("actor.a") == before_version, "same need is no-op")

    var provider := NeedsProviderClass.new(needs)
    var full: Dictionary = provider.evaluate("actor.a", &"movement.step_forward")
    _check(int(full.get("status", -1)) == ProviderBase.Status.ALLOWED and int(full.get("duration_adjustment_bp", -1)) == 6500, "fatigue 100 recovers +65 percent timing pressure")
    needs.set_need("actor.a", NeedsClass.FATIGUE, 40)
    var partial: Dictionary = provider.evaluate("actor.a", &"movement.turn_left")
    _check(int(partial.get("duration_adjustment_bp", -1)) == 2600, "fatigue scaling is exact integer basis points")
    var unrelated: Dictionary = provider.evaluate("actor.a", &"inventory.inspect")
    _check(int(unrelated.get("status", -1)) == ProviderBase.Status.ALLOWED and int(unrelated.get("duration_adjustment_bp", -1)) == 0, "unrelated actions unaffected")
    var missing: Dictionary = provider.evaluate("actor.missing", &"movement.step_forward")
    _check(int(missing.get("status", -1)) == ProviderBase.Status.UNKNOWN, "missing Needs fails closed through provider")

func _test_snapshot_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var needs: ActorNeedsState = fixture["needs"]
    for actor_id: String in ["b.actor", "a.actor"]:
        wm.create_entity(&"actor.survivor", actor_id)
        needs.enroll_actor(actor_id)
    needs.set_all("a.actor", 11, 22, 33, 44)
    var saved: Dictionary = needs.snapshot()
    _check(String(saved["records"][0]["actor_id"]) == "a.actor", "snapshot order deterministic")
    var restored := NeedsClass.new()
    _check(restored.load_snapshot(saved), "snapshot restores")
    _check(restored.snapshot() == saved, "snapshot round trip deterministic")
    var before_bad: Dictionary = restored.snapshot()
    var bad: Dictionary = before_bad.duplicate(true)
    bad["records"][0]["hunger"] = 101
    _check(not restored.load_snapshot(bad), "invalid need snapshot rejected")
    _check(restored.snapshot() == before_bad, "invalid restore is atomic")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
