function sim_chance(sim, pct) {
    return sim_rand_range(sim, 1, 100) <= pct;
}
