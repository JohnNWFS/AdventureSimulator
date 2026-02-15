function sim_make_combat_encounter(sim, party_power) {
    var MAX_REROLLS_PER_ENCOUNTER = 10;
    var BOSS_CAP_RATIO = 1.80;

    var pool = [
        { name: "Skeleton", base: 5 },
        { name: "Bandit", base: 6 },
        { name: "Goblin", base: 4 },
        { name: "Slime", base: 3 },
        { name: "Warg", base: 7 },
        { name: "Cult Acolyte", base: 6 },
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
    var targeted_total = 0;
    var targeted_names = "";
    var targeted_enemies = [];
    var targeted_count = 0;

    while (targeted_total < target_total && targeted_count < 3) {
        var remaining = target_total - targeted_total;
        var fitting = [];

        for (var p = 0; p < array_length(pool); p++) {
            var fit_e = pool[p];
            var fit_per_enemy = floor((fit_e.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
            var fit_non_boss_cap = max(3, floor(party_power * 0.45));
            fit_per_enemy = clamp(fit_per_enemy, 2, fit_non_boss_cap);

            if (fit_per_enemy <= (remaining + small_slack)) {
                if ((targeted_total + fit_per_enemy) <= max_budget && (targeted_total + fit_per_enemy) <= boss_cap) {
                    array_push(fitting, { name: fit_e.name, threat: fit_per_enemy });
                }
            }
        }

        if (array_length(fitting) <= 0) break;

        var picked = fitting[sim_rand_range(sim, 0, array_length(fitting) - 1)];
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
            ratio: (targeted_total / max(1, party_power))
        };
    }

    for (var attempt = 0; attempt < MAX_REROLLS_PER_ENCOUNTER; attempt++) {
        var group_size = sim_rand_range(sim, 1, 3);
        var total = 0;
        var names = "";
        var enemies = [];

        for (var i = 0; i < group_size; i++) {
            var e = pool[sim_rand_range(sim, 0, array_length(pool) - 1)];
            var per_enemy = floor((e.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));

            // Smooth non-boss spikes.
            var non_boss_cap = max(3, floor(party_power * 0.45));
            per_enemy = clamp(per_enemy, 2, non_boss_cap);

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
                ratio: ratio
            };
        }

        var scaled_attempt = sim_try_scale_encounter(candidate, cap_ratio, BOSS_CAP_RATIO, false);
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
                ratio: (scaled_attempt.total / max(1, party_power))
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
            ratio: bestfit_under_cap.ratio
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
                ratio: (scaled_fallback.total / max(1, party_power))
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
        ratio: 0
    };
}
