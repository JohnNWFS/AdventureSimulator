/// obj_sim_controller :: Create
episode_beats_target = 120; // 120 beats ≈ 10 minutes if you later map 1 beat ≈ 5 sec
episode_beats_target_short = 36;
episode_beats_target_very_short = 16;
auto_run = true;
beats_per_step = 1;         // crank this up to 5/10 for turbo simulation
ui_max_lines = 26;

sim = {};                   // will hold run state + party
if (!variable_global_exists("debug_seed")) global.debug_seed = 100001;
if (!variable_global_exists("debug_seed_step")) global.debug_seed_step = 1;
if (!variable_global_exists("debug_short_mode")) global.debug_short_mode = false;
if (!variable_global_exists("debug_very_short_mode")) global.debug_very_short_mode = false;
if (!variable_global_exists("debug_verbose")) global.debug_verbose = false;
if (!variable_global_exists("debug_multi_seed_count")) global.debug_multi_seed_count = 4;
if (!variable_global_exists("debug_blockout_playback")) global.debug_blockout_playback = false;

var run_target = global.debug_very_short_mode ? episode_beats_target_very_short : (global.debug_short_mode ? episode_beats_target_short : episode_beats_target);
sim_run_new(sim, run_target, global.debug_seed);

blockout_seen_log_count = array_length(sim.log);
blockout_shot = {
    beat_tag: "IDLE",
    anim_id: "idle",
    lane: "scene",
    duration_ms: 900,
    start_ms: current_time
};

//loot_debug_dump(sim, 20, { source: "chest", zone: "Dungeon", tier_target: 2 });
//loot_debug_dump(sim, 10, { source: "merchant", zone: "Town", tier_target: 4 });
//loot_debug_dump(sim, 10, { source: "boss", zone: "Castle", tier_target: 7 });



// CODEX note for future runs: append a new version comment to this section instead of replacing prior entries.
// CODEX version log: codex/sprint1-02-anti-repeat - Sprint1-07 Cinematic deterministic choose() replacement sweep.
