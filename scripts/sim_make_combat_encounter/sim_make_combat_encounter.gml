function sim_make_combat_encounter(sim, party_power) {
    var MAX_REROLLS_PER_ENCOUNTER = 10;
    var BOSS_CAP_RATIO = 1.80;
    var DIFFICULTY_SLOPE = 0.065;
    var NON_BOSS_CAP_RATIO = 0.42;

    var pool = [
        { name: "Skeleton", base: 5 },
        { name: "Bandit", base: 6 },
        { name: "Goblin", base: 4 },
        { name: "Slime", base: 3 },
        { name: "Warg", base: 8 },
        { name: "Cult Acolyte", base: 7 },
        { name: "Ogre Brute", base: 11 }
    ];

    var tier_pick = sim_pick_encounter_tier(sim);
    var tag = tier_pick.tier;
    var cap_ratio = tier_pick.max_ratio;

    var min_budget = floor(party_power * tier_pick.min_ratio);
    var max_budget = floor(party_power * tier_pick.max_ratio);
    var boss_cap = floor(party_power * BOSS_CAP_RATIO);
    max_budget = min(max_budget, boss_cap);

    var rerolls = 0;
    var prevented = 0;
    var attempts = 0;
    var candidates = [];

    var target_total = sim_rand_range(sim, min_budget, max_budget);
    var small_slack = 2;
    var early_party = (party_power < 52);
    var group_target = 2;
    var group_roll = sim_rand_range(sim, 1, 100);

    if (tag == "NORMAL") {
        if (early_party) {
            if (group_roll <= 50) group_target = 1;
            else if (group_roll <= 90) group_target = 2;
            else group_target = 3;
        } else {
            if (group_roll <= 20) group_target = 1;
            else if (group_roll <= 70) group_target = 2;
            else group_target = 3;
        }
    } else if (tag == "HARD") {
        if (early_party) {
            if (group_roll <= 20) group_target = 1;
            else if (group_roll <= 75) group_target = 2;
            else group_target = 3;
        } else {
            if (group_roll <= 10) group_target = 1;
            else if (group_roll <= 55) group_target = 2;
            else group_target = 3;
        }
    } else if (tag == "BOSS") {
        group_target = (group_roll <= 40) ? 2 : 3;
    }

    if (max_budget <= 12 || min_budget <= 8) group_target = min(group_target, 2);

    var est_mid_threat = floor((6 + sim.difficulty) * (1 + sim.difficulty * DIFFICULTY_SLOPE));
    var min_group_needed = clamp(ceil(min_budget / max(1, est_mid_threat)), 1, 3);
    group_target = max(group_target, min_group_needed);

    var targeted_total = 0;
    var targeted_names = "";
    var targeted_enemies = [];
    var targeted_count = 0;

    while (targeted_total < target_total && targeted_count < group_target) {
        var remaining = target_total - targeted_total;
        var low_remaining = (remaining <= 6 || remaining <= floor(party_power * 0.16));
        if (low_remaining) group_target = min(group_target, 2);

        var fitting = [];
        var fitting_weighted = [];

        for (var p = 0; p < array_length(pool); p++) {
            var fit_e = pool[p];
            var fit_jitter_min = (fit_e.name == "Cult Acolyte") ? -2 : -1;
            var fit_jitter_max = (fit_e.name == "Cult Acolyte") ? 3 : 2;
            var fit_per_enemy = floor((fit_e.base + sim_rand_range(sim, fit_jitter_min, fit_jitter_max)) * (1 + sim.difficulty * DIFFICULTY_SLOPE));
            var fit_non_boss_cap = max(3, floor(party_power * NON_BOSS_CAP_RATIO));
            fit_per_enemy = clamp(fit_per_enemy, 2, fit_non_boss_cap);

            if (fit_per_enemy <= (remaining + small_slack)) {
                if ((targeted_total + fit_per_enemy) <= max_budget && (targeted_total + fit_per_enemy) <= boss_cap) {
                    array_push(fitting, { name: fit_e.name, threat: fit_per_enemy });
                }
            }
        }

        if (array_length(fitting) <= 0) break;

        for (var fw = 0; fw < array_length(fitting); fw++) {
            var fit_pick = fitting[fw];
            var same_name_count = 0;
            for (var te = 0; te < array_length(targeted_enemies); te++) {
                if (targeted_enemies[te].name == fit_pick.name) same_name_count += 1;
            }
            var weight = max(1, 3 - (same_name_count * 2));
            for (var wx = 0; wx < weight; wx++) array_push(fitting_weighted, fit_pick);
        }

        var picked_pool = (array_length(fitting_weighted) > 0) ? fitting_weighted : fitting;
        var picked = picked_pool[sim_rand_range(sim, 0, array_length(picked_pool) - 1)];
        targeted_total += picked.threat;
        if (targeted_names != "") targeted_names += ", ";
        targeted_names += picked.name;
        array_push(targeted_enemies, picked);
        targeted_count += 1;

        if ((target_total - targeted_total) < 2) break;
    }

    attempts += 1;
    if (targeted_total >= min_budget && targeted_total <= max_budget && targeted_total <= boss_cap) {
        return {
            degraded: false,
            scaled: false,
            bestfit_selected: false,
            names: targeted_names,
            total: targeted_total,
            tag: tag,
            rerolls: rerolls,
            prevented: prevented,
            attempts: attempts,
            party_power: party_power,
            ratio: (targeted_total / max(1, party_power)),
            group_size: array_length(targeted_enemies),
            enemies: targeted_enemies
        };
    }

    for (var attempt = 0; attempt < MAX_REROLLS_PER_ENCOUNTER; attempt++) {
        var group_size = group_target;
        if (max_budget <= 12 || target_total <= 10) group_size = min(group_size, 2);
        if (min_budget >= 10 && group_size < 2) group_size = 2;
        if (attempt >= 4 && max_budget > 12) group_size = min(3, group_size + 1);
        var total = 0;
        var names = "";
        var enemies = [];

        for (var i = 0; i < group_size; i++) {
            var e = pool[sim_rand_range(sim, 0, array_length(pool) - 1)];
            var jitter_min = (e.name == "Cult Acolyte") ? -2 : -1;
            var jitter_max = (e.name == "Cult Acolyte") ? 3 : 2;
            var per_enemy = floor((e.base + sim_rand_range(sim, jitter_min, jitter_max)) * (1 + sim.difficulty * DIFFICULTY_SLOPE));

            // Smooth non-boss spikes.
            var non_boss_cap = max(3, floor(party_power * NON_BOSS_CAP_RATIO));
            per_enemy = clamp(per_enemy, 2, non_boss_cap);

            if (i > 0 && enemies[i - 1].name == e.name && sim_chance(sim, 55)) {
                e = pool[sim_rand_range(sim, 0, array_length(pool) - 1)];
                jitter_min = (e.name == "Cult Acolyte") ? -2 : -1;
                jitter_max = (e.name == "Cult Acolyte") ? 3 : 2;
                per_enemy = floor((e.base + sim_rand_range(sim, jitter_min, jitter_max)) * (1 + sim.difficulty * DIFFICULTY_SLOPE));
                per_enemy = clamp(per_enemy, 2, non_boss_cap);
            }

            total += per_enemy;
            if (names != "") names += ", ";
            names += e.name;
            array_push(enemies, { name: e.name, threat: per_enemy });
        }

        attempts += 1;

        var ratio = total / max(1, party_power);
        var candidate = {
            names: names,
            total: total,
            tag: tag,
            party_power: party_power,
            ratio: ratio,
            cap_ratio: cap_ratio,
            enemies: enemies
        };
        array_push(candidates, candidate);

        if (total > boss_cap) {
            prevented += 1;
            rerolls += 1;
            continue;
        }

        if (total >= min_budget && total <= max_budget) {
            return {
                degraded: false,
                scaled: false,
                bestfit_selected: false,
                names: names,
                total: total,
                tag: tag,
                rerolls: rerolls,
                prevented: prevented,
                attempts: attempts,
                party_power: party_power,
                ratio: ratio,
                group_size: group_size,
                enemies: enemies
            };
        }

        var scaled_attempt = undefined;
        if (total > max_budget || total > boss_cap) scaled_attempt = sim_try_scale_encounter(candidate, cap_ratio, BOSS_CAP_RATIO, false);
        if (!is_undefined(scaled_attempt)) {
            prevented += 1;
            return {
                degraded: false,
                scaled: true,
                bestfit_selected: false,
                names: scaled_attempt.names,
                total: scaled_attempt.total,
                tag: tag,
                rerolls: rerolls,
                prevented: prevented,
                attempts: attempts,
                removed_enemy_name: scaled_attempt.removed_enemy_name,
                weakened_only: scaled_attempt.weakened_only,
                party_power: party_power,
                ratio: (scaled_attempt.total / max(1, party_power)),
                group_size: array_length(scaled_attempt.enemies),
                enemies: scaled_attempt.enemies
            };
        }

        rerolls += 1;
        if (total > max_budget) prevented += 1;
    }

    var bestfit_under_cap = undefined;
    for (var c = 0; c < array_length(candidates); c++) {
        var cand = candidates[c];
        if (cand.ratio <= cap_ratio) {
            if (is_undefined(bestfit_under_cap) || cand.ratio > bestfit_under_cap.ratio) {
                bestfit_under_cap = cand;
            }
        }
    }

    if (!is_undefined(bestfit_under_cap)) {
        return {
            degraded: false,
            scaled: false,
            bestfit_selected: true,
            names: bestfit_under_cap.names,
            total: bestfit_under_cap.total,
            tag: tag,
            rerolls: rerolls,
            prevented: prevented,
            attempts: attempts + 1,
            party_power: party_power,
            ratio: bestfit_under_cap.ratio,
            group_size: array_length(bestfit_under_cap.enemies),
            enemies: bestfit_under_cap.enemies
        };
    }

    var lowest_over_cap = undefined;
    for (var m = 0; m < array_length(candidates); m++) {
        var over = candidates[m];
        if (is_undefined(lowest_over_cap) || over.ratio < lowest_over_cap.ratio) lowest_over_cap = over;
    }

    if (!is_undefined(lowest_over_cap)) {
        var scaled_fallback = sim_try_scale_encounter(lowest_over_cap, cap_ratio, BOSS_CAP_RATIO, true);
        if (!is_undefined(scaled_fallback)) {
            prevented += 1;
            return {
                degraded: false,
                scaled: true,
                bestfit_selected: false,
                names: scaled_fallback.names,
                total: scaled_fallback.total,
                tag: tag,
                rerolls: rerolls,
                prevented: prevented,
                attempts: attempts + 1,
                removed_enemy_name: scaled_fallback.removed_enemy_name,
                weakened_only: scaled_fallback.weakened_only,
                party_power: party_power,
                ratio: (scaled_fallback.total / max(1, party_power)),
                group_size: array_length(scaled_fallback.enemies),
                enemies: scaled_fallback.enemies
            };
        }
    }

    return {
        degraded: true,
        scaled: false,
        bestfit_selected: false,
        tag: tag,
        rerolls: rerolls,
        prevented: prevented + 1,
        attempts: attempts + 1,
        total: 0,
        names: "",
        party_power: party_power,
        ratio: 0,
        group_size: 0,
        enemies: []
    };
}
