function sim_party_any_dead(sim) {
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (variable_struct_exists(p, "dead") && p.dead) return true;

        if (variable_struct_exists(p, "status_state") && p.status_state == "dead") return true;
    }
    return false;
}
