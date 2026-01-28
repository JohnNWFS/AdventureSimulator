function sim_rand_range(sim, a, b) {
    var r = sim_rng_next(sim);
    // convert to 0..1 using 32-bit range
    var t = r / 4294967296; // 2^32
    return a + floor(t * (b - a + 1));
}

