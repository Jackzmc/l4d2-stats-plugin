export enum Difficulty {
    Easy = 0,
    Normal,
    Advanced,
    Expert
}

export const GAMEMODES: Record<string, string> = {
    coop: "Campaign"
}

export const enum Survivor {
    Nick,
    Rochelle,
    Ellis,
    Coach,
    Bill,
    Zoey,
    Francis,
    Louis,
}

export const SURVIVOR_DEFS: Record<Survivor, { name: string, model: string }> = {
    [Survivor.Nick]: {
        name: "Nick",
        model: "gambler",
    },
    [Survivor.Rochelle]: {
        name: "Rochelle",
        model: "producer"
    },
    [Survivor.Ellis]: {
        name: "Ellis",
        model: "mechanic"
    },
    [Survivor.Coach]: {
        name: "Coach",
        model: "coach"
    },
    [Survivor.Bill]: {
        name: "Bill",
        model: "namvet"
    },
    [Survivor.Zoey]: {
        name: "Zoey",
        model: "teenangst"
    },
    [Survivor.Francis]: {
        name: "Francis",
        model: "biker"
    },
    [Survivor.Louis]: {
        name: "Louis",
        model: "manager"
    }
}