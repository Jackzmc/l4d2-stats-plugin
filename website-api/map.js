import campaignData from './assets/campaigns.json' assert { type: "json" };
const { official, custom } = campaignData

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
    if(!id) return 'null';
    // Slice out the prefix as official maps are in form of c##m#_, removing the 'm'
    const officialMap = official[id.substring(0,3).replace('m','')];
    if(officialMap) return officialMap.title;
    const customMap = custom[id];
    if(customMap && customMap.title) return customMap.title;
    //Todo: add some custom maps
    return id;
}