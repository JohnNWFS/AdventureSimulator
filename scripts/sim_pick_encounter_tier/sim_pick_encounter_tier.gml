function sim_pick_encounter_tier(sim) {
    var normal_cap_ratio = 1.30;
    var hard_cap_ratio = 1.45;

    var tier = "NORMAL";
    var min_ratio = 0.70;
    var max_ratio = normal_cap_ratio;

    var hard_chance = 10 + ((sim.tension > 72) ? 6 : 0);

    if (is_struct(sim.director) && variable_struct_exists(sim.director, "tank_tactic_state")) {
        var crisis_state = sim.director.tank_tactic_state;
        if (!variable_struct_exists(crisis_state, "stagger_left")) crisis_state.stagger_left = 0;
        if (crisis_state.withdrawal_left > 0 || crisis_state.stagger_left > 0) hard_chance = min(hard_chance, 6);
    }

    if (sim_chance(sim, hard_chance)) {
        tier = "HARD";
        min_ratio = 1.05;
        max_ratio = hard_cap_ratio;
    }

    if (is_struct(sim.director) && variable_struct_exists(sim.director, "tank_tactic_state")) {
        var state = sim.director.tank_tactic_state;
        if (!variable_struct_exists(state, "stagger_left")) state.stagger_left = 0;
        if (state.withdrawal_left > 0) {
            tier = "NORMAL";
            min_ratio = 0.70;
            max_ratio = min(normal_cap_ratio, 0.95);
        }
    }

    return { tier: tier, min_ratio: min_ratio, max_ratio: max_ratio };
}
