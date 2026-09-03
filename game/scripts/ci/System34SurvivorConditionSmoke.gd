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
const HeardFearClass = preload("res://scripts/simulation/actors/condition/ConditionHeardFearAdapter.gd")
const ProfilesClass = preload("res://scripts/simulation/actors/condition/SurvivorSustainmentProfileCatalog.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const HandSlots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")

const ACTOR_ID: String = "actor.system34.test"

var failures: Array[String] = []

func _initialize() -> void:
    _test_tiers_and_modifiers()
    _test_time_and_fatigue()
    _test_overexertion_harm()
    _test_fear_policy()
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
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    _check(hand_mutations.enroll_actor(ACTOR_ID), "fixture hands enrolled")
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    _check(inventory_mutations.enroll_container(ACTOR_ID), "fixture personal inventory enrolled")
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(ACTOR_ID), "fixture carry enrolled")
    var physical_catalog := PhysicalCatalogClass.new()
    var carry := CarryQueryClass.new(
        world,
        hands,
        inventory,
        WeightQueryClass.new(world, physical_catalog),
        carry_state
    )
    _check(carry.configure_capacity_modifier(modifiers), "fixture carry reads condition capacity effects")
    var moodlets := MoodletClass.new(modifiers, health, carry)
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
        "mutations": mutations,
        "hand_mutations": hand_mutations,
        "physical_catalog": physical_catalog,
        "carry_state": carry_state,
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
    _check(green_moods.is_empty(), "positive meter state does not clutter moodlets")

    for channel: StringName in StateClass.CHANNELS:
        _check(service.set_condition(ACTOR_ID, channel, 0), "red channel set: %s" % String(channel))
    var red: Dictionary = modifiers.modifier_snapshot(ACTOR_ID)
    _check(int(red.get("health_multiplier_bp", 0)) >= 6000, "health penalty respects -40 percent cap")
    _check(int(red.get("fatigue_recovery_multiplier_bp", 0)) == 4000, "bad condition slows fatigue recovery to cap")
    _check(int(red.get("speed_multiplier_bp", 0)) == 6500, "speed penalty respects -35 percent cap")
    _check(int(red.get("carry_multiplier_bp", 0)) == 6000, "carry penalty respects -40 percent cap")
    _check(int(red.get("melee_damage_multiplier_bp", 0)) == 6500, "melee penalty respects -35 percent cap")
    var red_moods: Array = moodlets.moodlets_for(ACTOR_ID).get("moodlets", [])
    for channel: StringName in StateClass.CHANNELS:
        _check(_has_moodlet(red_moods, StringName("condition.%s.red" % String(channel))), "red channel produces moodlet: %s" % String(channel))
    _check(_has_moodlet(red_moods, &"health.injured"), "condition health cap produces a real injury moodlet")

    var mutations: WorldMutationService = fixture["mutations"]
    var hand_mutations: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    var physical_catalog: ItemPhysicalPropertyCatalog = fixture["physical_catalog"]
    var carry_state: ActorCarryState = fixture["carry_state"]
    _check(mutations.create_entity(&"item.rock", "item.condition.rock") == "item.condition.rock", "heavy fixture item exists")
    _check(physical_catalog.register_profile(&"item.rock", 20000), "heavy fixture item has physical mass")
    _check(hand_mutations.set_item(ACTOR_ID, HandSlots.Value.PRIMARY_RIGHT, "item.condition.rock"), "heavy fixture item is carried")
    var burdened_moods: Array = moodlets.moodlets_for(ACTOR_ID).get("moodlets", [])
    _check(_has_moodlet(burdened_moods, &"carry.overburdened"), "real carried mass produces Overburdened moodlet")
    _check(carry_state.set_capacity_grams(ACTOR_ID, 40000), "carry capacity can change for threshold fixture")
    var heavy_moods: Array = moodlets.moodlets_for(ACTOR_ID).get("moodlets", [])
    _check(_has_moodlet(heavy_moods, &"carry.heavy_load") and not _has_moodlet(heavy_moods, &"carry.overburdened"), "75-100 percent real load produces strongest-only Heavy Load moodlet")

func _test_time_and_fatigue() -> void:
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
    _check(int(after.get("calm", -1)) == int(before.get("calm", -2)), "no-threat time does not accumulate fear")

    _check(service.add_fatigue(ACTOR_ID, 50), "physical exertion adds fatigue")
    var spent: int = service.current_fatigue(ACTOR_ID)
    var same_tick: int = service.current_fatigue(ACTOR_ID)
    _check(spent == same_tick, "decision pause wall-clock does not recover fatigue")
    _advance(kernel, time_profile.ticks_per_minute(), &"test.wait.minute")
    _check(service.current_fatigue(ACTOR_ID) < spent, "WHEN minute recovers fatigue")
    var fatigue_moods: Array = (fixture["moodlets"] as ActorConditionMoodletQuery).moodlets_for(ACTOR_ID).get("moodlets", [])
    _check(_has_moodlet(fatigue_moods, &"condition.fatigue.winded"), "real fatigue derives Winded moodlet")

func _test_overexertion_harm() -> void:
    var fixture: Dictionary = _fixture()
    var service: ActorConditionService = fixture["service"]
    var health: ActorHealthState = fixture["health"]
    _check(service.add_fatigue(ACTOR_ID, 100), "heavy effort can nearly exhaust the survivor")
    _check(not service.can_start_run(ACTOR_ID), "severe fatigue blocks another run")
    var before: int = health.current_hp(ACTOR_ID)
    _check(service.add_fatigue(ACTOR_ID, 20), "survivor may still overexert through other physical work")
    _check(health.current_hp(ACTOR_ID) < before, "effort beyond maximum fatigue causes real health harm")
    for _index in range(20):
        service.add_fatigue(ACTOR_ID, 100)
    _check(health.current_hp(ACTOR_ID) == 0, "sustained overexertion can reach zero vitality through canonical health")

func _test_fear_policy() -> void:
    _check(HeardFearClass.fear_pressure(&"movement", 1.0) == 0, "ordinary movement sound is not fear")
    _check(HeardFearClass.fear_pressure(&"impact", 1.0) == 0, "ordinary impact sound is not fear")
    _check(HeardFearClass.fear_pressure(&"utility", 1.0) == 0, "ordinary utility sound is not fear")
    _check(HeardFearClass.fear_pressure(&"threat", 0.64) == 0, "weak threat sound stays below fear threshold")
    _check(HeardFearClass.fear_pressure(&"threat", 0.65) == HeardFearClass.THREAT_NOTICE_PRESSURE, "recognized threat sound produces bounded fear")
    _check(HeardFearClass.fear_pressure(&"threat", 0.85) == HeardFearClass.THREAT_SEVERE_PRESSURE, "severe recognized threat sound produces bounded fear")

    var fixture: Dictionary = _fixture()
    var service: ActorConditionService = fixture["service"]
    var kernel: TickKernel = fixture["kernel"]
    var time_profile: WorldTimeProfile = fixture["time"]
    _check(service.set_condition(ACTOR_ID, StateClass.CALM, 30), "fear recovery fixture sets low Calm")
    var before: int = service.value(ACTOR_ID, StateClass.CALM)
    _advance(kernel, time_profile.ticks_per_hour(), &"test.wait.calm_recovery")
    var after: int = service.value(ACTOR_ID, StateClass.CALM)
    _check(after > before and after <= 60, "Calm recovers toward neutral when no threat is present")

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
    service.add_fatigue(ACTOR_ID, 17)
    var saved: Dictionary = state.snapshot()
    var restored := StateClass.new(fixture["world"])
    _check(restored.load_snapshot(saved), "condition snapshot restores")
    _check(restored.snapshot() == saved, "condition snapshot round trip deterministic")

    var legacy: Dictionary = saved.duplicate(true)
    legacy["schema_version"] = StateClass.LEGACY_SCHEMA_VERSION
    var legacy_records: Array = legacy.get("records", [])
    if not legacy_records.is_empty():
        var legacy_record: Dictionary = (legacy_records[0] as Dictionary).duplicate(true)
        var fatigue_raw: int = int(legacy_record.get("fatigue_raw", 0))
        legacy_record["stamina_raw"] = StateClass.RAW_MAX - fatigue_raw
        legacy_record["stamina_anchor_tick"] = int(legacy_record.get("fatigue_anchor_tick", 0))
        legacy_record["metabolic_stamina_remainder"] = int(legacy_record.get("metabolic_exertion_remainder", 0))
        legacy_record["hydration_stamina_remainder"] = int(legacy_record.get("hydration_exertion_remainder", 0))
        for new_key: String in ["fatigue_raw", "fatigue_anchor_tick", "metabolic_exertion_remainder", "hydration_exertion_remainder", "overexertion_remainder"]:
            legacy_record.erase(new_key)
        legacy_records[0] = legacy_record
        legacy["records"] = legacy_records
        var migrated := StateClass.new(fixture["world"])
        _check(migrated.load_snapshot(legacy), "legacy stamina snapshot migrates")
        _check(int(migrated.record(ACTOR_ID).get("fatigue_raw", -1)) == fatigue_raw, "legacy remaining stamina inverts into fatigue pressure")
        _check(not migrated.record(ACTOR_ID).has("stamina_raw"), "migration removes duplicate stamina storage")
    var profiles := ProfilesClass.new()
    _check(profiles.has_profile(&"item.drink.water_bottle"), "real water bottle is drinkable")
    _check(profiles.has_profile(&"item.food.apple"), "real ready food is edible")
    _check(not profiles.has_profile(&"item.food.raw_meat"), "raw meat is not faked as ready food")

func _advance(kernel: TickKernel, duration_ticks: int, action_type: StringName) -> void:
    var serial: int = kernel.begin_action(ACTOR_ID, action_type, duration_ticks)
    _check(serial > 0, "test action begins: %s" % String(action_type))
    if serial > 0:
        kernel.run_until_stop()

static func _has_moodlet(values: Array, moodlet_id: StringName) -> bool:
    for value: Variant in values:
        if typeof(value) == TYPE_DICTIONARY and StringName((value as Dictionary).get("moodlet_id", &"")) == moodlet_id:
            return true
    return false

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
