import campaigns from '../assets/campaigns.json'

for(const campaign in campaigns) {
    if(!campaigns[campaign].id) {
        campaigns[campaign].id = campaigns[campaign].title.toLowerCase().replace(/\s/,'-')
    }
}

export const CAMPAIGNS = campaigns;


export function getMapNameByChapter(id) {
    const campaign = campaigns[id.substring(0,3).replace('m','')];
    if(campaign) return campaign.title;
    //Todo: add some custom maps
    return id;
}

export function getMapImage(id) {
    const campaign = campaigns[id.substring(0,3).replace('m','')];
    if(campaign) return campaign.image;
    //Todo: add some custom maps
    return null;
}