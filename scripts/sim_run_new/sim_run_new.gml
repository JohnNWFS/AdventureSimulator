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
