function loot_roll_pct(sim) {
	// returns 1...100 using the sim RNG
	return sim_rand_range(sim, 1, 100);
}
