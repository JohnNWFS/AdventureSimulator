function sim_run_restart_same_seed(sim) {
    // Replay exact run deterministically
    global.debug_seed = sim.seed;
    rng_seed_init(global.debug_seed);
    sim_run_init(sim, sim.seed, sim.beats_target);
}
