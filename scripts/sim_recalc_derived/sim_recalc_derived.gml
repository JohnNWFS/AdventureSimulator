function sim_recalc_derived(p) {
    var gear_atk = 0;
    var gear_def = 0;
    var gear_hp  = 0;
    var gear_mp  = 0;

    var w = p.equip.weapon;
    var a = p.equip.armor;
    var t = p.equip.trinket;

    if (is_struct(w)) { gear_atk += w.stats.atk; gear_def += w.stats.def; gear_hp += w.stats.hp; gear_mp += w.stats.mp; }
    if (is_struct(a)) { gear_atk += a.stats.atk; gear_def += a.stats.def; gear_hp += a.stats.hp; gear_mp += a.stats.mp; }
    if (is_struct(t)) { gear_atk += t.stats.atk; gear_def += t.stats.def; gear_hp += t.stats.hp; gear_mp += t.stats.mp; }

    p.max_hp = max(1, p.base_max_hp + gear_hp);
    p.max_mp = max(0, p.base_max_mp + gear_mp);

    // Clamp current resources to new max
    p.hp = clamp(p.hp, 0, p.max_hp);
    p.mp = clamp(p.mp, 0, p.max_mp);

    p.atk = max(0, p.base_atk + gear_atk);

    // Wounds reduce DEF after gear/base are applied
    var raw_def = p.base_def + gear_def;
    p.def = max(0, raw_def - p.wounds);
}