function sim_rng_next(sim) {
    // Simple LCG: deterministic across platforms/builds
    // X_{n+1} = (aX + c) mod 2^32
    sim.rng = (1664525 * sim.rng + 1013904223) & $FFFFFFFF;
    return sim.rng;
}

