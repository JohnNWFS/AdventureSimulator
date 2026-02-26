function sim_party_is_active(member) {
    if (!is_struct(member)) return false;

    var is_dead = variable_struct_exists(member, "dead") && member.dead;
    var is_retired = variable_struct_exists(member, "retired") && member.retired;
    var status_dead = variable_struct_exists(member, "status_state") && member.status_state == "dead";
    var status_retired = variable_struct_exists(member, "status_state") && member.status_state == "retired";
    var is_inactive = variable_struct_exists(member, "inactive") && member.inactive;

    return !(is_dead || is_retired || status_dead || status_retired || is_inactive);
}

function sim_party_any_dead(sim) {
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (!sim_party_is_active(p)) {
            if ((variable_struct_exists(p, "dead") && p.dead)
            || (variable_struct_exists(p, "status_state") && p.status_state == "dead")) {
                return true;
            }
        }
    }
    return false;
}
