local addonName, CFCT = ...
CFCT:AddDefaultPreset("Classic", {
    animSpeed = 1,
    animDuration = 1.25,
    areaX = 0,
    areaY = 100,
    areaNX = 0,
    areaNY = 0,
    textStrata = "TOOLTIP",
    dontOverlapNameplates = false,
    inheritNameplates = false,
    preventOverlap = true,
    preventOverlapSpacingX = 30,
    preventOverlapSpacingY = 50,
    attachMode = "tn",
    attachModeFallback = true,
    spellIconOffsetX = 0,
    spellIconOffsetY = 0,
    spellIconZoom = 1,
    spellIconAspectRatio = 1,
    abbreviateNumbers = false,
    kiloSeparator = false,
    filterAbsoluteEnabled = false,
    filterAbsoluteThreshold = 100,
    filterRelativeEnabled = false,
    filterRelativeThreshold = 10,
    filterAverageEnabled = false,
    filterAverageThreshold = 10,
    filterMissesEnabled = false,
    sortByDamage = false,
    sortMissPrio = false,
    mergeEvents = false,
    mergeEventsInterval = 0.1,
    mergeEventsIntervalMode = "last",
    mergeEventsCounter = true,
    mergeEventsByGuid = false,
    mergeEventsBySpellID = false,
    mergeEventsBySpellIcon = true,
    mergeEventsBySchool = true,
    mergeEventsMisses = false,
    colorTable = {
        -- Single Schools
        [1]  = "ffff0000", -- MaskPhysical
        [2]  = "ffffffb6", -- MaskHoly
        [4]  = "ffff432c", -- MaskFire
        [8]  = "ff3c9742", -- MaskNature
        [16] = "ff00abff", -- MaskFrost
        [32] = "ff9500b6", -- MaskShadow
        [64] = "ffdd4aff", -- MaskArcane
        -- Physical and a Magical
        [5]  = "ffff8879", -- MaskFlamestrike
        [17] = "ff7dd5ff", -- MaskFroststrike
        [65] = "ffa8caff", -- MaskSpellstrike
        [9]  = "ffa1eaa3", -- MaskStormstrike
        [33] = "ffa89cff", -- MaskShadowstrike
        [3]  = "ffffffe6", -- MaskHolystrike
        -- Two Magical Schools
        [20] = "ffff64ab", -- MaskFrostfire
        [68] = "ffff4d5c", -- MaskSpellfire
        [12] = "ffdfcfb6", -- MaskFirestorm
        [36] = "ffb92334", -- MaskShadowflame
        [6]  = "ffffca68", -- MaskHolyfire
        [80] = "ff828ffd", -- MaskSpellfrost
        [24] = "ff5de1de", -- MaskFroststorm
        [48] = "ff3a00e5", -- MaskShadowfrost
        [18] = "ffbffffc", -- MaskHolyfrost
        [72] = "ff3f45ff", -- MaskSpellstorm
        [96] = "ff0009ff", -- MaskSpellshadow
        [66] = "fffff9ed", -- MaskDivine
        [40] = "ff462b68", -- MaskShadowstorm
        [10] = "ffe9ffa9", -- MaskHolystorm
        [34] = "ff242d8d", -- MaskTwilight (Shadowholy not explicitly listed)
        -- Three or more schools
        [28]  = "ffffa500", -- MaskElemental
        [124] = "ffffffff", -- MaskChromatic
        [126] = "ff97f4ff", -- MaskMagical
        [127] = "ff8000ff"  -- MaskChaos
    },
    colorTableDotEnabled = false,
    colorTableDot = {
        -- Single Schools
        [1]  = "ffff0000", -- MaskPhysical
        [2]  = "ffffffb6", -- MaskHoly
        [4]  = "ffff432c", -- MaskFire
        [8]  = "ff3c9742", -- MaskNature
        [16] = "ff00abff", -- MaskFrost
        [32] = "ff9500b6", -- MaskShadow
        [64] = "ffdd4aff", -- MaskArcane
        -- Physical and a Magical
        [5]  = "ffff8879", -- MaskFlamestrike
        [17] = "ff7dd5ff", -- MaskFroststrike
        [65] = "ffa8caff", -- MaskSpellstrike
        [9]  = "ffa1eaa3", -- MaskStormstrike
        [33] = "ffa89cff", -- MaskShadowstrike
        [3]  = "ffffffe6", -- MaskHolystrike
        -- Two Magical Schools
        [20] = "ffff64ab", -- MaskFrostfire
        [68] = "ffff4d5c", -- MaskSpellfire
        [12] = "ffdfcfb6", -- MaskFirestorm
        [36] = "ffb92334", -- MaskShadowflame
        [6]  = "ffffca68", -- MaskHolyfire
        [80] = "ff828ffd", -- MaskSpellfrost
        [24] = "ff5de1de", -- MaskFroststorm
        [48] = "ff3a00e5", -- MaskShadowfrost
        [18] = "ffbffffc", -- MaskHolyfrost
        [72] = "ff3f45ff", -- MaskSpellstorm
        [96] = "ff0009ff", -- MaskSpellshadow
        [66] = "fffff9ed", -- MaskDivine
        [40] = "ff462b68", -- MaskShadowstorm
        [10] = "ffe9ffa9", -- MaskHolystorm
        [34] = "ff242d8d", -- MaskTwilight (Shadowholy not explicitly listed)
        -- Three or more schools
        [28]  = "ffffa500", -- MaskElemental
        [124] = "ffffffff", -- MaskChromatic
        [126] = "ff97f4ff", -- MaskMagical
        [127] = "ff8000ff"  -- MaskChaos
    },
    auto = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFFFFF",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },  
    automiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFFFFF",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },  
    autocrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FFFFFFFF",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    petauto = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFF9D00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },  
    petautomiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFF9D00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },  
    petautocrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FFFF9D00",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    spell = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    spellmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    spellcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    spelltick = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    spelltickmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    spelltickcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    petspell = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    petspellmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    petspellcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = true,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    petspelltick = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    petspelltickmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    petspelltickcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FFFFE800",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    heal = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    healmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    healcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    healtick = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    healtickmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    healtickcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    petheal = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    pethealmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    pethealcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    },
    pethealtick = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    pethealtickmiss = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 42,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        },
        Scroll = {
            enabled = true,
            direction = "UP",
            distance = 32
        }
    },
    pethealtickcrit = {
        enabled = true,
        fontPath = "Fonts\\FRIZQT__.TTF",
        fontSize = 60,
        fontStyle = "",
        fontColor = "FF00FF00",
        showIcons = false,
        colorByType = false,
        Pow = {
            enabled = true,
            initScale = 0.25,
            midScale = 1.55,
            endScale = 1,
            duration = 0.3,
            inOutRatio = 0.7
        },
        FadeIn = {
            enabled = true,
            duration = 0.07
        },
        FadeOut = {
            enabled = true,
            duration = 0.3
        }
    }
})
