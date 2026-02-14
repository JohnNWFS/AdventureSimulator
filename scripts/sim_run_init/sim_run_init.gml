function sim_run_init(sim, seed, beats_target) {
    // Core run state
    global.debug_seed = seed;
    sim.seed = seed;
    sim.rng = seed;
    sim.beat = 0;
    sim.beats_target = beats_target;
    sim.finished = false;

    sim.zone = "Dungeon";
    sim.difficulty = 1;
    sim.tension = 10;
    sim.gold_total = 0;

    sim.wound_retreat_threshold = 3;
    sim.retreat_to_city = false;
    sim.retreat_beats_left = 0;
    sim.city_scene_pending = false;
    sim.city_scene_played = false;

    sim.director = {
        merchant_cd: 0,
        chest_cd: 0,
        merchants_this_zone: 0,
        beats_since_relief: 0
    };

    sim.prev_zone = sim.zone;

    sim.log = [];
    sim_log(sim, "🌟 Episode begins. Seed=" + string(sim.seed) + " Zone=" + sim.zone);

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

        deaths: 0,
        retirements: 0,
        legacies: 0
    };
}
