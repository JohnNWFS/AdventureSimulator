function sim_log_tag(sim, tag, msg) {
    var safe_tag = string(tag);
    var safe_msg = string(msg);

    // Keep in-memory for HUD
    array_push(sim.log, "[" + safe_tag + "] " + safe_msg);

    // Route through canonical emitter
    beat_output_emit(safe_tag, safe_msg, undefined);
}
