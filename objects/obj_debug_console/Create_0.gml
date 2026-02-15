// Debug system defaults
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

// Input latch
key_prev_r = false;
key_prev_n = false;
key_prev_s = false;
key_prev_c = false;
key_prev_v = false;
key_prev_o = false;
key_prev_hash = false;

// A small banner so you know it's alive
beat_output_emit("DEBUG", "Debug console online. Seed=" + string(global.debug_seed), undefined);