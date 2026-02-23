// Debug system defaults
// Sprint1-10 note: runs now follow a deterministic 4-zone cinematic route
// (Town -> Wilderness biome A -> Wilderness biome B -> Dungeon type).
// Debug logs include [DEBUG] route segments, route_index advances, and early encounter pool picks.
global.debug_enabled = true;

// Deterministic debug seed controls
global.debug_seed = 100001;      // pick a seed you like
global.debug_seed_step = 1;      // how much "Next Seed" increments
global.debug_short_mode = true;  // short runs by default

// Output buffer
global.debug_lines = [];
global.debug_line_cap = 60;
if (!variable_global_exists("run_log_text")) global.run_log_text = "";

// Short-run limits (your sim should respect these when possible)
global.debug_max_beats = 25;     // cap number of beat lines per run
global.debug_beats_emitted = 0;  // reset each run

// Macro config
macro_runs_target = 8;   // <-- change this later (e.g., 4, 12, etc.)

// Macro state
macro_active = false;
macro_step = 0;
macro_runs_done = 0;
global.debug_batch_mode = "runs";

// Run-wait state
macro_waiting_run = false;
macro_wait_deadline_ms = 0;
macro_wait_timeout_ms = 20000; // safety net: 20 seconds

// Debug find config
global.debug_find_enabled = true;
global.debug_find_string = "[EPISODE_HOOK]";
global.debug_find_repeats = 100;
global.debug_find_seed_start = 100000;
global.debug_find_seed_step = 1;
global.debug_find_stop_on_first = false;

// Debug find runtime state
global.debug_find_active = false;
global.debug_find_index = 0;
global.debug_find_hits = 0;
global.debug_find_results = [];
global.debug_find_results_filename = "";


// Input latch
key_prev_r = false;
key_prev_n = false;
key_prev_s = false;
key_prev_c = false;
key_prev_v = false;
key_prev_o = false;
key_prev_hash = false;

// A small banner so you know it's alive
beat_output_emit("DEBUG", "Debug console online (4-zone route debug enabled). Seed=" + string(global.debug_seed), undefined);
