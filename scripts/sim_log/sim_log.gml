function sim_log(sim, text) {
    // Keep in-memory
    array_push(sim.log, text);

    // Also dump to Output console for sharing back
    show_debug_message(text);
}
