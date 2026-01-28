function sim_run_init(sim, seed, beats_target) {
    // Core run state
    sim.seed = seed;
    sim.rng = seed;               // internal RNG state (do not use GameMaker's global RNG)
    sim.beat = 0;
    sim.beats_target = beats_target;
    sim.finished = false;

    sim.zone = "Dungeon";
    sim.difficulty = 1;
    sim.tension = 10;             // 0..100 pacing knob
    sim.gold_total = 0;

	sim.director = {
	    merchant_cd: 0,
	    chest_cd: 0,
	    merchants_this_zone: 0
	};

	sim.prev_zone = sim.zone;

    sim.log = [];
    sim_log(sim, "🎬 Episode begins. Seed=" + string(sim.seed) + " Zone=" + sim.zone);

    // Party
    sim.party = [];
    sim.party[0] = sim_make_party_member("Tank",   sim_name_pick(sim, "tank"),   70,  5,  8, 6);
    sim.party[1] = sim_make_party_member("Mage",   sim_name_pick(sim, "mage"),   40, 30, 12, 2);
    sim.party[2] = sim_make_party_member("Thief",  sim_name_pick(sim, "thief"),  45, 10, 10, 3);
    sim.party[3] = sim_make_party_member("Healer", sim_name_pick(sim, "healer"), 42, 28,  6, 3);

    // Starter items (strings for now, but this becomes structs later)
	sim.party[0].armor = "Iron Shield";
	sim.party[1].weapon = "Charcoal Wand";
	sim.party[2].trinket = "Lockpick Kit";
	sim.party[3].trinket = "Prayer Beads";


    // Simple per-run counters for scoring/debug
    sim.stats = {
        near_deaths: 0,
        knockdowns: 0,
        chests_opened: 0,
        merchants_seen: 0,
        rares_found: 0,
        boss_defeated: false
    };
}
