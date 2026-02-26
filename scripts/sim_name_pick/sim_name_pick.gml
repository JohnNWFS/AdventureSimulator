function sim_name_pick(sim, role) {
    // Keep your old interface, but route to the richer generator
    // role here is "tank/mage/thief/healer" from your caller
    return sim_name_generate(sim, role);
}
