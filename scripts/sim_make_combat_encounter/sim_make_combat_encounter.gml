function sim_make_combat_encounter(sim, party_power) {
    var MAX_REROLLS_PER_ENCOUNTER = 5;

    var zone_key = "Town";
    if (sim.zone == "Wilderness") {
        zone_key = (sim.overland_biome == "Woods") ? "Wilderness: Woods" : "Wilderness: Fields";
    } else if (sim.zone == "Dungeon") {
        zone_key = "Dungeon: Cursed Temple";
    }

    var roster = [
        // Fields
        { name: "Raider Scout", base: 5, archetype: "ambusher", zones: ["Wilderness: Fields"], tier: "low" },
        { name: "Mounted Bandit", base: 8, archetype: "melee", zones: ["Wilderness: Fields"], tier: "mid" },
        { name: "Spear Militia", base: 7, archetype: "tank", zones: ["Wilderness: Fields"], tier: "mid" },
        { name: "Field Cultist", base: 7, archetype: "caster", zones: ["Wilderness: Fields"], tier: "mid" },
        { name: "War Hound", base: 6, archetype: "ambusher", zones: ["Wilderness: Fields"], tier: "low" },
        { name: "Bog Leech", base: 4, archetype: "swarm", zones: ["Wilderness: Fields"], tier: "low" },

        // Woods
        { name: "Briar Stalker", base: 6, archetype: "ambusher", zones: ["Wilderness: Woods"], tier: "low" },
        { name: "Forest Warden", base: 9, archetype: "tank", zones: ["Wilderness: Woods"], tier: "high" },
        { name: "Poison Archer", base: 7, archetype: "ranged", zones: ["Wilderness: Woods"], tier: "mid" },
        { name: "Moss Golem", base: 10, archetype: "tank", zones: ["Wilderness: Woods"], tier: "high" },
        { name: "Shrieking Crow Swarm", base: 6, archetype: "swarm", zones: ["Wilderness: Woods"], tier: "low" },
        { name: "Root Snare Entity", base: 8, archetype: "controller", zones: ["Wilderness: Woods"], tier: "mid" },

        // Dungeon: Cursed Temple
        { name: "Bone Sentinel", base: 9, archetype: "tank", zones: ["Dungeon: Cursed Temple"], tier: "high" },
        { name: "Ritual Adept", base: 9, archetype: "caster", zones: ["Dungeon: Cursed Temple"], tier: "high" },
        { name: "Chain Thrall", base: 8, archetype: "melee", zones: ["Dungeon: Cursed Temple"], tier: "mid" },
        { name: "Echo Wraith", base: 10, archetype: "ambusher", zones: ["Dungeon: Cursed Temple"], tier: "high" },
        { name: "Temple Guardian Idol", base: 12, archetype: "boss", zones: ["Dungeon: Cursed Temple"], tier: "boss" },
        { name: "Ash Revenant", base: 11, archetype: "caster", zones: ["Dungeon: Cursed Temple"], tier: "boss" },

        // Neutral / shared
        { name: "Brigand Captain", base: 10, archetype: "melee", zones: ["Town", "Wilderness: Fields"], tier: "high" },
        { name: "Hex Witch", base: 9, archetype: "caster", zones: ["Town", "Wilderness: Woods", "Dungeon: Cursed Temple"], tier: "high" },
        { name: "Plague Rat Pack", base: 5, archetype: "swarm", zones: ["Town", "Dungeon: Cursed Temple"], tier: "low" },
        { name: "Carrion Drake", base: 11, archetype: "ambusher", zones: ["Wilderness: Fields", "Wilderness: Woods", "Dungeon: Cursed Temple"], tier: "boss" },
        { name: "Shieldbearer Veteran", base: 8, archetype: "tank", zones: ["Town", "Wilderness: Fields"], tier: "mid" },
        { name: "Blood Acolyte", base: 8, archetype: "caster", zones: ["Town", "Dungeon: Cursed Temple"], tier: "mid" }
    ];

    if (!variable_struct_exists(sim, "enemy_director") || !is_struct(sim.enemy_director)) {
        sim.enemy_director = { appearances: {}, last_encounter_enemies: [], signature_enemy: "" };
    }
    if (sim.enemy_director.signature_enemy == "") {
        var sig_idx = sim_rand_range(sim, 0, array_length(roster) - 1);
        sim.enemy_director.signature_enemy = roster[sig_idx].name;
    }

    var profile = sim_get_zone_profile(sim);
    var zone_enemy_weights = profile.enemy_weights;

    var eligible = [];
    for (var i = 0; i < array_length(roster); i++) {
        var enemy = roster[i];
        var zone_ok = false;
        for (var zi = 0; zi < array_length(enemy.zones); zi++) {
            if (enemy.zones[zi] == zone_key) { zone_ok = true; break; }
        }
        if (!zone_ok) continue;

        var seen = variable_struct_exists(sim.enemy_director.appearances, enemy.name)
            ? variable_struct_get(sim.enemy_director.appearances, enemy.name)
            : 0;
        var max_appearances = (enemy.name == sim.enemy_director.signature_enemy) ? 6 : 4;
        if (seen >= max_appearances) continue;

        var blocked_by_cooldown = false;
        if (enemy.tier != "boss") {
            for (var li = 0; li < array_length(sim.enemy_director.last_encounter_enemies); li++) {
                if (sim.enemy_director.last_encounter_enemies[li] == enemy.name) {
                    blocked_by_cooldown = true;
                    break;
                }
            }
        }
        if (blocked_by_cooldown) continue;

        var w = variable_struct_exists(zone_enemy_weights, enemy.name) ? variable_struct_get(zone_enemy_weights, enemy.name) : 1.0;
        if (enemy.name == sim.enemy_director.signature_enemy && seen < 6) w *= 1.2;
        enemy.weight = w;
        array_push(eligible, enemy);
    }

    var tier_pick = sim_pick_encounter_tier(sim);
    var tag = tier_pick.tier;
    var min_budget = floor(party_power * tier_pick.min_ratio);
    var max_budget = floor(party_power * tier_pick.max_ratio);

    var attempts = 0;
    var rerolls = 0;

    for (var attempt = 0; attempt <= MAX_REROLLS_PER_ENCOUNTER; attempt++) {
        attempts += 1;
        var target_threat = sim_rand_range(sim, min_budget, max_budget);

        var tier_pref = (tag == "HARD") ? ["high", "boss", "mid", "low"] : ["mid", "low", "high", "boss"];
        var enemies = [];
        var total = 0;

        for (var slot = 0; slot < 3; slot++) {
            var picks = [];
            var remaining = max(0, target_threat - total);
            if (remaining <= 0) break;

            for (var tp = 0; tp < array_length(tier_pref); tp++) {
                var tier_name = tier_pref[tp];
                for (var e = 0; e < array_length(eligible); e++) {
                    var cand = eligible[e];
                    if (cand.tier != tier_name) continue;

                    var threat = floor((cand.base + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
                    threat = clamp(threat, 2, max_budget);
                    if (threat <= remaining || (slot == 0 && threat <= max_budget)) {
                        array_push(picks, { enemy: cand, threat: threat, w: cand.weight });
                    }
                }
                if (array_length(picks) > 0) break;
            }

            if (array_length(picks) <= 0) break;

            var total_w = 0;
            for (var wi = 0; wi < array_length(picks); wi++) total_w += max(1, floor(picks[wi].w * 100));
            var roll = sim_rand_range(sim, 1, total_w);
            var running = 0;
            var chosen = picks[0];
            for (var pi = 0; pi < array_length(picks); pi++) {
                running += max(1, floor(picks[pi].w * 100));
                if (roll <= running) { chosen = picks[pi]; break; }
            }

            total += chosen.threat;
            array_push(enemies, { name: chosen.enemy.name, threat: chosen.threat, archetype: chosen.enemy.archetype });
            if (total >= max_budget) break;
        }

        if (total >= min_budget && total <= max_budget && array_length(enemies) > 0) {
            var names = "";
            for (var ni = 0; ni < array_length(enemies); ni++) {
                if (names != "") names += ", ";
                names += enemies[ni].name;

                var prev = variable_struct_exists(sim.enemy_director.appearances, enemies[ni].name)
                    ? variable_struct_get(sim.enemy_director.appearances, enemies[ni].name)
                    : 0;
                variable_struct_set(sim.enemy_director.appearances, enemies[ni].name, prev + 1);
            }
            sim.enemy_director.last_encounter_enemies = [];
            for (var l = 0; l < array_length(enemies); l++) {
                array_push(sim.enemy_director.last_encounter_enemies, enemies[l].name);
            }

            return {
                degraded: false,
                scaled: false,
                bestfit_selected: false,
                names: names,
                total: total,
                tag: tag,
                rerolls: rerolls,
                prevented: 0,
                attempts: attempts,
                party_power: party_power,
                ratio: total / max(1, party_power),
                group_size: array_length(enemies),
                enemies: enemies,
                zone_used: sim.zone,
                biome_used: sim.overland_biome,
                dungeon_type_used: sim.dungeon_type
            };
        }

        if (attempt < MAX_REROLLS_PER_ENCOUNTER) rerolls += 1;
    }

    return {
        degraded: true,
        scaled: false,
        bestfit_selected: false,
        tag: tag,
        rerolls: rerolls,
        prevented: 1,
        attempts: attempts,
        total: 0,
        names: "",
        party_power: party_power,
        ratio: 0,
        group_size: 0,
        enemies: [],
        zone_used: sim.zone,
        biome_used: sim.overland_biome,
        dungeon_type_used: sim.dungeon_type
    };
}
