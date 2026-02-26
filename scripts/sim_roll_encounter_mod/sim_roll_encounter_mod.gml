function sim_roll_encounter_mod(sim) {
    // Returns a struct describing a one-off combat modifier, or undefined.
    // No persistence: modifiers affect only the current combat resolution.
    //
    // Fields (when present):
    //  tag: string log tag
    //  desc: string one-line narration
    //  threat_add: int
    //  dmg_mult: real
    //  def_mult: real (multiplier applied to target DEF effectiveness)
    //  mp_cost_add: int (extra MP cost for mage casts this fight)
    //  pre_strike: bool (ambush-style pre-hit)
    //  extra_splash: int (base splash to apply mid-fight; 0 means none)

    // Most combats have no modifier.
    if (!sim_chance(sim, 38)) return undefined;

    var roll = sim_rand_range(sim, 1, 100);

    // Weighting tuned for variety without constant chaos.
    if (roll <= 18) {
        return {
            tag: "AMBUSH",
            desc: "🕳 Ambush! Something lashes out before you can set formation.",
            threat_add: 1,
            dmg_mult: 1.05,
            def_mult: 1.00,
            mp_cost_add: 0,
            pre_strike: true,
            extra_splash: 0
        };
    }
    if (roll <= 35) {
        return {
            tag: "ELITE",
            desc: "👁 Elite foe: tougher, meaner, and weirdly proud of it.",
            threat_add: 2,
            dmg_mult: 1.20,
            def_mult: 1.00,
            mp_cost_add: 0,
            pre_strike: false,
            extra_splash: 0
        };
    }
    if (roll <= 52) {
        return {
            tag: "SLIPPERY",
            desc: "🧊 Slippery ground: footing is bad, armor helps less than usual.",
            threat_add: 1,
            dmg_mult: 1.10,
            def_mult: 0.60,
            mp_cost_add: 0,
            pre_strike: false,
            extra_splash: 0
        };
    }
    if (roll <= 69) {
        return {
            tag: "BERSERK",
            desc: "🔥 Berserk rush: the enemy swings wild and hard.",
            threat_add: 1,
            dmg_mult: 1.35,
            def_mult: 1.00,
            mp_cost_add: 0,
            pre_strike: false,
            extra_splash: 1
        };
    }
    if (roll <= 85) {
        return {
            tag: "REINFORCEMENTS",
            desc: "🪓 Reinforcements: more shapes join the fight from the dark.",
            threat_add: 2,
            dmg_mult: 1.10,
            def_mult: 1.00,
            mp_cost_add: 0,
            pre_strike: false,
            extra_splash: 2
        };
    }

    return {
        tag: "CURSED_GROUND",
        desc: "🜏 Cursed ground: spells feel heavier and more expensive.",
        threat_add: 1,
        dmg_mult: 1.08,
        def_mult: 1.00,
        mp_cost_add: 2,
        pre_strike: false,
        extra_splash: 0
    };
}
