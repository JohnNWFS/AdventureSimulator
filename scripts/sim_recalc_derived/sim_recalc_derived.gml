function sim_recalc_derived(p) {
    // Ensure equip struct exists (compat with legacy party members)
    if (!variable_struct_exists(p, "equip") || !is_struct(p.equip)) {
        p.equip = { weapon: undefined, armor: undefined, trinket: undefined };
    }

    // Base stats should exist; if not, fall back to current values safely
    if (!variable_struct_exists(p, "base_max_hp")) p.base_max_hp = p.max_hp;
    if (!variable_struct_exists(p, "base_max_mp")) p.base_max_mp = p.max_mp;
    if (!variable_struct_exists(p, "base_atk"))    p.base_atk    = p.atk;
    if (!variable_struct_exists(p, "base_def"))    p.base_def    = p.def;

    var hp_bonus = 0;
    var mp_bonus = 0;
    var atk_bonus = 0;
    var def_bonus = 0;

    // Pull equipped items
    var w = p.equip.weapon;
    var a = p.equip.armor;
    var t = p.equip.trinket;

    // Sum bonuses (items are structs in your newer loot system)
    if (!is_undefined(w) && is_struct(w) && variable_struct_exists(w, "stats")) {
        atk_bonus += w.stats.atk;
        def_bonus += w.stats.def;
        hp_bonus  += w.stats.hp;
        mp_bonus  += w.stats.mp;
    }

    if (!is_undefined(a) && is_struct(a) && variable_struct_exists(a, "stats")) {
        atk_bonus += a.stats.atk;
        def_bonus += a.stats.def;
        hp_bonus  += a.stats.hp;
        mp_bonus  += a.stats.mp;
    }

    if (!is_undefined(t) && is_struct(t) && variable_struct_exists(t, "stats")) {
        atk_bonus += t.stats.atk;
        def_bonus += t.stats.def;
        hp_bonus  += t.stats.hp;
        mp_bonus  += t.stats.mp;
    }

    // Apply wound penalty to DEF (your current behavior)
    var wound_def_pen = (variable_struct_exists(p, "wounds")) ? p.wounds : 0;

    // Derived maxima
    p.max_hp = max(1, p.base_max_hp + hp_bonus);
    p.max_mp = max(0, p.base_max_mp + mp_bonus);

    // Derived combat stats
    p.atk = p.base_atk + atk_bonus;
    p.def = max(0, (p.base_def + def_bonus) - wound_def_pen);

    if (variable_struct_exists(p, "injury_lingering") && p.injury_lingering) {
        var pen = variable_struct_exists(p, "injury_penalty_pct") ? p.injury_penalty_pct : 10;
        var mult = max(0.5, 1.0 - pen / 100.0);
        var stat = variable_struct_exists(p, "injury_stat") ? p.injury_stat : "";
        if (stat == "atk") p.atk = max(1, floor(p.atk * mult));
        else if (stat == "def") p.def = max(0, floor(p.def * mult));
        else if (stat == "max_hp") p.max_hp = max(10, floor(p.max_hp * mult));
    }

    // Clamp current resources to maxima
    p.hp = clamp(p.hp, -p.max_hp * 2, p.max_hp); // allow negatives for overkill checks
    p.mp = clamp(p.mp, 0, p.max_mp);

    // Optional legacy strings for HUD compatibility
    p.weapon  = sim_item_name(p.equip.weapon);
    p.armor   = sim_item_name(p.equip.armor);
    p.trinket = sim_item_name(p.equip.trinket);
}
