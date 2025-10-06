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

export const SURVIVOR_DEFS: Record<Survivor, { name: string, model: string, color: string, colorIsDark: boolean }> = {
    [Survivor.Nick]: {
        name: "Nick",
        model: "gambler",
        color: "#8A847D", //#3E5B88
        colorIsDark: false,
    },
    [Survivor.Rochelle]: {
        name: "Rochelle",
        model: "producer",
        color: "#954661",
        colorIsDark: false,
    },
    [Survivor.Ellis]: {
        name: "Ellis",
        model: "mechanic",
        color: "#B2AC97",
        colorIsDark: false,
    },
    [Survivor.Coach]: {
        name: "Coach",
        model: "coach",
        color: "#584962",
        colorIsDark: true,
    },
    [Survivor.Bill]: {
        name: "Bill",
        model: "namvet",
        color: "#44462C",
        colorIsDark: true,
    },
    [Survivor.Zoey]: {
        name: "Zoey",
        model: "teenangst",
        color: "#933A3D",
        colorIsDark: false,
    },
    [Survivor.Francis]: {
        name: "Francis",
        model: "biker",
        color: "#35363F",
        colorIsDark: true,
    },
    [Survivor.Louis]: {
        name: "Louis",
        model: "manager",
        color: "#928B89",
        colorIsDark: false,
    }
}