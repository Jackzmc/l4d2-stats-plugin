const OFFICIAL_MAPS_BY_CHAPTER = {
    "c1m": "Dead Center",
    "c2m": "Dark Carnival",
    "c3m": "Swamp Fever",
    "c4m": "Hard Rain",
    "c5m": "The Parish",
    "c6m": "The Passing",
    "c7m": "The Sacrifice",
    "c8m": "No Mercy",
    "c9m": "Death Toll",
    "c10": "Crash Course",
    "c11": "Dead Air",
    "c12": "Blood Harvest",
    "c13": "Cold Stream",
    "c14": "Last Stand",
}
const OFFICIAL_IMAGES_BY_CHAPTER = {
    "c1m": "c1_dead_center.jpeg",
    "c2m": "c2_dark_carnival.png",
    "c3m": "c3_swamp_fever.jpeg",
    "c4m": "c4_hard_rain.jpeg",
    "c5m": "c5_the_parish.jpeg",
    "c6m": "c6_the_passing.jpeg",
    "c7m": "c7_the_sacrifice.jpeg",
    "c8m": "c8_no_mercy.jpeg",
    "c9m": "c9_death_toll.jpeg",
    "c10": "c10_crash_course.jpeg",
    "c11": "c11_dead_air.jpeg",
    "c12": "c12_blood_harvest.jpeg",
    "c13": "c13_cold_stream.png",
}

/*const CUSTOM_MAP_NAMES = {

}*/

export function getMapName(id) {
    const officialMapName = OFFICIAL_MAPS_BY_CHAPTER[id.substring(0,3)];
    if(officialMapName) return officialMapName;
    //Todo: add some custom maps
    return id;
}

export function getMapImage(id) {
    const officalImageUrl = OFFICIAL_IMAGES_BY_CHAPTER[id.substring(0,3)];
    if(officalImageUrl) return officalImageUrl;
    //Todo: add some custom maps
    return null;
}