function sim_get_zone_profile(sim) {
    var key = "Town";
    if (sim.zone == "Wilderness") {
        if (sim.overland_biome == "Fields") key = "Wilderness: Fields";
        else if (sim.overland_biome == "Woods") key = "Wilderness: Woods";
        else key = "Wilderness: Fields";
    } else if (sim.zone == "Dungeon") {
        if (sim.dungeon_type == "Cursed Temple") key = "Dungeon: Cursed Temple";
        else key = "Dungeon: Cursed Temple";
    }

    var profiles = {
        "Town": {
            enemy_weights: { "Brigand Captain": 1.0, "Shieldbearer Veteran": 1.0, "Plague Rat Pack": 0.9 },
            hazard_weights: { spore: 0.35, collapse: 0.40 },
            social_weights: { whispers: 1.35, rivals: 1.40 },
            merchant_pool: ["consumable", "trinket", "armor"],
            tension_modifier: 0.85
        },
        "Wilderness: Fields": {
            beat_weights: {
                combat: 60,
                exploration: 20,
                merchant: 10,
                social: 10
            },
            enemy_weights: {
                "Raider Scout": 1.35,
                "Mounted Bandit": 1.25,
                "Spear Militia": 1.20,
                "Field Cultist": 1.25,
                "War Hound": 1.20,
                "Bog Leech": 1.10
            },
            hazard_weights: { spore: 0.90, collapse: 1.15 },
            social_weights: { whispers: 1.00, rivals: 0.85 },
            merchant_pool: ["weapon", "armor", "consumable"],
            tension_modifier: 1.05
        },
        "Wilderness: Woods": {
            beat_weights: {
                combat: 45,
                hazard: 20,
                social: 20,
                exploration: 15
            },
            enemy_weights: {
                "Briar Stalker": 1.35,
                "Forest Warden": 1.20,
                "Poison Archer": 1.35,
                "Moss Golem": 1.10,
                "Shrieking Crow Swarm": 1.25,
                "Root Snare Entity": 1.30
            },
            hazard_weights: { spore: 1.35, collapse: 0.95 },
            social_weights: { whispers: 1.10, rivals: 0.95 },
            merchant_pool: ["trinket", "consumable", "weapon"],
            tension_modifier: 1.10
        },
        "Dungeon: Cursed Temple": {
            beat_weights: {
                combat: 55,
                hazard: 25,
                relief: 10,
                social: 10
            },
            enemy_weights: {
                "Bone Sentinel": 1.30,
                "Ritual Adept": 1.25,
                "Chain Thrall": 1.30,
                "Echo Wraith": 1.20,
                "Temple Guardian Idol": 1.10,
                "Ash Revenant": 1.25
            },
            hazard_weights: { spore: 1.20, collapse: 1.30 },
            social_weights: { whispers: 0.95, rivals: 0.75 },
            merchant_pool: ["trinket", "consumable", "armor"],
            tension_modifier: 1.18
        }
    };

    return variable_struct_get(profiles, key);
}

function sim_run_init(sim, seed, beats_target) {
    var short_mode = (variable_global_exists("debug_short_mode") && global.debug_short_mode);
    var very_short_mode = (variable_global_exists("debug_very_short_mode") && global.debug_very_short_mode);

    // Core run state
    global.debug_seed = seed;
    sim.seed = seed;
    sim.rng = seed;
    sim.beat = 0;
    var target_cap = very_short_mode ? 16 : (short_mode ? 36 : beats_target);
    sim.beats_target = min(beats_target, target_cap);
    sim.finished = false;
    if (!variable_struct_exists(sim, "episode_begun_logged")) sim.episode_begun_logged = false;

    sim.route_generated = false;
    sim.city_phase_executed = false;
    sim.adventure_initialized = false;
    sim.starter_kit_applied = false;

    // ---- Episode flags reset (must reset each run; sim struct is reused) ----
    if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};
    sim.flags.hook_emitted = false;
    sim.flags.complication_emitted = false;
    sim.flags.boss_begun = false;
    sim.flags.adventure_start_emitted = false;

    sim.intel = {
        trap_warning: false,
        boss_weakness_known: false
    };

    // A biome is just the kind of outdoor place the party travels through,
    // like Forest, Swamp, or Road.
    //
    // HOW TO ADD A NEW BIOME (step by step):
    // 1) Add the new biome name to this biome_options list.
    // 2) Add a matching monster pool for that biome in sim_make_combat_encounter.
    //    If you skip step 2, the code falls back to generic Wilderness monsters.
    // 3) Optional: add biome-flavored travel text where route messages are built.
    var biome_options = ["Fields", "Foothills", "Mountains", "Forest", "Woods", "Swamp", "Coast", "Road"];

    // A dungeon type is the scary final place, like Ruined Castle or Cave System.
    //
    // HOW TO ADD A NEW DUNGEON TYPE (step by step):
    // 1) Add the new type name to this dungeon_type_options list.
    // 2) Add a matching monster pool for that dungeon type in sim_make_combat_encounter.
    // 3) Optional: add special merchant/travel flavor text for that type.
    var dungeon_type_options = ["Ruined Castle", "Cursed Temple", "Cave System", "Ancient Dungeon"];

    var biome_a_idx = sim_rand_range(sim, 0, array_length(biome_options) - 1);
    var biome_b_idx = sim_rand_range(sim, 0, array_length(biome_options) - 1);
    while (biome_b_idx == biome_a_idx) {
        biome_b_idx = sim_rand_range(sim, 0, array_length(biome_options) - 1);
    }

    var biome_a = biome_options[biome_a_idx];
    var biome_b = biome_options[biome_b_idx];
    var dungeon_type = dungeon_type_options[sim_rand_range(sim, 0, array_length(dungeon_type_options) - 1)];

    sim.route_segments = [
        { zone: "Town", biome: "City", dungeon_type: "" },
        { zone: "Wilderness", biome: biome_a, dungeon_type: "" },
        { zone: "Wilderness", biome: biome_b, dungeon_type: "" },
        { zone: "Dungeon", biome: "", dungeon_type: dungeon_type }
    ];
    sim.route_index = 0;
    sim.route_generated = true;
    sim.cine_dungeon_enter_emitted = false;

    var seg0 = sim.route_segments[0];
    sim.zone = seg0.zone;
    sim.overland_biome = seg0.biome;
    sim.dungeon_type = seg0.dungeon_type;
    sim.zone_profile = sim_get_zone_profile(sim);

    sim.route_milestone_1 = 2;
    sim.route_milestone_2 = max(sim.route_milestone_1 + 1, floor(sim.beats_target / 3));
    sim.route_milestone_3 = max(sim.route_milestone_2 + 1, floor((sim.beats_target * 2) / 3));

    sim.difficulty = 1;
    sim.tension = 10;
    sim.tension_current = 0;
    sim.tension_threshold = sim_rand_range(sim, 28, 45);
    sim.gold_total = 0;

    sim.wound_retreat_threshold = very_short_mode ? 2 : (short_mode ? 2 : 3);
    sim.retreat_to_city = false;
    sim.retreat_beats_left = 0;
    sim.city_scene_pending = false;
    sim.city_scene_played = false;

    if (!variable_struct_exists(sim, "episode_index")) sim.episode_index = 1;
    if (!variable_struct_exists(sim, "city_reputation")) sim.city_reputation = 0;
    if (!variable_struct_exists(sim, "city_favor")) sim.city_favor = 0;
    if (!variable_struct_exists(sim, "city_reputation_tier")) sim.city_reputation_tier = "neutral";
    if (!variable_struct_exists(sim, "city_merchant_price_mult")) sim.city_merchant_price_mult = 1.0;
    if (!variable_struct_exists(sim, "city_merchant_effect_pending")) sim.city_merchant_effect_pending = false;
    if (!variable_struct_exists(sim, "city_ambush_bonus_next")) sim.city_ambush_bonus_next = 0;
    if (!variable_struct_exists(sim, "city_tension_threshold_shift")) sim.city_tension_threshold_shift = 0;

    sim.director = {
        merchant_cd: 0,
        chest_cd: 0,
        merchants_this_zone: 0,
        beats_since_relief: 0,
        adventure_cd: 0,
        relief_min_gap: 4,
        relief_max_gap: 9,
        repeat_window: 6,
        route_mod: {
            ambush_mult: 1.0,
            loot_mult: 1.0,
            hazard_mult: 1.0,
            social_mult: 1.0,
            relief_mult: 1.0,
            risk_mult: 1.0,
            ttl: 0,
            label: ""
        },
        last_relief_type: "",
        relief_context_lock: 0,
        retreat_bridge_left: 0,
        discovery_courier_seen: false,
        discovery_major_seen: false,
        repeat_prevented: 0,
        downed_loop_interventions: 0,
        tank_crisis_window: 10,
        tank_crisis_history: [],
        tank_tactic_state: {
            defensive_left: 0,
            cover_left: 0,
            withdrawal_left: 0,
            withdrawal_announced: false
        }
    };

    sim.debug_short_mode = short_mode;
    sim.debug_very_short_mode = very_short_mode;
    sim.coverage = {
        combat: 0,
        exploration: 0,
        social: 0,
        hazard: 0,
        discovery: 0,
        relief: 0,
        merchant: 0,
        retreat: 0
    };

    sim.zone_beat_counts = {};
    for (var zone_i = 0; zone_i < array_length(sim.route_segments); zone_i++) {
        var zone_seg = sim.route_segments[zone_i];
        var zone_key = zone_seg.zone;
        if (zone_seg.zone == "Wilderness") zone_key = "Wilderness: " + zone_seg.biome;
        else if (zone_seg.zone == "Dungeon") zone_key = "Dungeon: " + zone_seg.dungeon_type;

        if (!variable_struct_exists(sim.zone_beat_counts, zone_key)) {
            variable_struct_set(sim.zone_beat_counts, zone_key, {
                combat: 0,
                exploration: 0,
                social: 0,
                hazard: 0,
                merchant: 0,
                relief: 0
            });
        }
    }

    sim.recent_beats = [];
    sim.prev_zone = sim.zone;
    sim.cine_opening_emitted = false;
    sim.cine_roster_emitted_for_city_depart = -1;
    sim.cine_start_beats_emitted = false;
    sim.cine_tremor_cooldown = 0;

    sim.log = [];
    if (variable_global_exists("debug_enabled") && global.debug_enabled) {
        global.run_log_text = "";
        clipboard_set_text("");
    }
    if (!sim.episode_begun_logged) {
        sim_log(sim, "🌟 Episode begins. Seed=" + string(sim.seed) + " Zone=" + sim.zone);
        var verbose = variable_global_exists("debug_verbose") ? global.debug_verbose : false;
        if (verbose) sim_log_tag(sim, "NEAR_DEATH_DEF", "near_death is tracked as HP <= 35% max HP.");
        sim.episode_begun_logged = true;
    }

    sim_log(sim, "[DEBUG] Route segments generated (4 total):");
    for (var route_i = 0; route_i < array_length(sim.route_segments); route_i++) {
        var seg = sim.route_segments[route_i];
        sim_log(sim,
            "[DEBUG] segment[" + string(route_i) + "] zone=" + seg.zone +
            " biome=" + seg.biome +
            " dungeon_type=" + seg.dungeon_type
        );
    }

    // Party
    sim.party = [];
    sim.party[0] = sim_make_party_member("Tank",   sim_name_pick(sim, "tank"),   70,  5,  8, 6);
    sim.party[1] = sim_make_party_member("Mage",   sim_name_pick(sim, "mage"),   40, 30, 12, 2);
    sim.party[2] = sim_make_party_member("Thief",  sim_name_pick(sim, "thief"),  45, 10, 10, 3);
    sim.party[3] = sim_make_party_member("Healer", sim_name_pick(sim, "healer"), 42, 28,  6, 3);

    // Flavor starter strings (safe to keep)
    if (!sim.starter_kit_applied) {
        sim.party[0].armor = "Iron Shield";
        sim.party[1].weapon = "Charcoal Wand";
        sim.party[2].trinket = "Lockpick Kit";
        sim.party[3].trinket = "Prayer Beads";
        sim.starter_kit_applied = true;
    }

    // Guarantee equip schema + derived stats exist on all members
    for (var i = 0; i < array_length(sim.party); i++) {
        sim_recalc_derived(sim.party[i]);
    }

    if (!sim.adventure_initialized) {
        var prologue_options = [
            "The party meets in an inn.",
            "The party convenes at the Adventurers' Guild.",
            "The party gathers in the town center.",
            "The party receives a blessing at the local church.",
            "The party consults a priest at the temple.",
            "The party regroups after a battle.",
            "The party arrives by ship and takes rooms near the docks."
        ];
        if (!variable_struct_exists(sim, "cine_start_beats_emitted")) sim.cine_start_beats_emitted = false;
        if (!sim.cine_start_beats_emitted) {
            var prologue_idx = sim_rand_range(sim, 0, array_length(prologue_options) - 1);
            sim_log_tag(sim, "ADVENTURE_START", prologue_options[prologue_idx]);

            var tank_name = "Unknown";
            var thief_name = "Unknown";
            var mage_name = "Unknown";
            var healer_name = "Unknown";

            for (var j = 0; j < array_length(sim.party); j++) {
                var member = sim.party[j];
                if (member.role == "Tank") tank_name = member.name;
                else if (member.role == "Thief") thief_name = member.name;
                else if (member.role == "Mage") mage_name = member.name;
                else if (member.role == "Healer") healer_name = member.name;
            }

            sim_log_tag(sim, "PARTY_ROSTER",
                "Tank=" + tank_name + "; Thief=" + thief_name + "; Mage=" + mage_name + "; Healer=" + healer_name + "."
            );
            sim.cine_start_beats_emitted = true;
            sim.cine_opening_emitted = true;
        }
        sim.adventure_initialized = true;
    }

    // Stats (ensure combats exists)
    sim.stats = {
        combats: 0,
        near_deaths: 0,
        knockdowns: 0,
        chests_opened: 0,
        merchants_seen: 0,
        merchants_bought: 0,
        rares_found: 0,
        boss_defeated: false,
        boss_trigger_beat: -1,
        downed_events: 0,
        tank_downed_count: 0,
        total_downed_count: 0,
        encounters_over_budget_prevented: 0,
        rerolls_count: 0,
        encounter_attempts: 0,
        encounter_accepted: 0,
        encounter_rerolled: 0,
        encounter_scaled_down: 0,
        encounter_degraded: 0,
        encounter_bestfit_selected: 0,
        encounter_ratio_sum: 0,
        encounter_ratio_min: 0,
        encounter_ratio_max: 0,
        encounter_group_1: 0,
        encounter_group_2: 0,
        encounter_group_3: 0,
        encounter_enemy_counts: {},

        deaths: 0,
        retirements: 0,
        legacies: 0
    };
}
