function sim_run_new(sim, beats_target) {
    // Canonical run seed source: global.debug_seed
    var seed;

    if (argument_count >= 3) {
        seed = argument[2];
    } else if (variable_global_exists("debug_seed")) {
        seed = global.debug_seed;
    } else {
        seed = irandom_range(100000, 999999);
        global.debug_seed = seed;
    }

    global.debug_seed = seed;
    rng_seed_init(global.debug_seed);
    sim_run_init(sim, global.debug_seed, beats_target);
}

function sim_run_multi_seed_short_test(sim, base_seed, run_count, beats_target_short) {
    var original_seed = sim.seed;
    var original_short = variable_global_exists("debug_short_mode") ? global.debug_short_mode : false;
    var original_very_short = variable_global_exists("debug_very_short_mode") ? global.debug_very_short_mode : false;

    var total_combats = 0;
    var total_exploration = 0;
    var total_merchant = 0;
    var total_relief = 0;
    var total_discovery = 0;
    var total_hazard = 0;
    var total_social = 0;
    var total_downed = 0;
    var total_prevented = 0;

    global.debug_short_mode = true;
    global.debug_very_short_mode = false;

    for (var i = 0; i < run_count; i++) {
        var test_seed = base_seed + i;

        sim.log = [];
        sim_log(sim, "=== Test Run " + string(i + 1) + " (Seed " + string(test_seed) + ") ===");

        sim_run_new(sim, beats_target_short, test_seed);
        sim_log(sim, "=== Test Run " + string(i + 1) + " (Seed " + string(test_seed) + ") ===");
        while (!sim.finished) {
            sim_run_step(sim);
        }

        sim_log(sim,
            "Run " + string(i + 1) + " summary: " +
            "combat=" + string(sim.coverage.combat) +
            ", exploration=" + string(sim.coverage.exploration) +
            ", social=" + string(sim.coverage.social) +
            ", merchant=" + string(sim.coverage.merchant) +
            ", relief=" + string(sim.coverage.relief) +
            ", discovery=" + string(sim.coverage.discovery) +
            ", hazard=" + string(sim.coverage.hazard) +
            ", downed=" + string(sim.stats.downed_events) +
            ", repeats prevented=" + string(sim.director.repeat_prevented)
        );

        total_combats += sim.coverage.combat;
        total_exploration += sim.coverage.exploration;
        total_merchant += sim.coverage.merchant;
        total_relief += sim.coverage.relief;
        total_discovery += sim.coverage.discovery;
        total_hazard += sim.coverage.hazard;
        total_social += sim.coverage.social;
        total_downed += sim.stats.downed_events;
        total_prevented += sim.director.repeat_prevented;
    }

    global.debug_seed = original_seed;
    global.debug_short_mode = original_short;
    global.debug_very_short_mode = original_very_short;
    sim_log(sim,
        "Combined summary: combat=" + string(total_combats) +
        ", exploration=" + string(total_exploration) +
        ", social=" + string(total_social) +
        ", merchant=" + string(total_merchant) +
        ", relief=" + string(total_relief) +
        ", discovery=" + string(total_discovery) +
        ", hazard=" + string(total_hazard) +
        ", downed=" + string(total_downed) +
        ", repeats prevented=" + string(total_prevented)
    );
    sim_log(sim, "=== End multi-seed short test ===");
}
