function sim_run_new(sim, beats_target) {
    // New run with a new seed
    var seed = irandom_range(100000, 999999);
    sim_run_init(sim, seed, beats_target);
}
