function sim_run_restart_same_seed(sim) {
    // Replay exact run deterministically
    sim_run_init(sim, sim.seed, sim.beats_target);
}
