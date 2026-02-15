function sim_pick_encounter_tier(sim) {
    var normal_cap_ratio = 1.25;
    var hard_cap_ratio = 1.45;

    var tier = "NORMAL";
    var min_ratio = 0.75;
    var max_ratio = normal_cap_ratio;

    var hard_chance = 10 + ((sim.tension > 72) ? 6 : 0);
    if (sim_chance(sim, hard_chance)) {
        tier = "HARD";
        min_ratio = 1.10;
        max_ratio = hard_cap_ratio;
    }

    if (is_struct(sim.director) && variable_struct_exists(sim.director, "tank_tactic_state")) {
        var state = sim.director.tank_tactic_state;
        if (state.withdrawal_left > 0) {
            tier = "NORMAL";
            min_ratio = 0.75;
            max_ratio = min(normal_cap_ratio, 0.95);
        }
    }

    return { tier: tier, min_ratio: min_ratio, max_ratio: max_ratio };
}

