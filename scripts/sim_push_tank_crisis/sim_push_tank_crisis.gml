function sim_push_tank_crisis(sim, crisis_add) {
    if (!is_struct(sim.director)) return 0;

    if (!variable_struct_exists(sim.director, "tank_crisis_window")) {
        sim.director.tank_crisis_window = 10;
    }

    if (!variable_struct_exists(sim.director, "tank_crisis_history") || !is_array(sim.director.tank_crisis_history)) {
        sim.director.tank_crisis_history = [];
    }

    // Store this beat's contribution (use a clear field name)
    array_push(sim.director.tank_crisis_history, { beat: sim.beat, delta: crisis_add });

    // Trim to rolling window
    var k = 0;
    while (k < array_length(sim.director.tank_crisis_history)) {
        var entry = sim.director.tank_crisis_history[k];
        if (sim.beat - entry.beat >= sim.director.tank_crisis_window) {
            array_delete(sim.director.tank_crisis_history, k, 1);
        } else {
            k += 1;
        }
    }

    // Sum contributions in window
    var _score = 0;
    for (var i = 0; i < array_length(sim.director.tank_crisis_history); i++) {
        _score += sim.director.tank_crisis_history[i].delta;
    }

    return _score;
}