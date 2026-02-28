// Debug system defaults
// Sprint1-10 note: runs now follow a deterministic 4-zone cinematic route
// (Town -> Wilderness biome A -> Wilderness biome B -> Dungeon type).
// Debug logs include [DEBUG] route segments, route_index advances, and early encounter pool picks.
global.debug_enabled = true;
global.debug_output_enabled = false;

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


if (!variable_global_exists("tuner_active")) global.tuner_active = false;
if (!variable_global_exists("tuner_session") || !is_struct(global.tuner_session)) {
    global.tuner_session = {
        episodes: 0,
        sum_combats: 0,
        sum_chests: 0,
        sum_merchants: 0,
        sum_rares: 0,
        sum_retirements: 0,
        sum_deaths: 0,
        sum_gold: 0,
        boss_defeated_count: 0
    };
}

if (!variable_global_exists("tuning") || !is_struct(global.tuning)) global.tuning = {};
if (!variable_struct_exists(global.tuning, "merchant_chance_base")) global.tuning.merchant_chance_base = 13;
if (!variable_struct_exists(global.tuning, "chest_chance_base")) global.tuning.chest_chance_base = 12;
if (!variable_struct_exists(global.tuning, "merchants_per_zone_cap")) global.tuning.merchants_per_zone_cap = 2;
if (!variable_struct_exists(global.tuning, "chests_per_zone_cap")) global.tuning.chests_per_zone_cap = 2;
if (!variable_struct_exists(global.tuning, "merchant_cd_turns")) global.tuning.merchant_cd_turns = 3;
if (!variable_struct_exists(global.tuning, "chest_cd_turns")) global.tuning.chest_cd_turns = 4;
if (!variable_struct_exists(global.tuning, "exploration_chest_first_pct")) global.tuning.exploration_chest_first_pct = 34;
if (!variable_struct_exists(global.tuning, "exploration_chest_next_pct")) global.tuning.exploration_chest_next_pct = 20;
if (!variable_struct_exists(global.tuning, "encounter_rate_scalar")) global.tuning.encounter_rate_scalar = 1.0;
if (!variable_struct_exists(global.tuning, "monster_power_scalar")) global.tuning.monster_power_scalar = 1.0;
if (!variable_struct_exists(global.tuning, "dmg_scalar")) global.tuning.dmg_scalar = 1.0;
if (!variable_struct_exists(global.tuning, "heal_scalar")) global.tuning.heal_scalar = 1.0;

slider_index = 0;
tuner_sliders = [
    { key: "merchant_chance_base", label: "merchant_chance_base", min: 0, max: 40, step: 1, big_step: 5, decimals: 0 },
    { key: "chest_chance_base", label: "chest_chance_base", min: 0, max: 40, step: 1, big_step: 5, decimals: 0 },
    { key: "merchants_per_zone_cap", label: "merchants_per_zone_cap", min: 0, max: 6, step: 1, big_step: 1, decimals: 0 },
    { key: "chests_per_zone_cap", label: "chests_per_zone_cap", min: 0, max: 6, step: 1, big_step: 1, decimals: 0 },
    { key: "merchant_cd_turns", label: "merchant_cd_turns", min: 0, max: 8, step: 1, big_step: 1, decimals: 0 },
    { key: "chest_cd_turns", label: "chest_cd_turns", min: 0, max: 8, step: 1, big_step: 1, decimals: 0 },
    { key: "exploration_chest_first_pct", label: "exploration_chest_first_pct", min: 0, max: 80, step: 1, big_step: 5, decimals: 0 },
    { key: "exploration_chest_next_pct", label: "exploration_chest_next_pct", min: 0, max: 60, step: 1, big_step: 5, decimals: 0 },
    { key: "encounter_rate_scalar", label: "encounter_rate_scalar", min: 0.25, max: 2.50, step: 0.05, big_step: 0.20, decimals: 2 },
    { key: "monster_power_scalar", label: "monster_power_scalar", min: 0.50, max: 2.00, step: 0.05, big_step: 0.20, decimals: 2 },
    { key: "dmg_scalar", label: "dmg_scalar", min: 0.85, max: 1.25, step: 0.01, big_step: 0.05, decimals: 2 },
    { key: "heal_scalar", label: "heal_scalar", min: 0.85, max: 1.25, step: 0.01, big_step: 0.05, decimals: 2 }
];
