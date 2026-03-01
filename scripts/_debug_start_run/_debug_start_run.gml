function _debug_start_run()
{
    global.debug_beats_emitted = 0;

    // Flush previous run's leftover lines
    debug_log_flush();

    // Clear run log text
    global.run_log_text = "";
    clipboard_set_text("");

    // Reset beat buffers so every new run starts with a clean slate, regardless of
    // autosave state.  Without this, any sim_run_init call that fired earlier in
    // the same frame (e.g. obj_sim_controller's own R-key handler calling
    // sim_run_restart_same_seed before obj_debug_console's handler runs)
    // would leave its EPISODE_BEGIN / ADVENTURE_START / PARTY_ROSTER lines in
    // canonical_beats, causing them to appear twice at the top of every log file.
    if (!variable_global_exists("canonical_beats"))  global.canonical_beats  = [];
    if (!variable_global_exists("debug_only_lines")) global.debug_only_lines = [];
    global.canonical_beats  = [];
    global.debug_only_lines = [];

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
            var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
            sim_run_new(sim, run_target, global.debug_seed);
        }
    }
}
