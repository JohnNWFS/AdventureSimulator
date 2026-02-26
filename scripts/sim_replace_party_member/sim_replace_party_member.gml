function sim_replace_party_member(sim, idx, role) {
    // Maintain party archetypes and indices
    var new_p = sim_make_party_member(role, sim_name_generate(sim, string_lower(role)), 1, 1, 1, 1);

    // Re-roll with proper scaled base stats by role
    var d = sim.difficulty;

    switch (role) {
        case "Tank":
            new_p.base_max_hp = 70 + d * 4;
            new_p.base_max_mp = 5;
            new_p.base_atk    = 8 + floor(d * 0.6);
            new_p.base_def    = 6 + floor(d * 0.4);
            break;

        case "Mage":
            new_p.base_max_hp = 40 + d * 2;
            new_p.base_max_mp = 30 + d * 2;
            new_p.base_atk    = 12 + floor(d * 0.8);
            new_p.base_def    = 2 + floor(d * 0.2);
            break;

        case "Thief":
            new_p.base_max_hp = 45 + d * 2;
            new_p.base_max_mp = 10 + d;
            new_p.base_atk    = 10 + floor(d * 0.7);
            new_p.base_def    = 3 + floor(d * 0.3);
            break;

        case "Healer":
            new_p.base_max_hp = 42 + d * 2;
            new_p.base_max_mp = 28 + d * 2;
            new_p.base_atk    = 6 + floor(d * 0.3);
            new_p.base_def    = 3 + floor(d * 0.3);
            break;
    }

    new_p.hp = new_p.base_max_hp;
    new_p.mp = new_p.base_max_mp;

    // Flavor
    new_p.origin = sim_pick_origin(sim);
    new_p.quirk  = sim_pick_quirk(sim, role);

    // Fresh spirit
    new_p.resolve = 100;
    new_p.retire_notice = false;
    new_p.cracking_flag = false;
    new_p.status_state = "alive";

    // Keep empty gear; you can later “starter-kit” them in town
    new_p.equip.weapon  = undefined;
    new_p.equip.armor   = undefined;
    new_p.equip.trinket = undefined;

    sim.party[idx] = new_p;
    sim_recalc_derived(sim.party[idx]);

    sim_log_tag(sim, "RECRUIT",
        "🧑‍🤝‍🧑 Recruit joins: " + new_p.role + " " + new_p.name +
        " (" + new_p.origin + ", " + new_p.quirk + ")."
    );
}
