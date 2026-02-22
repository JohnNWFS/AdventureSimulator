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

    // ---- Episode flags reset (must reset each run; sim struct is reused) ----
    if (!variable_struct_exists(sim, "flags") || !is_struct(sim.flags)) sim.flags = {};
    sim.flags.hook_emitted = false;
    sim.flags.complication_emitted = false;
    sim.flags.boss_begun = false;

    sim.intel = {
        trap_warning: false,
        boss_weakness_known: false
    };

    sim.zone = "Dungeon";
    sim.difficulty = 1;
    sim.tension = 10;
    sim.gold_total = 0;

    sim.wound_retreat_threshold = very_short_mode ? 2 : (short_mode ? 2 : 3);
    sim.retreat_to_city = false;
    sim.retreat_beats_left = 0;
    sim.city_scene_pending = false;
    sim.city_scene_played = false;

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

    sim.recent_beats = [];
    sim.prev_zone = sim.zone;

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

    // Party
    sim.party = [];
    sim.party[0] = sim_make_party_member("Tank",   sim_name_pick(sim, "tank"),   70,  5,  8, 6);
    sim.party[1] = sim_make_party_member("Mage",   sim_name_pick(sim, "mage"),   40, 30, 12, 2);
    sim.party[2] = sim_make_party_member("Thief",  sim_name_pick(sim, "thief"),  45, 10, 10, 3);
    sim.party[3] = sim_make_party_member("Healer", sim_name_pick(sim, "healer"), 42, 28,  6, 3);

    // Flavor starter strings (safe to keep)
    sim.party[0].armor = "Iron Shield";
    sim.party[1].weapon = "Charcoal Wand";
    sim.party[2].trinket = "Lockpick Kit";
    sim.party[3].trinket = "Prayer Beads";

    // Guarantee equip schema + derived stats exist on all members
    for (var i = 0; i < array_length(sim.party); i++) {
        sim_recalc_derived(sim.party[i]);
    }

    var prologue_options = [
        "The party meets in an inn.",
        "The party convenes at the Adventurers' Guild.",
        "The party gathers in the town center.",
        "The party receives a blessing at the local church.",
        "The party consults a priest at the temple.",
        "The party regroups after a battle.",
        "The party arrives by ship and takes rooms near the docks."
    ];
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
