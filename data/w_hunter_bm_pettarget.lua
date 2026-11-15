local _, ns = ...
ns.widgetData = ns.widgetData or {}
ns.widgetData.bm_pettarget = {
    classes = {
        HUNTER = { taunt = 2649, call = 883 },
    },
    grace    = 2,
    tick     = 1,
    edge     = 0.1,
    petSlots = 10,
    attack   = "Interface\\Icons\\Ability_GhoulFrenzy",
    fury     = 19574,
    kill     = 34027,
}
ns.hunterBmPetTargetDataLoaded = true
