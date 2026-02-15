function sim_try_scale_encounter(enc, cap_ratio, boss_cap_ratio, force_scale) {
    if (!is_struct(enc) || !variable_struct_exists(enc, "enemies") || !is_array(enc.enemies)) return undefined;
    if (enc.tag == "BOSS") return undefined;

    var party_power = max(1, enc.party_power);
    var ratio = enc.total / party_power;
    if (!force_scale && ratio > cap_ratio + 0.20) return undefined;

    var enemies = enc.enemies;
    var enemy_count = array_length(enemies);
    if (enemy_count <= 0) return undefined;

    var removed_name = "";
    var scaled_total = enc.total;

    if (enemy_count > 1) {
        var remove_idx = 0;
        var remove_threat = enemies[0].threat;
        for (var i = 1; i < enemy_count; i++) {
            if (enemies[i].threat > remove_threat) {
                remove_threat = enemies[i].threat;
                remove_idx = i;
            }
        }
        removed_name = enemies[remove_idx].name;
        array_delete(enemies, remove_idx, 1);

        scaled_total = 0;
        for (var j = 0; j < array_length(enemies); j++) {
            scaled_total += enemies[j].threat;
        }
    } else {
        scaled_total = floor(enc.total * 0.90);
    }

    var scaled_ratio = scaled_total / party_power;
    if (scaled_ratio > boss_cap_ratio + 0.35) return undefined;

    var names = "";
    for (var n = 0; n < array_length(enemies); n++) {
        if (names != "") names += ", ";
        names += enemies[n].name;
    }

    return {
        names: names,
        total: max(1, scaled_total),
        tag: enc.tag,
        scaled: true,
        removed_enemy_name: removed_name,
        weakened_only: (enemy_count <= 1),
        party_power: enc.party_power,
        cap_ratio: cap_ratio,
        enemies: enemies
    };
}


