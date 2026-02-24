function sim_make_combat_encounter(sim, party_power) {
    var MAX_REROLLS_PER_ENCOUNTER = 5;

    var zone_key = "Town";
    if (sim.zone == "Wilderness") {
        zone_key = (sim.overland_biome == "Woods") ? "Wilderness: Woods" : "Wilderness: Fields";
    } else if (sim.zone == "Dungeon") {
        zone_key = "Dungeon: Cursed Temple";
    }

    var roster = [
        // HOW TO ADD A NEW ENEMY:
        // 1. Add entry here
        // 2. Provide required fields
        // 3. Ensure zone eligibility is correct
        // 4. Adjust weight if needed

        // Wilderness: Fields
        { name: "Raider Scout", archetype: "ambusher", base_threat: 5, zones: ["Wilderness: Fields"], weight: 1.35, tier: "low" },
        { name: "Mounted Bandit", archetype: "melee", base_threat: 8, zones: ["Wilderness: Fields"], weight: 1.25, tier: "mid" },
        { name: "Spear Militia", archetype: "tank", base_threat: 7, zones: ["Wilderness: Fields"], weight: 1.20, tier: "mid" },
        { name: "Field Cultist", archetype: "caster", base_threat: 7, zones: ["Wilderness: Fields"], weight: 1.25, tier: "mid" },
        { name: "War Hound", archetype: "ambusher", base_threat: 6, zones: ["Wilderness: Fields"], weight: 1.20, tier: "low" },
        { name: "Bog Leech", archetype: "swarm", base_threat: 4, zones: ["Wilderness: Fields"], weight: 1.10, tier: "low" },
        { name: "Dust Pike Runner", archetype: "ambusher", base_threat: 6, zones: ["Wilderness: Fields"], weight: 1.10, tier: "low" },
        { name: "Banner Skirmisher", archetype: "melee", base_threat: 8, zones: ["Wilderness: Fields"], weight: 1.00, tier: "mid" },
        { name: "Steppe Slinger", archetype: "ranged", base_threat: 7, zones: ["Wilderness: Fields"], weight: 1.05, tier: "mid" },
        { name: "Grainfield Brute", archetype: "tank", base_threat: 9, zones: ["Wilderness: Fields"], weight: 0.95, tier: "high" },
        { name: "Ashen Heretic", archetype: "caster", base_threat: 9, zones: ["Wilderness: Fields"], weight: 1.00, tier: "high" },
        { name: "Ridge Warg", archetype: "ambusher", base_threat: 8, zones: ["Wilderness: Fields"], weight: 0.70, tier: "mid" },
        { name: "Harrier Wolfpack", archetype: "swarm", base_threat: 7, zones: ["Wilderness: Fields"], weight: 0.95, tier: "mid" },
        { name: "Broken Lancer", archetype: "melee", base_threat: 10, zones: ["Wilderness: Fields"], weight: 0.90, tier: "high" },
        { name: "Fen Marauder", archetype: "controller", base_threat: 8, zones: ["Wilderness: Fields"], weight: 1.00, tier: "mid" },
        { name: "Howling Outrider", archetype: "ambusher", base_threat: 9, zones: ["Wilderness: Fields"], weight: 0.85, tier: "high" },
        { name: "Tithe Collector", archetype: "caster", base_threat: 10, zones: ["Wilderness: Fields"], weight: 0.85, tier: "high" },
        { name: "Dune Ravager", archetype: "boss", base_threat: 12, zones: ["Wilderness: Fields"], weight: 0.80, tier: "boss" },

        // Wilderness: Woods
        { name: "Briar Stalker", archetype: "ambusher", base_threat: 6, zones: ["Wilderness: Woods"], weight: 1.35, tier: "low" },
        { name: "Forest Warden", archetype: "tank", base_threat: 9, zones: ["Wilderness: Woods"], weight: 1.20, tier: "high" },
        { name: "Poison Archer", archetype: "ranged", base_threat: 7, zones: ["Wilderness: Woods"], weight: 1.35, tier: "mid" },
        { name: "Moss Golem", archetype: "tank", base_threat: 10, zones: ["Wilderness: Woods"], weight: 1.10, tier: "high" },
        { name: "Shrieking Crow Swarm", archetype: "swarm", base_threat: 6, zones: ["Wilderness: Woods"], weight: 1.25, tier: "low" },
        { name: "Root Snare Entity", archetype: "controller", base_threat: 8, zones: ["Wilderness: Woods"], weight: 1.30, tier: "mid" },
        { name: "Needlecap Lurker", archetype: "ambusher", base_threat: 7, zones: ["Wilderness: Woods"], weight: 1.10, tier: "mid" },
        { name: "Barkhide Bruiser", archetype: "tank", base_threat: 8, zones: ["Wilderness: Woods"], weight: 1.00, tier: "mid" },
        { name: "Canopy Hexer", archetype: "caster", base_threat: 9, zones: ["Wilderness: Woods"], weight: 1.00, tier: "high" },
        { name: "Vine Lash Hunter", archetype: "controller", base_threat: 7, zones: ["Wilderness: Woods"], weight: 1.05, tier: "mid" },
        { name: "Thornrunner", archetype: "ambusher", base_threat: 6, zones: ["Wilderness: Woods"], weight: 1.15, tier: "low" },
        { name: "Moonlit Trapper", archetype: "ranged", base_threat: 8, zones: ["Wilderness: Woods"], weight: 0.95, tier: "mid" },
        { name: "Sap Ooze", archetype: "swarm", base_threat: 5, zones: ["Wilderness: Woods"], weight: 1.10, tier: "low" },
        { name: "Ravencaller", archetype: "caster", base_threat: 10, zones: ["Wilderness: Woods"], weight: 0.90, tier: "high" },
        { name: "Grove Bulwark", archetype: "tank", base_threat: 10, zones: ["Wilderness: Woods"], weight: 0.90, tier: "high" },
        { name: "Mist Saboteur", archetype: "ambusher", base_threat: 8, zones: ["Wilderness: Woods"], weight: 0.95, tier: "mid" },
        { name: "Hollow Stag", archetype: "boss", base_threat: 12, zones: ["Wilderness: Woods"], weight: 0.80, tier: "boss" },
        { name: "Spite Dryad", archetype: "caster", base_threat: 11, zones: ["Wilderness: Woods"], weight: 0.85, tier: "boss" },

        // Dungeon: Cursed Temple
        { name: "Bone Sentinel", archetype: "tank", base_threat: 9, zones: ["Dungeon: Cursed Temple"], weight: 1.30, tier: "high" },
        { name: "Ritual Adept", archetype: "caster", base_threat: 9, zones: ["Dungeon: Cursed Temple"], weight: 1.25, tier: "high" },
        { name: "Chain Thrall", archetype: "melee", base_threat: 8, zones: ["Dungeon: Cursed Temple"], weight: 1.30, tier: "mid" },
        { name: "Echo Wraith", archetype: "ambusher", base_threat: 10, zones: ["Dungeon: Cursed Temple"], weight: 1.20, tier: "high" },
        { name: "Temple Guardian Idol", archetype: "boss", base_threat: 12, zones: ["Dungeon: Cursed Temple"], weight: 1.10, tier: "boss" },
        { name: "Ash Revenant", archetype: "caster", base_threat: 11, zones: ["Dungeon: Cursed Temple"], weight: 1.25, tier: "boss" },
        { name: "Censer Devotee", archetype: "caster", base_threat: 8, zones: ["Dungeon: Cursed Temple"], weight: 1.10, tier: "mid" },
        { name: "Hallway Reaver", archetype: "melee", base_threat: 9, zones: ["Dungeon: Cursed Temple"], weight: 1.00, tier: "high" },
        { name: "Mirebone Servitor", archetype: "tank", base_threat: 8, zones: ["Dungeon: Cursed Temple"], weight: 1.05, tier: "mid" },
        { name: "Lamprey Spirit", archetype: "ambusher", base_threat: 7, zones: ["Dungeon: Cursed Temple"], weight: 1.00, tier: "mid" },
        { name: "Idol Fragment Swarm", archetype: "swarm", base_threat: 6, zones: ["Dungeon: Cursed Temple"], weight: 1.05, tier: "low" },
        { name: "Vault Sentinel", archetype: "tank", base_threat: 10, zones: ["Dungeon: Cursed Temple"], weight: 0.95, tier: "high" },
        { name: "Grave Choir", archetype: "caster", base_threat: 10, zones: ["Dungeon: Cursed Temple"], weight: 0.95, tier: "high" },
        { name: "Crypt Fang", archetype: "ambusher", base_threat: 8, zones: ["Dungeon: Cursed Temple"], weight: 1.00, tier: "mid" },
        { name: "Sacrificial Blade", archetype: "melee", base_threat: 9, zones: ["Dungeon: Cursed Temple"], weight: 1.00, tier: "high" },
        { name: "Stained Archivist", archetype: "controller", base_threat: 9, zones: ["Dungeon: Cursed Temple"], weight: 0.95, tier: "high" },
        { name: "Pillar Horror", archetype: "boss", base_threat: 13, zones: ["Dungeon: Cursed Temple"], weight: 0.80, tier: "boss" },
        { name: "Coffin Warg", archetype: "ambusher", base_threat: 9, zones: ["Dungeon: Cursed Temple"], weight: 0.65, tier: "high" },

        // Shared / Town / Cross-zone
        { name: "Brigand Captain", archetype: "melee", base_threat: 10, zones: ["Town", "Wilderness: Fields"], weight: 1.00, tier: "high" },
        { name: "Hex Witch", archetype: "caster", base_threat: 9, zones: ["Town", "Wilderness: Woods", "Dungeon: Cursed Temple"], weight: 1.00, tier: "high" },
        { name: "Plague Rat Pack", archetype: "swarm", base_threat: 5, zones: ["Town", "Dungeon: Cursed Temple"], weight: 0.90, tier: "low" },
        { name: "Carrion Drake", archetype: "ambusher", base_threat: 11, zones: ["Wilderness: Fields", "Wilderness: Woods", "Dungeon: Cursed Temple"], weight: 0.90, tier: "boss" },
        { name: "Shieldbearer Veteran", archetype: "tank", base_threat: 8, zones: ["Town", "Wilderness: Fields"], weight: 1.00, tier: "mid" },
        { name: "Blood Acolyte", archetype: "caster", base_threat: 8, zones: ["Town", "Dungeon: Cursed Temple"], weight: 1.00, tier: "mid" },
        { name: "Street Knifeman", archetype: "ambusher", base_threat: 6, zones: ["Town"], weight: 1.10, tier: "low" },
        { name: "Watch Defector", archetype: "tank", base_threat: 8, zones: ["Town"], weight: 1.05, tier: "mid" },
        { name: "Sewer Channeler", archetype: "caster", base_threat: 7, zones: ["Town"], weight: 1.00, tier: "mid" },
        { name: "Torch Mob", archetype: "swarm", base_threat: 6, zones: ["Town"], weight: 1.00, tier: "low" },
        { name: "Debt Collector", archetype: "melee", base_threat: 9, zones: ["Town"], weight: 0.95, tier: "high" },
        { name: "Gatehouse Sniper", archetype: "ranged", base_threat: 8, zones: ["Town", "Wilderness: Woods"], weight: 0.95, tier: "mid" },
        { name: "Roadside Zealot", archetype: "caster", base_threat: 8, zones: ["Town", "Wilderness: Fields"], weight: 0.95, tier: "mid" },
        { name: "Bone Broker", archetype: "controller", base_threat: 9, zones: ["Town", "Dungeon: Cursed Temple"], weight: 0.90, tier: "high" },
        { name: "Grim Bailiff", archetype: "tank", base_threat: 10, zones: ["Town", "Wilderness: Fields"], weight: 0.85, tier: "high" },
        { name: "Mire Alchemist", archetype: "caster", base_threat: 9, zones: ["Wilderness: Fields", "Wilderness: Woods"], weight: 0.90, tier: "high" },
        { name: "Warg Handler", archetype: "controller", base_threat: 8, zones: ["Town", "Wilderness: Fields", "Dungeon: Cursed Temple"], weight: 0.60, tier: "mid" },
        { name: "Night Bell Wraith", archetype: "ambusher", base_threat: 10, zones: ["Town", "Dungeon: Cursed Temple"], weight: 0.85, tier: "high" }
    ];

    if (!variable_struct_exists(sim, "enemy_director") || !is_struct(sim.enemy_director)) {
        sim.enemy_director = { appearances: {}, episode_appearances: {}, last_encounter_enemies: [], last_multiset_key: "", last_episode_seen: -1 };
    }

    if (!variable_struct_exists(sim.enemy_director, "episode_appearances") || !is_struct(sim.enemy_director.episode_appearances)) {
        sim.enemy_director.episode_appearances = {};
    }
    if (!variable_struct_exists(sim.enemy_director, "last_encounter_enemies") || !is_array(sim.enemy_director.last_encounter_enemies)) {
        sim.enemy_director.last_encounter_enemies = [];
    }

    var episode_id = variable_struct_exists(sim, "episode_index") ? sim.episode_index : 1;
    if (!variable_struct_exists(sim.enemy_director, "last_episode_seen") || sim.enemy_director.last_episode_seen != episode_id) {
        sim.enemy_director.episode_appearances = {};
        sim.enemy_director.last_episode_seen = episode_id;
    }

    var profile = sim_get_zone_profile(sim);
    var zone_enemy_weights = is_struct(profile) && variable_struct_exists(profile, "enemy_weights") ? profile.enemy_weights : {};

    var eligible = [];
    var total_episode_seen = 0;
    for (var i = 0; i < array_length(roster); i++) {
        var enemy = roster[i];
        var zone_ok = false;
        for (var zi = 0; zi < array_length(enemy.zones); zi++) {
            if (enemy.zones[zi] == zone_key) { zone_ok = true; break; }
        }
        if (!zone_ok) continue;

        var seen_episode = variable_struct_exists(sim.enemy_director.episode_appearances, enemy.name)
            ? variable_struct_get(sim.enemy_director.episode_appearances, enemy.name)
            : 0;
        total_episode_seen += seen_episode;

        var zone_weight = variable_struct_exists(zone_enemy_weights, enemy.name) ? variable_struct_get(zone_enemy_weights, enemy.name) : 1.0;
        var tuned_weight = enemy.weight * zone_weight;

        var in_last_encounter = false;
        for (var li = 0; li < array_length(sim.enemy_director.last_encounter_enemies); li++) {
            if (sim.enemy_director.last_encounter_enemies[li] == enemy.name) {
                in_last_encounter = true;
                break;
            }
        }
        if (in_last_encounter) tuned_weight *= 0.12;

        array_push(eligible, { enemy: enemy, seen_episode: seen_episode, tuned_weight: tuned_weight });
    }

    var avg_seen = 0;
    if (array_length(eligible) > 0) avg_seen = total_episode_seen / array_length(eligible);

    for (var e = 0; e < array_length(eligible); e++) {
        var usage_delta = eligible[e].seen_episode - avg_seen;
        if (usage_delta < 0) {
            eligible[e].tuned_weight *= (1.0 + min(0.70, abs(usage_delta) * 0.20));
        } else if (usage_delta > 0) {
            eligible[e].tuned_weight *= max(0.35, 1.0 - min(0.65, usage_delta * 0.18));
        }
        eligible[e].tuned_weight = max(0.05, eligible[e].tuned_weight);
    }

    var tier_pick = sim_pick_encounter_tier(sim);
    var tag = tier_pick.tier;
    var min_budget = floor(party_power * tier_pick.min_ratio);
    var max_budget = floor(party_power * tier_pick.max_ratio);

    var attempts = 0;
    var rerolls = 0;
    var best_candidate = undefined;
    var best_diff = 999999;

    for (var attempt = 0; attempt <= MAX_REROLLS_PER_ENCOUNTER; attempt++) {
        attempts += 1;

        var target_threat = sim_rand_range(sim, min_budget, max_budget);
        var tier_pref = (tag == "HARD") ? ["high", "boss", "mid", "low"] : ["mid", "low", "high", "boss"];

        var enemies = [];
        var total = 0;

        for (var slot = 0; slot < 3; slot++) {
            var remaining = max(0, target_threat - total);
            if (remaining <= 0) break;

            var picks = [];
            for (var tp = 0; tp < array_length(tier_pref); tp++) {
                var tier_name = tier_pref[tp];
                for (var ix = 0; ix < array_length(eligible); ix++) {
                    var item = eligible[ix];
                    var cand = item.enemy;
                    if (cand.tier != tier_name) continue;

                    var threat = floor((cand.base_threat + sim_rand_range(sim, -1, 2)) * (1 + sim.difficulty * 0.08));
                    threat = clamp(threat, 2, max_budget);
                    var overflow_limit = floor(max_budget * 0.15);
                    if (threat <= remaining || (slot == 0 && threat <= max_budget) || (remaining > 0 && threat <= (remaining + overflow_limit))) {
                        array_push(picks, { enemy: cand, threat: threat, w: item.tuned_weight });
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
            for (var pick_i = 0; pick_i < array_length(picks); pick_i++) {
                running += max(1, floor(picks[pick_i].w * 100));
                if (roll <= running) { chosen = picks[pick_i]; break; }
            }

            total += chosen.threat;
            array_push(enemies, { name: chosen.enemy.name, threat: chosen.threat, archetype: chosen.enemy.archetype });
            if (total >= max_budget) break;
        }

        if (array_length(enemies) <= 0) {
            if (attempt < MAX_REROLLS_PER_ENCOUNTER) rerolls += 1;
            continue;
        }

        var sorted_names = [];
        for (var si = 0; si < array_length(enemies); si++) array_push(sorted_names, enemies[si].name);
        for (var a = 0; a < array_length(sorted_names); a++) {
            for (var b = a + 1; b < array_length(sorted_names); b++) {
                if (string(sorted_names[b]) < string(sorted_names[a])) {
                    var tmp = sorted_names[a];
                    sorted_names[a] = sorted_names[b];
                    sorted_names[b] = tmp;
                }
            }
        }
        var multiset_key = "";
        for (var sk = 0; sk < array_length(sorted_names); sk++) {
            if (sk > 0) multiset_key += "|";
            multiset_key += sorted_names[sk];
        }

        var valid_budget = (total >= min_budget && total <= max_budget);
        var is_repeat = (multiset_key == sim.enemy_director.last_multiset_key);

        if (total <= max_budget) {
            var diff = abs(target_threat - total);
            if (diff < best_diff) {
                best_diff = diff;
                best_candidate = { enemies: enemies, total: total, multiset_key: multiset_key };
            }
        }

        if (valid_budget && !is_repeat) {
            var names = "";
            for (var ni = 0; ni < array_length(enemies); ni++) {
                if (names != "") names += ", ";
                names += enemies[ni].name;

                var prev_all = variable_struct_exists(sim.enemy_director.appearances, enemies[ni].name)
                    ? variable_struct_get(sim.enemy_director.appearances, enemies[ni].name)
                    : 0;
                variable_struct_set(sim.enemy_director.appearances, enemies[ni].name, prev_all + 1);

                var prev_ep = variable_struct_exists(sim.enemy_director.episode_appearances, enemies[ni].name)
                    ? variable_struct_get(sim.enemy_director.episode_appearances, enemies[ni].name)
                    : 0;
                variable_struct_set(sim.enemy_director.episode_appearances, enemies[ni].name, prev_ep + 1);
            }

            sim.enemy_director.last_encounter_enemies = [];
            for (var l = 0; l < array_length(enemies); l++) array_push(sim.enemy_director.last_encounter_enemies, enemies[l].name);
            sim.enemy_director.last_multiset_key = multiset_key;

            return {
                degraded: false,
                scaled: false,
                bestfit_selected: false,
                names: names,
                total: total,
                tag: tag,
                rerolls: rerolls,
                prevented: is_repeat ? 1 : 0,
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

    if (is_struct(best_candidate) && array_length(best_candidate.enemies) > 0) {
        var best_names = "";
        for (var bi = 0; bi < array_length(best_candidate.enemies); bi++) {
            if (best_names != "") best_names += ", ";
            best_names += best_candidate.enemies[bi].name;

            var prev_all2 = variable_struct_exists(sim.enemy_director.appearances, best_candidate.enemies[bi].name)
                ? variable_struct_get(sim.enemy_director.appearances, best_candidate.enemies[bi].name)
                : 0;
            variable_struct_set(sim.enemy_director.appearances, best_candidate.enemies[bi].name, prev_all2 + 1);

            var prev_ep2 = variable_struct_exists(sim.enemy_director.episode_appearances, best_candidate.enemies[bi].name)
                ? variable_struct_get(sim.enemy_director.episode_appearances, best_candidate.enemies[bi].name)
                : 0;
            variable_struct_set(sim.enemy_director.episode_appearances, best_candidate.enemies[bi].name, prev_ep2 + 1);
        }

        sim.enemy_director.last_encounter_enemies = [];
        for (var bl = 0; bl < array_length(best_candidate.enemies); bl++) array_push(sim.enemy_director.last_encounter_enemies, best_candidate.enemies[bl].name);
        sim.enemy_director.last_multiset_key = best_candidate.multiset_key;

        return {
            degraded: false,
            scaled: false,
            bestfit_selected: true,
            names: best_names,
            total: best_candidate.total,
            tag: tag,
            rerolls: rerolls,
            prevented: 1,
            attempts: attempts,
            party_power: party_power,
            ratio: best_candidate.total / max(1, party_power),
            group_size: array_length(best_candidate.enemies),
            enemies: best_candidate.enemies,
            zone_used: sim.zone,
            biome_used: sim.overland_biome,
            dungeon_type_used: sim.dungeon_type
        };
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
