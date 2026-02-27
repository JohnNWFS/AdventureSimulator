function sim_log_tag(sim, tag, msg) {
    var source = (argument_count >= 4) ? string(argument[3]) : "";
    var line = "[" + string(tag) + "] " + msg;

    // Route through beat_output_emit first so duplicate suppression can guard
    // every output channel from a second accidental emission.
    var emitted = beat_output_emit(tag, msg, { sim: sim, source: source });

    // Keep in sim's own log (for on-screen display) only if it was emitted.
    if (emitted) {
        array_push(sim.log, line);
    }
}
