function _debug_start_run()
{
    global.debug_beats_emitted = 0;

    // Flush previous run's leftover lines
    debug_log_flush();

    // Clear run log text
    global.run_log_text = "";
    global.opening_beat_last_line = "";
    clipboard_set_text("");

    // Seed the RNG
    rng_seed_init(global.debug_seed);

    // Start ONE new log file (if autosave is on)
    if (global.debug_autosave) {
        debug_log_start_file(global.debug_seed);
    }

    beat_output_emit("DEBUG", "Run started. Seed=" + string(global.debug_seed), undefined);

    var map_hook = sim_beat_animation_map_get("EPISODE_HOOK");
    beat_output_emit("DEBUG", "BeatMap EPISODE_HOOK -> anim_id=" + map_hook.anim_id + " lane=" + map_hook.lane, undefined);
    var map_encounter = sim_beat_animation_map_get("ENCOUNTER");
    beat_output_emit("DEBUG", "BeatMap ENCOUNTER -> anim_id=" + map_encounter.anim_id + " lane=" + map_encounter.lane, undefined);
    var map_loot = sim_beat_animation_map_get("LOOT_FOUND");
    beat_output_emit("DEBUG", "BeatMap LOOT_FOUND -> anim_id=" + map_loot.anim_id + " lane=" + map_loot.lane, undefined);

    if (object_exists(obj_sim_controller)) {
        with (obj_sim_controller) {
            sim_run_new(sim, episode_beats_target, global.debug_seed);
        }
    }
}
