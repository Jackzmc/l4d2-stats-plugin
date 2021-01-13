import {official, custom} from '../assets/campaigns.json'
import NoMapImage from '../assets/no_map_image.png';

for(const campaign in official) {
    if(!official[campaign].id) {
        official[campaign].id = official[campaign].title.toLowerCase().replace(/\s/,'-')
    }
}
for(const campaign in custom) {
    if(!custom[campaign].id) {
        custom[campaign].id = custom[campaign].title.toLowerCase().replace(/\s/,'-')
    }
}

export const CAMPAIGNS = { ...official, ...custom };


export function getMapName(id) {
    const officialMap = official[id.substring(0,3).replace('m','')];
    if(officialMap) return officialMap.title;
    const customMap = custom[id];
    if(customMap) return customMap.title;
    //Todo: add some custom maps
    return id;
}

export function getMapImage(id) {
    const officialMap = official[id.substring(0,3).replace('m','')];
    if(officialMap) return '/img/posters/' + officialMap.image;
    const customMap = custom[id];
    if(customMap) return '/img/posters/' + customMap.image;
    //Todo: add some custom maps
    return NoMapImage;
}