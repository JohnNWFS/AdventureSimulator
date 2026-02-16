function sim_make_combat_encounter(sim, party_power) {
    var MAX_REROLLS_PER_ENCOUNTER = 6;
    var BOSS_CAP_RATIO = 1.80;
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

    for (var attempt = 0; attempt < MAX_REROLLS_PER_ENCOUNTER; attempt++) {
        var target_threat = sim_rand_range(sim, min_budget, max_budget);
        var remaining = target_threat;
        var group_size_max = 3;
        var total = 0;
        var names = "";
        var enemies = [];

        for (var i = 0; i < group_size_max; i++) {
            var fitting = [];
            var non_boss_cap = max(3, floor(party_power * NON_BOSS_CAP_RATIO));

            for (var p = 0; p < array_length(pool); p++) {
                var fit_e = pool[p];
                var fit_expected = floor((fit_e.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
                fit_expected = clamp(fit_expected, 2, non_boss_cap);
                if (fit_expected <= remaining) {
                    array_push(fitting, fit_e);
                }
            }

            if (array_length(fitting) <= 0) break;

            var e = fitting[sim_rand_range(sim, 0, array_length(fitting) - 1)];
            var per_enemy = floor((e.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
            per_enemy = clamp(per_enemy, 2, non_boss_cap);

            total += per_enemy;
            remaining = max(0, target_threat - total);
            if (names != "") names += ", ";
            names += e.name;
            array_push(enemies, { name: e.name, threat: per_enemy });
        }

        if (total < min_budget && array_length(enemies) < group_size_max) {
            var add_remaining = max(0, target_threat - total);
            var add_fitting = [];
            var add_non_boss_cap = max(3, floor(party_power * NON_BOSS_CAP_RATIO));

            for (var ap = 0; ap < array_length(pool); ap++) {
                var add_e = pool[ap];
                var add_expected = floor((add_e.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
                add_expected = clamp(add_expected, 2, add_non_boss_cap);
                if (add_expected <= add_remaining) {
                    array_push(add_fitting, add_e);
                }
            }

            if (array_length(add_fitting) > 0) {
                var add_pick = add_fitting[sim_rand_range(sim, 0, array_length(add_fitting) - 1)];
                var add_threat = floor((add_pick.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
                add_threat = clamp(add_threat, 2, add_non_boss_cap);
                total += add_threat;
                if (names != "") names += ", ";
                names += add_pick.name;
                array_push(enemies, { name: add_pick.name, threat: add_threat });
            }
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
                group_size: array_length(enemies),
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
