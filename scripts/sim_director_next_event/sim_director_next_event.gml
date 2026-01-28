function sim_director_next_event(sim) {
    // Big beats
    if (sim.beat == 0) return "intro";
    if (sim.beat == sim.beats_target - 10) return "boss"; // last ~10 beats reserved for boss

    // If party is struggling, offer relief
    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    if (avg_hp_pct < 0.45 || sim.tension > 75) {
        return "relief";
    }


	if (sim.director.merchant_cd == 0 && sim.director.merchants_this_zone < 2 && sim_chance(sim, 10)) {
	    sim.director.merchant_cd = 8; // no merchant for next 8 beats
	    return "merchant";
	}

	if (sim.director.chest_cd == 0 && sim_chance(sim, 16)) {
	    sim.director.chest_cd = 4;
	    return "chest";
	}


    // Variety beats
    if (sim_chance(sim, 12)) return "merchant";
    if (sim_chance(sim, 18)) return "chest";

    // Default
    return "combat";
}
