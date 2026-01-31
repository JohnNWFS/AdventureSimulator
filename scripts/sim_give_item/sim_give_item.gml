function sim_give_item(sim, item) {
    // Default behavior: pick a random recipient for equipables
    var idx = sim_rand_range(sim, 0, array_length(sim.party) - 1);
    sim_give_item_to(sim, item, idx);
}
