// Debug system defaults
// Sprint1-10 note: runs now follow a deterministic 4-zone cinematic route
// (Town -> Wilderness biome A -> Wilderness biome B -> Dungeon type).
// Debug logs include [DEBUG] route segments, route_index advances, and early encounter pool picks.
global.debug_enabled = true;
global.debug_output_enabled = false;

// Deterministic debug seed controls
global.debug_seed = 100001;      // pick a seed you like
global.debug_seed_step = 1;      // how much "Next Seed" increments
global.debug_short_mode = false; // full-length runs by default

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
key_prev_f8 = false;

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
if (!variable_struct_exists(global.tuning, "merchant_chance_base")) global.tuning.merchant_chance_base = 40;
if (!variable_struct_exists(global.tuning, "chest_chance_base")) global.tuning.chest_chance_base = 40;
if (!variable_struct_exists(global.tuning, "merchants_per_zone_cap")) global.tuning.merchants_per_zone_cap = 2;
if (!variable_struct_exists(global.tuning, "chests_per_zone_cap")) global.tuning.chests_per_zone_cap = 6;
if (!variable_struct_exists(global.tuning, "merchant_cd_turns")) global.tuning.merchant_cd_turns = 0;
if (!variable_struct_exists(global.tuning, "chest_cd_turns")) global.tuning.chest_cd_turns = 0;
if (!variable_struct_exists(global.tuning, "exploration_chest_first_pct")) global.tuning.exploration_chest_first_pct = 34;
if (!variable_struct_exists(global.tuning, "exploration_chest_next_pct")) global.tuning.exploration_chest_next_pct = 20;
if (!variable_struct_exists(global.tuning, "encounter_rate_scalar")) global.tuning.encounter_rate_scalar = 1.0;
if (!variable_struct_exists(global.tuning, "monster_power_scalar")) global.tuning.monster_power_scalar = 1.0;
if (!variable_struct_exists(global.tuning, "dmg_scalar")) global.tuning.dmg_scalar = 1.0;
if (!variable_struct_exists(global.tuning, "heal_scalar")) global.tuning.heal_scalar = 1.0;

slider_index = 0;
tuner_selected_help_key = "";
tuner_hover_help_key = "";
tuner_help = {
    merchant_chance_base: "Base percent chance for a merchant event to spawn during director checks. Increase: merchants appear more often, giving more shop opportunities and potentially easier recovery. Decrease: merchants are rarer, so economy pressure rises. Companion values: limited by merchants_per_zone_cap and throttled by merchant_cd_turns.",
    chest_chance_base: "Base percent chance for chest events during director checks. Increase: more chest opportunities and loot inflow. Decrease: fewer chest events and slower gearing. Companion values: works with chests_per_zone_cap and chest_cd_turns, and is also affected by route loot multipliers.",
    merchants_per_zone_cap: "Hard cap on merchant spawns per zone. Increase: allows more merchants to appear before the zone blocks further merchant events. Decrease: clamps merchant frequency even when chance is high. Companion values: merchant_chance_base controls attempts, merchant_cd_turns controls spacing.",
    chests_per_zone_cap: "Hard cap on chest spawns per zone. Increase: allows more chest outcomes before the zone reaches chest saturation. Decrease: exploration chest generation shuts off earlier in a zone. Companion values: chest_chance_base sets attempt frequency; chest_cd_turns and exploration chest percentages shape actual delivery cadence.",
    merchant_cd_turns: "Cooldown turns after a merchant appears. Increase: merchants are spaced farther apart and cannot chain as often. Decrease: merchants can reappear sooner. Companion values: combines with merchant_chance_base and merchants_per_zone_cap to determine total merchant density.",
    chest_cd_turns: "Cooldown turns after a chest appears. Increase: chest streaks are reduced by longer gaps. Decrease: chest chains become more possible when chance checks pass. Companion values: combines with chest_chance_base, chests_per_zone_cap, exploration_chest_first_pct, and exploration_chest_next_pct.",
    exploration_chest_first_pct: "Percent chance for the first exploration chest roll when in exploration focus. Increase: first chest in exploration is more likely. Decrease: first chest is less likely, making exploration drier. Companion values: paired with exploration_chest_next_pct for follow-up chests and constrained by chest_cd_turns/chests_per_zone_cap.",
    exploration_chest_next_pct: "Percent chance for additional exploration chest rolls after the first chest logic. Increase: follow-up chests become more common. Decrease: first chest may still happen but chaining additional chests drops. Companion values: paired with exploration_chest_first_pct and constrained by chest cooldown/cap values.",
    encounter_rate_scalar: "Global multiplier for encounter pressure/frequency logic. Increase: more encounters or faster combat pacing pressure. Decrease: fewer encounters and calmer pacing. Companion values: interacts with monster_power_scalar and damage/heal scalars to define total run difficulty feel.",
    monster_power_scalar: "Multiplier for enemy threat/power calculations in combat and boss resolution. Increase: enemies hit harder or scale stronger, increasing wipe risk. Decrease: enemies are easier to handle. Companion values: heavily felt with dmg_scalar (incoming damage) and heal_scalar (recovery capacity).",
    dmg_scalar: "Multiplier on incoming damage applied to party members. Increase: every qualifying damage packet grows, making combats deadlier. Decrease: incoming damage is softened and survivability improves. Companion values: paired with monster_power_scalar for danger and heal_scalar for sustain balance.",
    heal_scalar: "Multiplier on healing amounts (party heal/auto-heal effects). Increase: healing actions restore more, offsetting attrition. Decrease: recovery weakens and chip damage sticks longer. Companion values: balancing counterpart to dmg_scalar and monster_power_scalar."
};
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
