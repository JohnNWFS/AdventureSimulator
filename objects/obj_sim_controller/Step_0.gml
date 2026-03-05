/// obj_sim_controller :: Step
// Controls
if (keyboard_check_pressed(vk_return)) {
    global.debug_seed += global.debug_seed_step;
    var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
    sim_run_new(sim, run_target, global.debug_seed);
    blockout_seen_log_count = array_length(sim.log);
}
if (keyboard_check_pressed(ord("R"))) {
    sim_run_restart_same_seed(sim);         // replay same seed
    blockout_seen_log_count = array_length(sim.log);
}
if (keyboard_check_pressed(ord("T"))) {
    global.debug_short_mode = !global.debug_short_mode;
    if (global.debug_short_mode) global.debug_very_short_mode = false;
    sim_log_tag(sim, "DEBUG_MODE", "🧪 Short run mode: " + string(global.debug_short_mode));
    var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
    sim_run_new(sim, run_target, global.debug_seed);
    blockout_seen_log_count = array_length(sim.log);
}
if (keyboard_check_pressed(ord("V"))) {
    global.debug_very_short_mode = !global.debug_very_short_mode;
    if (global.debug_very_short_mode) global.debug_short_mode = true;
    sim_log_tag(sim, "DEBUG_MODE", "⚡ Very short mode: " + string(global.debug_very_short_mode));
    var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
    sim_run_new(sim, run_target, global.debug_seed);
    blockout_seen_log_count = array_length(sim.log);
}
if (keyboard_check_pressed(ord("Q"))) {
    sim_run_multi_seed_short_test(sim, global.debug_seed, global.debug_multi_seed_count, episode_beats_target_short);
    blockout_seen_log_count = array_length(sim.log);
}
if (keyboard_check_pressed(vk_space)) {
    auto_run = !auto_run;
}
if (keyboard_check_pressed(ord("B"))) {
    global.debug_blockout_playback = !global.debug_blockout_playback;
}
if (!auto_run && keyboard_check_pressed(ord("N"))) {
    beats_per_step = 1;
    sim_run_step(sim);
}

// Auto-run
if (auto_run && !sim.finished) {
    for (var i = 0; i < beats_per_step; i++) {
        if (sim.finished) break;
        sim_run_step(sim);
    }
}

// Blockout playback: parse new tagged lines and convert to a tiny shot model.
while (blockout_seen_log_count < array_length(sim.log)) {
    var line = sim.log[blockout_seen_log_count];
    blockout_seen_log_count += 1;

    if (!is_string(line)) continue;
    if (string_length(line) < 3) continue;
    if (string_char_at(line, 1) != "[") continue;

    var close_idx = string_pos("]", line);
    if (close_idx <= 2) continue;

    var beat_tag = string_copy(line, 2, close_idx - 2);
    var beat_map = sim_beat_animation_map_get(beat_tag);

    var duration_ms = 900;
    switch (beat_tag) {
        case "ADVENTURE_START": duration_ms = 1600; break;
        case "ENCOUNTER": duration_ms = 1200; break;
        case "COMBAT_EXCHANGE": duration_ms = 650; break;
        case "LOOT_FOUND": duration_ms = 1150; break;
        case "CITY_ARRIVE": duration_ms = 1400; break;
        default: duration_ms = 900; break;
    }

    blockout_shot = {
        beat_tag: beat_tag,
        anim_id: beat_map.anim_id,
        lane: beat_map.lane,
        duration_ms: duration_ms,
        start_ms: current_time
    };
}

// If finished, do nothing until rerun/new seed.
