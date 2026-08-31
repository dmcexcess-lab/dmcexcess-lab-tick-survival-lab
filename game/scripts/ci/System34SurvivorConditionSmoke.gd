extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const KernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const StateClass = preload("res://scripts/simulation/actors/condition/ActorConditionState.gd")
const ModifierClass = preload("res://scripts/simulation/actors/condition/ActorConditionModifierQuery.gd")
const ServiceClass = preload("res://scripts/simulation/actors/condition/ActorConditionService.gd")
const MoodletClass = preload("res://scripts/simulation/actors/condition/ActorConditionMoodletQuery.gd")
const ProfilesClass = preload("res://scripts/simulation/actors/condition/SurvivorSustainmentProfileCatalog.gd")

const ACTOR_ID: String = "actor.system34.test"

var failures: Array[String] = []

func _initialize() -> void:
    _test_tiers_and_modifiers()
    _test_time_and_stamina()
    _test_health_pressure_and_nonhealing_cap()
    _test_snapshot_and_profiles()
    if failures.is_empty():
        print("SYSTEM34_SURVIVOR_CONDITION_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("SYSTEM34_SURVIVOR_CONDITION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    _check(mutations.create_entity(&"actor.survivor", ACTOR_ID) == ACTOR_ID, "fixture survivor created")
    var health := HealthClass.new(world)
    _check(health.enroll_actor(ACTOR_ID), "fixture health enrolled")
    var kernel := KernelClass.new(ACTOR_ID)
    var time_profile := TimeProfileClass.new()
    var state := StateClass.new(world)
    _check(state.enroll_actor(ACTOR_ID, kernel.world_tick()), "fixture condition enrolled")
    var modifiers := ModifierClass.new(state, time_profile, kernel)
    var service := ServiceClass.new(state, health, kernel, time_profile, modifiers)
    var moodlets := MoodletClass.new(modifiers)
    _check(modifiers.is_ready() and service.is_ready() and moodlets.is_ready(), "fixture System 34 ready")
    return {
        "world": world,
        "health": health,
        "kernel": kernel,
        "time": time_profile,
        "state": state,
        "modifiers": modifiers,
        "service": service,
        "moodlets": moodlets,
    }

func _test_tiers_and_modifiers() -> void:
    var fixture: Dictionary = _fixture()
    var service: ActorConditionService = fixture["service"]
    var modifiers: ActorConditionModifierQuery = fixture["modifiers"]
    var moodlets: ActorConditionMoodletQuery = fixture["moodlets"]
    _check(moodlets.moodlets_for(ACTOR_ID).get("moodlets", []).is_empty(), "normal state has no moodlet")
    _check(modifiers.tier_for_value(80) == ModifierClass.TIER_GREEN, "80 is green")
    _check(modifiers.tier_for_value(79) == ModifierClass.TIER_NORMAL, "79 is normal")
    _check(modifiers.tier_for_value(45) == ModifierClass.TIER_NORMAL, "45 is normal")
    _check(modifiers.tier_for_value(44) == ModifierClass.TIER_YELLOW, "44 is yellow")
    _check(modifiers.tier_for_value(30) == ModifierClass.TIER_YELLOW, "30 is yellow")
    _check(modifiers.tier_for_value(29) == ModifierClass.TIER_ORANGE, "29 is orange")
    _check(modifiers.tier_for_value(15) == ModifierClass.TIER_ORANGE, "15 is orange")
    _check(modifiers.tier_for_value(14) == ModifierClass.TIER_RED, "14 is red")

    _check(service.set_condition(ACTOR_ID, StateClass.SATIETY, 85), "green satiety set")
    var positive: Dictionary = modifiers.modifier_snapshot(ACTOR_ID)
    _check(int(positive.get("health_multiplier_bp", 0)) > 10000, "green condition gives tiny health bonus")
    var green_moods: Array = moodlets.moodlets_for(ACTOR_ID).get("moodlets", [])
    _check(green_moods.size() == 1 and String((green_moods[0] as Dictionary).get("label", "")) == "Well Fed", "green Well Fed moodlet derived")

    for channel: StringName in StateClass.CHANNELS:
        _check(service.set_condition(ACTOR_ID, channel, 0), "red channel set: %s" % String(channel))
    var red: Dictionary = modifiers.modifier_snapshot(ACTOR_ID)
    _check(int(red.get("health_multiplier_bp", 0)) >= 6000, "health penalty respects -40 percent cap")
    _check(int(red.get("stamina_multiplier_bp", 0)) == 4000, "stamina penalty respects -60 percent cap")
    _check(int(red.get("speed_multiplier_bp", 0)) == 6500, "speed penalty respects -35 percent cap")
    _check(int(red.get("carry_multiplier_bp", 0)) == 6000, "carry penalty respects -40 percent cap")
    _check(int(red.get("melee_damage_multiplier_bp", 0)) == 6500, "melee penalty respects -35 percent cap")
    _check((moodlets.moodlets_for(ACTOR_ID).get("moodlets", []) as Array).size() == 6, "six red channels produce six moodlets")

func _test_time_and_stamina() -> void:
    var fixture: Dictionary = _fixture()
    var service: ActorConditionService = fixture["service"]
    var kernel: TickKernel = fixture["kernel"]
    var time_profile: WorldTimeProfile = fixture["time"]
    var before: Dictionary = service.values(ACTOR_ID)
    _advance(kernel, time_profile.ticks_per_hour(), &"test.wait.hour")
    var after: Dictionary = service.values(ACTOR_ID)
    _check(int(after.get("satiety", 100)) < int(before.get("satiety", 0)), "satiety decays from WHEN time")
    _check(int(after.get("hydration", 100)) < int(before.get("hydration", 0)), "hydration decays from WHEN time")
    _check(int(after.get("rest", 100)) < int(before.get("rest", 0)), "rest decays from WHEN time")

    _check(service.spend_stamina(ACTOR_ID, 50), "stamina spent")
    var spent: int = service.current_stamina(ACTOR_ID)
    var same_tick: int = service.current_stamina(ACTOR_ID)
    _check(spent == same_tick, "decision pause wall-clock does not recover stamina")
    _advance(kernel, time_profile.ticks_per_minute(), &"test.wait.minute")
    _check(service.current_stamina(ACTOR_ID) > spent, "WHEN minute recovers stamina")

func _test_health_pressure_and_nonhealing_cap() -> void:
    var fixture: Dictionary = _fixture()
    var service: ActorConditionService = fixture["service"]
    var health: ActorHealthState = fixture["health"]
    var kernel: TickKernel = fixture["kernel"]
    var time_profile: WorldTimeProfile = fixture["time"]

    for channel: StringName in StateClass.CHANNELS:
        service.set_condition(ACTOR_ID, channel, 0)
    var reduced_max: int = service.effective_max_health(ACTOR_ID)
    _check(health.current_hp(ACTOR_ID) == reduced_max, "worsening condition clamps current health to effective max")
    for channel: StringName in StateClass.CHANNELS:
        service.set_condition(ACTOR_ID, channel, 60)
    _check(service.effective_max_health(ACTOR_ID) == health.max_hp(ACTOR_ID), "recovered condition restores max-health ceiling")
    _check(health.current_hp(ACTOR_ID) == reduced_max, "restored ceiling does not magically heal lost HP")

    health.heal(ACTOR_ID, 100)
    service.set_condition(ACTOR_ID, StateClass.HYDRATION, 0)
    var before_hp: int = health.current_hp(ACTOR_ID)
    _advance(kernel, time_profile.ticks_per_hour(), &"test.wait.dehydrated")
    _check(health.current_hp(ACTOR_ID) <= before_hp - ServiceClass.DEHYDRATION_HP_PER_HOUR, "zero hydration causes real health damage")
    service.set_condition(ACTOR_ID, StateClass.ENGAGEMENT, 0)
    var mental_before: int = health.current_hp(ACTOR_ID)
    _advance(kernel, time_profile.ticks_per_hour(), &"test.wait.bored")
    _check(health.current_hp(ACTOR_ID) <= mental_before, "mental red state never heals or creates fake HP")

func _test_snapshot_and_profiles() -> void:
    var fixture: Dictionary = _fixture()
    var service: ActorConditionService = fixture["service"]
    var state: ActorConditionState = fixture["state"]
    service.set_condition(ACTOR_ID, StateClass.CALM, 12)
    service.spend_stamina(ACTOR_ID, 17)
    var saved: Dictionary = state.snapshot()
    var restored := StateClass.new(fixture["world"])
    _check(restored.load_snapshot(saved), "condition snapshot restores")
    _check(restored.snapshot() == saved, "condition snapshot round trip deterministic")
    var profiles := ProfilesClass.new()
    _check(profiles.has_profile(&"item.drink.water_bottle"), "real water bottle is drinkable")
    _check(profiles.has_profile(&"item.food.apple"), "real ready food is edible")
    _check(not profiles.has_profile(&"item.food.raw_meat"), "raw meat is not faked as ready food")

func _advance(kernel: TickKernel, duration_ticks: int, action_type: StringName) -> void:
    var serial: int = kernel.begin_action(ACTOR_ID, action_type, duration_ticks)
    _check(serial > 0, "test action begins: %s" % String(action_type))
    if serial > 0:
        kernel.run_until_stop()

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
