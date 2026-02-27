function sim_narrative_tag(tag) {
    return (
        tag == "NAV_CHOICE" || tag == "NAV_STATE" || tag == "DISCOVERY" || tag == "COMPLICATION" ||
        tag == "SOCIAL" || tag == "HAZARD" || tag == "RUMOR"
    );
}

function sim_narrative_recent_contains(sim, full_line) {
    if (!variable_struct_exists(sim, "recent_narrative_lines") || !is_array(sim.recent_narrative_lines)) {
        sim.recent_narrative_lines = [];
    }

    for (var i = 0; i < array_length(sim.recent_narrative_lines); i++) {
        if (sim.recent_narrative_lines[i] == full_line) return true;
    }
    return false;
}

function sim_narrative_recent_push(sim, full_line) {
    if (!variable_struct_exists(sim, "recent_narrative_lines") || !is_array(sim.recent_narrative_lines)) {
        sim.recent_narrative_lines = [];
    }

    array_push(sim.recent_narrative_lines, full_line);
    while (array_length(sim.recent_narrative_lines) > 20) {
        array_delete(sim.recent_narrative_lines, 0, 1);
    }
}

function sim_log_tag(sim, tag, msg) {
    var source = (argument_count >= 4) ? string(argument[3]) : "";
    var variants = (argument_count >= 5 && is_array(argument[4])) ? argument[4] : undefined;
    var final_msg = msg;

    if (sim_narrative_tag(tag) && is_array(variants) && array_length(variants) > 0) {
        var tries = 0;
        while (tries < 5) {
            var idx = sim_rand_range(sim, 0, array_length(variants) - 1);
            var candidate_msg = variants[idx];
            var candidate_line = "[" + string(tag) + "] " + candidate_msg;
            final_msg = candidate_msg;
            if (!sim_narrative_recent_contains(sim, candidate_line)) break;
            tries += 1;
        }
    }

    var line = "[" + string(tag) + "] " + final_msg;

    // Route through beat_output_emit first so duplicate suppression can guard
    // every output channel from a second accidental emission.
    var emitted = beat_output_emit(tag, final_msg, { sim: sim, source: source });

    // Keep in sim's own log (for on-screen display) only if it was emitted.
    if (emitted) {
        array_push(sim.log, line);
        if (sim_narrative_tag(tag)) {
            sim_narrative_recent_push(sim, line);
        }
    }
}
