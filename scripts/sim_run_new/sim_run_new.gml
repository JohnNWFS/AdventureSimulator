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

    global.debug_short_mode = true;
    sim.log = [];

    for (var i = 0; i < run_count; i++) {
        var test_seed = base_seed + i;
        sim_log(sim, "=== Test Run " + string(i + 1) + " (Seed " + string(test_seed) + ") ===");

        sim_run_new(sim, beats_target_short, test_seed);
        while (!sim.finished) {
            sim_run_step(sim);
        }
    }

    global.debug_seed = original_seed;
    global.debug_short_mode = original_short;
    sim_log(sim, "=== End multi-seed short test ===");
}
